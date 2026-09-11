using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Models;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Api.Controllers;

[ApiController, Route("api/inventory"), Authorize]
public class InventoryController(AppDbContext db, InventoryService service) : ControllerBase
{
    public const string Writers = "INVENTORY_OFFICER,ADMINISTRATOR";
    public const string Readers = Writers + ",SENIOR_ENGINEER";
    private Guid Actor => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet, Authorize(Roles = Readers)]
    [HttpGet("low-stock"), Authorize(Roles = Readers)]
    public async Task<IActionResult> List(CancellationToken ct, string? search = null, EquipmentCategory? category = null, bool lowStock = false, bool? active = null, string sort = "name", int page = 1, int pageSize = 20)
    {
        var query = db.Set<InventoryItem>().AsNoTracking().Include(x => x.Supplier).AsQueryable();
        if (!string.IsNullOrWhiteSpace(search)) { var term = search.Trim().ToUpper(); query = query.Where(x => x.SKU.Contains(term) || x.Name.ToUpper().Contains(term)); }
        if (category.HasValue) query = query.Where(x => x.Category == category);
        if (active.HasValue) query = query.Where(x => x.Active == active);
        if (lowStock || Request.Path.Value!.EndsWith("low-stock")) query = query.Where(x => x.QuantityInStock - x.ReservedQuantity <= x.ReorderLevel);
        var total = await query.CountAsync(ct);
        query = sort switch { "stock" => query.OrderBy(x => x.QuantityInStock - x.ReservedQuantity), "price" => query.OrderBy(x => x.UnitPriceUsd), "sku" => query.OrderBy(x => x.SKU), _ => query.OrderBy(x => x.Name) };
        page = Math.Max(1, page); pageSize = Math.Clamp(pageSize, 1, 100);
        return Ok(new { items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct), total, page, pageSize });
    }
    [HttpGet("{id:guid}"), Authorize(Roles = Readers)]
    public async Task<IActionResult> Get(Guid id, CancellationToken ct) => await db.Set<InventoryItem>().AsNoTracking().Include(x => x.Supplier).SingleOrDefaultAsync(x => x.Id == id, ct) is { } item ? Ok(item) : NotFound();
    [HttpPost, Authorize(Roles = Writers)]
    public async Task<IActionResult> Create(InventoryWriteDto dto, CancellationToken ct) { var item = await service.SaveAsync(null, dto, Actor, ct); return CreatedAtAction(nameof(Get), new { id = item.Id }, item); }
    [HttpPut("{id:guid}"), Authorize(Roles = Writers)]
    public async Task<IActionResult> Update(Guid id, InventoryWriteDto dto, CancellationToken ct) => Ok(await service.SaveAsync(id, dto, Actor, ct));
    [HttpDelete("{id:guid}"), Authorize(Roles = Writers)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct) { await service.DeactivateAsync(id, ct); return NoContent(); }
    [HttpPost("{id:guid}/adjust"), Authorize(Roles = Writers)]
    public async Task<IActionResult> Adjust(Guid id, StockAdjustmentDto dto, CancellationToken ct) => Ok(await service.AdjustAsync(id, dto, Actor, ct));
    [HttpGet("suppliers"), Authorize(Roles = Readers)]
    public async Task<IActionResult> Suppliers(CancellationToken ct) => Ok(await db.Set<Supplier>().AsNoTracking().OrderBy(x => x.Name).ToListAsync(ct));
    [HttpPost("suppliers"), Authorize(Roles = Writers)]
    public async Task<IActionResult> AddSupplier(SupplierWriteDto dto, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(dto.Name)) return BadRequest(new { message = "Supplier name is required." });
        var supplier = new Supplier { Name = dto.Name.Trim(), ContactEmail = dto.ContactEmail, Phone = dto.Phone }; db.Add(supplier); await db.SaveChangesAsync(ct); return Ok(supplier);
    }
    [HttpGet("proposals"), Authorize(Roles = Readers)]
    public async Task<IActionResult> Proposals(CancellationToken ct) => Ok(await db.EngineeringProposals.AsNoTracking().Where(x => x.ProposalStatus == ProposalStatus.Approved)
        .Select(x => new { x.Id, x.RecommendedKw, x.CreatedAt }).OrderByDescending(x => x.CreatedAt).ToListAsync(ct));
    [HttpPost("proposals/{id:guid}/price"), Authorize(Roles = Writers)]
    public async Task<IActionResult> Price(Guid id, CancellationToken ct) => Ok(QuoteView(await service.PriceAsync(id, ct)));
    [HttpGet("proposals/{id:guid}/equipment")]
    public async Task<IActionResult> Equipment(Guid id, CancellationToken ct)
    {
        if (User.Identity?.IsAuthenticated != true) return Unauthorized();
        var staff = User.IsInRole(RoleConstants.Administrator) || User.IsInRole(RoleConstants.InventoryOfficer) || User.IsInRole(RoleConstants.SeniorEngineer);
        var proposal = await db.EngineeringProposals.AsNoTracking().Where(x => x.Id == id && (staff || x.SolarSurvey.Customer.UserId == Actor)).Select(x => x.Id).SingleOrDefaultAsync(ct);
        if (proposal == Guid.Empty) return NotFound();
        var quotes = await db.Set<EquipmentQuote>().AsNoTracking().Where(x => x.EngineeringProposalId == id).OrderByDescending(x => x.CreatedAt).Take(20).ToListAsync(ct);
        return Ok(quotes.Select(QuoteView));
    }
    [HttpPost("reserve"), Authorize(Roles = Writers)]
    public async Task<IActionResult> Reserve(ReserveEquipmentDto dto, CancellationToken ct) { await service.ReserveAsync(dto.QuoteId, Actor, ct); return Ok(new { status = "RESERVED" }); }
    // id is the quote ID: releasing the entire equipment set avoids partial proposal reservations.
    [HttpPost("{id:guid}/release"), Authorize(Roles = Writers)]
    public async Task<IActionResult> Release(Guid id, CancellationToken ct) { await service.ReleaseAsync(id, Actor, ct); return Ok(new { status = "RELEASED" }); }
    [HttpGet("reservations"), Authorize(Roles = Readers)]
    public async Task<IActionResult> Reservations(CancellationToken ct) => Ok(await db.Set<InventoryReservation>().AsNoTracking().OrderByDescending(x => x.CreatedAt).Select(x => new {
        x.Id, x.EngineeringProposalId, x.EquipmentQuoteId, x.InventoryItemId, itemName = x.InventoryItem.Name, x.Quantity, x.UnitPriceUsd, x.ExchangeRate, x.UnitPriceLkr, x.TotalPriceLkr, x.Status, x.ReservedAt, x.ReleasedAt
    }).Take(500).ToListAsync(ct));
    private static object QuoteView(EquipmentQuote quote) => new { quote.Id, quote.EngineeringProposalId, quote.Status, quote.Error, quote.CreatedAt, quote.ExpiresAt, result = JsonSerializer.Deserialize<PricingResult>(quote.ResultJson) };
}
