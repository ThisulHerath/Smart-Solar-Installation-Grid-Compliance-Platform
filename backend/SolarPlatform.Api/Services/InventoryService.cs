using System.Data;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Services;

public class InventoryService(AppDbContext db, IEquipmentPricingClient pricing)
{
    public static decimal Money(decimal value) => decimal.Round(value, 2, MidpointRounding.AwayFromZero);

    // Project catalog policy: 500 W panels and one inverter rated at least the approved kW.
    public static int RequiredPanels(decimal kw) => kw > 0 && kw <= 10000
        ? checked((int)decimal.Ceiling(kw * 2)) : throw new InvalidOperationException("Invalid approved system capacity.");

    public async Task<InventoryItem> SaveAsync(Guid? id, InventoryWriteDto dto, Guid actor, CancellationToken ct)
    {
        var item = id.HasValue ? await Item(id.Value, ct) : new InventoryItem();
        if (id.HasValue && dto.Version != item.Version) throw new DbUpdateConcurrencyException("Inventory changed. Refresh before saving.");
        var sku = dto.SKU.Trim().ToUpperInvariant();
        if (string.IsNullOrWhiteSpace(sku) || string.IsNullOrWhiteSpace(dto.Name)) throw new ArgumentException("SKU and name are required.");
        if (await db.Set<InventoryItem>().AnyAsync(x => x.SKU == sku && x.Id != item.Id, ct)) throw new InvalidOperationException("SKU already exists.");
        if (dto.SupplierId.HasValue && !await db.Set<Supplier>().AnyAsync(x => x.Id == dto.SupplierId, ct)) throw new ArgumentException("Supplier does not exist.");
        if (!Enum.IsDefined(dto.Category) || dto.QuantityInStock < item.ReservedQuantity || dto.QuantityInStock < 0 || dto.UnitPriceUsd <= 0 || dto.CapacityWatts <= 0 || dto.ReorderLevel < 0)
            throw new ArgumentException("Invalid stock, price, category or capacity.");
        if (item.ReservedQuantity > 0 && (dto.Category != item.Category || dto.CapacityWatts != item.CapacityWatts))
            throw new InvalidOperationException("Release existing reservations before changing equipment specifications.");
        var delta = dto.QuantityInStock - item.QuantityInStock;
        item.SKU = sku; item.Name = dto.Name.Trim(); item.Category = dto.Category;
        item.Manufacturer = dto.Manufacturer.Trim(); item.Model = dto.Model.Trim(); item.SupplierId = dto.SupplierId;
        item.CapacityWatts = dto.CapacityWatts; item.QuantityInStock = dto.QuantityInStock; item.ReorderLevel = dto.ReorderLevel;
        item.UnitPriceUsd = Money(dto.UnitPriceUsd); item.Active = dto.Active;
        Touch(item);
        if (!id.HasValue) db.Add(item);
        if (delta != 0) Audit(item.Id, delta, delta > 0 ? StockTransactionType.RESTOCK : StockTransactionType.ADJUSTMENT, item.Id, actor, "Inventory form stock update");
        await db.SaveChangesAsync(ct);
        return item;
    }

    public async Task<InventoryItem> AdjustAsync(Guid id, StockAdjustmentDto dto, Guid actor, CancellationToken ct)
    {
        var item = await Item(id, ct);
        if (dto.Quantity == 0 || string.IsNullOrWhiteSpace(dto.Reason)) throw new ArgumentException("A nonzero quantity and reason are required.");
        var stock = checked(item.QuantityInStock + dto.Quantity);
        if (stock < item.ReservedQuantity || stock > 1000000) throw new InvalidOperationException("Adjustment would invalidate stock or reservations.");
        item.QuantityInStock = stock; Touch(item);
        Audit(id, dto.Quantity, dto.Quantity > 0 ? StockTransactionType.RESTOCK : StockTransactionType.ADJUSTMENT, Guid.NewGuid(), actor, dto.Reason);
        await db.SaveChangesAsync(ct);
        return item;
    }

    public async Task DeactivateAsync(Guid id, CancellationToken ct)
    {
        var item = await Item(id, ct); item.Active = false; Touch(item); await db.SaveChangesAsync(ct);
    }

