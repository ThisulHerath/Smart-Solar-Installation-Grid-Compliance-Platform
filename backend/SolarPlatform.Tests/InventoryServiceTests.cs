using Microsoft.EntityFrameworkCore;
using Moq;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;
using SolarPlatform.Api.Models;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Tests;

public class InventoryServiceTests
{
    private static AppDbContext Db() => new(new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
    private static InventoryWriteDto Draft(string sku = "PANEL-A") => new() { SKU = sku, Name = "Panel", CapacityWatts = 500, UnitPriceUsd = 450, QuantityInStock = 15, ReorderLevel = 5 };

    [Fact] public async Task Crud_NormalizesSku_RejectsDuplicates_AndDeactivates()
    {
        await using var db = Db(); var service = new InventoryService(db, Mock.Of<IEquipmentPricingClient>());
        var item = await service.SaveAsync(null, Draft(" panel-a "), Guid.NewGuid(), default);
        Assert.Equal("PANEL-A", item.SKU);
        await Assert.ThrowsAsync<InvalidOperationException>(() => service.SaveAsync(null, Draft(), Guid.NewGuid(), default));
        await service.DeactivateAsync(item.Id, default);
        Assert.False(item.Active); Assert.Equal(1, await db.Set<InventoryItem>().CountAsync());
        Assert.Equal(15, (await db.Set<InventoryTransaction>().SingleAsync()).Quantity);
    }
    [Fact] public async Task CannotReduceStockBelowReservations()
    {
        await using var db = Db(); var item = new InventoryItem { QuantityInStock = 15, ReservedQuantity = 10 };
        db.Add(item); await db.SaveChangesAsync(); var service = new InventoryService(db, Mock.Of<IEquipmentPricingClient>());
        await Assert.ThrowsAsync<InvalidOperationException>(() => service.AdjustAsync(item.Id, new(-6, "Correction"), Guid.NewGuid(), default));
        Assert.Equal(15, item.QuantityInStock); Assert.Empty(db.Set<InventoryTransaction>());
    }
    [Fact] public async Task StaleEditCannotOverwriteStock()
    {
        await using var db = Db(); var service = new InventoryService(db, Mock.Of<IEquipmentPricingClient>());
        var item = await service.SaveAsync(null, Draft(), Guid.NewGuid(), default);
        await Assert.ThrowsAsync<DbUpdateConcurrencyException>(() => service.SaveAsync(item.Id, Draft(), Guid.NewGuid(), default));
    }
    [Fact] public void AvailabilityAndGoldenPricing()
    {
        var item = new InventoryItem { QuantityInStock = 15, ReservedQuantity = 10, ReorderLevel = 5, UnitPriceUsd = 450 };
        Assert.Equal(5, item.AvailableQuantity); Assert.True(item.LowStock); Assert.Equal(10, InventoryService.RequiredPanels(5));
        var result = new PricingResult("VALIDATED", 300, DateTime.UtcNow, "USD", "LKR", 1350000,
            new() { new(item.Id, "Panel", "PANEL", 10, 450, 135000, 1350000) }, new());
        InventoryService.ValidatePricing(result, new() { [item.Id] = (item, 10) });
        Assert.Throws<InvalidOperationException>(() => InventoryService.ValidatePricing(result with { ExchangeRate = 301 }, new() { [item.Id] = (item, 10) }));
        Assert.Throws<InvalidOperationException>(() => InventoryService.ValidatePricing(result with { RateTimestamp = DateTime.UtcNow.AddDays(-3) }, new() { [item.Id] = (item, 10) }));
    }
    [Fact] public async Task FailedPricingIsPersistedAndDoesNotReserve()
    {
        await using var db = Db(); var proposal = new EngineeringProposal { ProposalStatus = ProposalStatus.Approved, RecommendedKw = 5 };
        db.Add(proposal); await db.SaveChangesAsync(); var service = new InventoryService(db, Mock.Of<IEquipmentPricingClient>());
        var quote = await service.PriceAsync(proposal.Id, default);
        Assert.Equal("FAILED", quote.Status); Assert.Empty(db.Set<InventoryReservation>());
        Assert.Contains("panels", quote.Error);
    }
    [Fact] public async Task UnapprovedProposalCannotBePriced()
    {
        await using var db = Db(); var proposal = new EngineeringProposal(); db.Add(proposal); await db.SaveChangesAsync();
        await Assert.ThrowsAsync<InvalidOperationException>(() => new InventoryService(db, Mock.Of<IEquipmentPricingClient>()).PriceAsync(proposal.Id, default));
        Assert.Empty(db.Set<EquipmentQuote>());
    }
    [Fact] public async Task ReservationRefusesNonTransactionalDatabase()
    {
        await using var db = Db();
        await Assert.ThrowsAsync<InvalidOperationException>(() => new InventoryService(db, Mock.Of<IEquipmentPricingClient>()).ReserveAsync(Guid.NewGuid(), Guid.NewGuid(), default));
    }
}