    public async Task<EquipmentQuote> PriceAsync(Guid proposalId, CancellationToken ct)
    {
        var proposal = await db.EngineeringProposals.SingleOrDefaultAsync(x => x.Id == proposalId, ct) ?? throw new KeyNotFoundException("Proposal not found.");
        if (proposal.ProposalStatus != ProposalStatus.Approved) throw new InvalidOperationException("Only approved proposals can be priced.");
        var quote = new EquipmentQuote { EngineeringProposalId = proposalId };
        db.Add(quote); await db.SaveChangesAsync(ct);
        try
        {
            var count = RequiredPanels(proposal.RecommendedKw);
            var items = await db.Set<InventoryItem>().AsNoTracking().Where(x => x.Active).OrderBy(x => x.UnitPriceUsd).ThenBy(x => x.Id).ToListAsync(ct);
            var panel = items.FirstOrDefault(x => x.Category == EquipmentCategory.PANEL && x.CapacityWatts == 500 && x.AvailableQuantity >= count)
                ?? throw new InvalidOperationException("Insufficient compatible 500 W panels.");
            var inverter = items.FirstOrDefault(x => x.Category == EquipmentCategory.INVERTER && x.CapacityWatts >= proposal.RecommendedKw * 1000 && x.AvailableQuantity >= 1)
                ?? throw new InvalidOperationException("No compatible inverter in stock.");
            var selected = new[] { (Item: panel, Quantity: count), (Item: inverter, Quantity: 1) };
            var result = await pricing.PriceAsync(new {
                proposalId, recommendedKw = proposal.RecommendedKw,
                items = selected.Select(x => new { inventoryItemId = x.Item.Id, x.Item.Name, category = x.Item.Category.ToString(), x.Quantity, x.Item.UnitPriceUsd, x.Item.AvailableQuantity, x.Item.CapacityWatts })
            }, ct);
            ValidatePricing(result, selected.ToDictionary(x => x.Item.Id, x => (x.Item, x.Quantity)));
            quote.Status = "VALIDATED"; quote.ResultJson = JsonSerializer.Serialize(result);
        }
        catch (OperationCanceledException) when (ct.IsCancellationRequested)
        {
            quote.Status = "FAILED";
            quote.Error = "Pricing request was interrupted. Request a new quote.";
            await db.SaveChangesAsync(CancellationToken.None);
            throw;
        }
        catch (Exception ex)
        {
            quote.Status = "FAILED";
            quote.Error = ex is InvalidOperationException ? ex.Message : "Pricing service unavailable or returned invalid data. Retry pricing.";
        }
        await db.SaveChangesAsync(ct);
        return quote;
    }

    public static void ValidatePricing(PricingResult result, Dictionary<Guid, (InventoryItem Item, int Quantity)> expected)
    {
        if (result.Status != "VALIDATED" || result.BaseCurrency != "USD" || result.TargetCurrency != "LKR" || result.ExchangeRate <= 0 || result.ExchangeRate > 1000000
            || result.RateTimestamp < DateTime.UtcNow.AddHours(-48) || result.RateTimestamp > DateTime.UtcNow.AddMinutes(5)
            || result.Lines == null || result.Lines.Count != expected.Count || result.Lines.Select(x => x.InventoryItemId).Distinct().Count() != expected.Count)
            throw new InvalidOperationException("Pricing validation failed: invalid rate, timestamp or equipment.");
        foreach (var line in result.Lines)
        {
            if (!expected.TryGetValue(line.InventoryItemId, out var entry) || line.Quantity != entry.Quantity || line.UnitPriceUsd != entry.Item.UnitPriceUsd
                || line.Category != entry.Item.Category.ToString() || line.UnitPriceLkr != Money(line.UnitPriceUsd * result.ExchangeRate)
                || line.TotalPriceLkr != Money(line.Quantity * line.UnitPriceLkr)) throw new InvalidOperationException("Pricing calculation or catalog validation failed.");
        }
        if (result.TotalPriceLkr != result.Lines.Sum(x => x.TotalPriceLkr)) throw new InvalidOperationException("Pricing total validation failed.");
    }

    public async Task ReserveAsync(Guid quoteId, Guid actor, CancellationToken ct)
    {
        if (!db.Database.IsRelational()) throw new InvalidOperationException("Reservations require PostgreSQL transaction support.");
        await using var transaction = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable, ct);
        var quote = await db.Set<EquipmentQuote>().Include(x => x.EngineeringProposal).SingleOrDefaultAsync(x => x.Id == quoteId, ct) ?? throw new KeyNotFoundException("Quote not found.");
        if (quote.Status == "RESERVED") return; // Safe replay after a lost response.
        if (quote.Status != "VALIDATED" || quote.ExpiresAt <= DateTime.UtcNow || quote.EngineeringProposal.ProposalStatus != ProposalStatus.Approved)
            throw new InvalidOperationException("Quote must be current and validated for an approved proposal.");
        if (await db.Set<InventoryReservation>().AnyAsync(x => x.EngineeringProposalId == quote.EngineeringProposalId && x.Status == ReservationStatus.RESERVED, ct))
            throw new InvalidOperationException("Proposal already has reserved equipment. Release it before reserving a new quote.");
        var result = JsonSerializer.Deserialize<PricingResult>(quote.ResultJson) ?? throw new InvalidOperationException("Invalid quote.");
        var expected = new Dictionary<Guid, (InventoryItem, int)>();
        foreach (var line in result.Lines.OrderBy(x => x.InventoryItemId))
        {
            var item = await Item(line.InventoryItemId, ct);
            if (!item.Active || item.AvailableQuantity < line.Quantity) throw new InvalidOperationException("Insufficient active inventory. Refresh pricing.");
            expected.Add(item.Id, (item, line.Category == "PANEL" ? RequiredPanels(quote.EngineeringProposal.RecommendedKw) : 1));
            if ((item.Category == EquipmentCategory.PANEL && item.CapacityWatts != 500) || (item.Category == EquipmentCategory.INVERTER && item.CapacityWatts < quote.EngineeringProposal.RecommendedKw * 1000))
                throw new InvalidOperationException("Equipment specification changed. Refresh pricing.");
        }
        ValidatePricing(result, expected);
        foreach (var line in result.Lines)
        {
            var item = expected[line.InventoryItemId].Item1;
            item.ReservedQuantity += line.Quantity; Touch(item);
            var reservation = new InventoryReservation { EngineeringProposalId = quote.EngineeringProposalId, EquipmentQuoteId = quote.Id,
                InventoryItemId = item.Id, Quantity = line.Quantity, UnitPriceUsd = line.UnitPriceUsd, ExchangeRate = result.ExchangeRate,
                UnitPriceLkr = line.UnitPriceLkr, TotalPriceLkr = line.TotalPriceLkr, Status = ReservationStatus.RESERVED, ReservedAt = DateTime.UtcNow };
            db.Add(reservation); Audit(item.Id, line.Quantity, StockTransactionType.RESERVATION, reservation.Id, actor, "Approved proposal reservation");
        }
        quote.Status = "RESERVED";
        await db.SaveChangesAsync(ct); await transaction.CommitAsync(ct);
    }

    public async Task ReleaseAsync(Guid quoteId, Guid actor, CancellationToken ct)
    {
        if (!db.Database.IsRelational()) throw new InvalidOperationException("Releases require PostgreSQL transaction support.");
        await using var transaction = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable, ct);
        var quote = await db.Set<EquipmentQuote>().SingleOrDefaultAsync(x => x.Id == quoteId, ct) ?? throw new KeyNotFoundException("Quote not found.");
        var reservations = await db.Set<InventoryReservation>().Where(x => x.EquipmentQuoteId == quoteId && x.Status == ReservationStatus.RESERVED).OrderBy(x => x.InventoryItemId).ToListAsync(ct);
        if (quote.Status == "RELEASED") return;
        if (reservations.Count == 0) throw new InvalidOperationException("No reserved equipment to release.");
        foreach (var reservation in reservations)
        {
            var item = await Item(reservation.InventoryItemId, ct);
            item.ReservedQuantity -= reservation.Quantity; Touch(item);
            reservation.Status = ReservationStatus.RELEASED; reservation.ReleasedAt = reservation.UpdatedAt = DateTime.UtcNow;
            Audit(item.Id, reservation.Quantity, StockTransactionType.RELEASE, reservation.Id, actor, "Proposal equipment released");
        }
        quote.Status = "RELEASED"; await db.SaveChangesAsync(ct); await transaction.CommitAsync(ct);
    }

    private Task<InventoryItem> Item(Guid id, CancellationToken ct) => FindItem(id, ct);
    private async Task<InventoryItem> FindItem(Guid id, CancellationToken ct) => await db.Set<InventoryItem>().SingleOrDefaultAsync(x => x.Id == id, ct) ?? throw new KeyNotFoundException("Inventory item not found.");
    private static void Touch(InventoryItem item) { item.Version = Guid.NewGuid(); item.UpdatedAt = DateTime.UtcNow; }
    private void Audit(Guid item, int quantity, StockTransactionType type, Guid reference, Guid actor, string reason) => db.Add(new InventoryTransaction {
        InventoryItemId = item, Quantity = quantity, TransactionType = type, ReferenceId = reference, ActorId = actor, Reason = reason });
}
