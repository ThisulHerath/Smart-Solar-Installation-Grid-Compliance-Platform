using System.ComponentModel.DataAnnotations;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.DTOs;

public class InventoryWriteDto
{
    [Required, StringLength(80)] public string SKU { get; set; } = "";
    [Required, StringLength(200)] public string Name { get; set; } = "";
    [EnumDataType(typeof(EquipmentCategory))] public EquipmentCategory Category { get; set; }
    [StringLength(200)] public string Manufacturer { get; set; } = "";
    [StringLength(200)] public string Model { get; set; } = "";
    public Guid? SupplierId { get; set; }
    [Range(typeof(decimal), "0.01", "10000000")] public decimal CapacityWatts { get; set; }
    [Range(0, 1000000)] public int QuantityInStock { get; set; }
    [Range(0, 1000000)] public int ReorderLevel { get; set; }
    [Range(typeof(decimal), "0.01", "10000000")] public decimal UnitPriceUsd { get; set; }
    public bool Active { get; set; } = true;
    public Guid? Version { get; set; }
}
public record StockAdjustmentDto([Range(-1000000,1000000)] int Quantity, [Required, StringLength(500)] string Reason);
public record ReserveEquipmentDto(Guid QuoteId);
public record SupplierWriteDto([Required, StringLength(200)] string Name, [EmailAddress, StringLength(255)] string? ContactEmail, [StringLength(50)] string? Phone);
public record PricingLine(Guid InventoryItemId, string Name, string Category, int Quantity, decimal UnitPriceUsd, decimal UnitPriceLkr, decimal TotalPriceLkr);
public record PricingResult(string Status, decimal ExchangeRate, DateTime RateTimestamp, string BaseCurrency, string TargetCurrency, decimal TotalPriceLkr, List<PricingLine> Lines, List<string> ExecutionLogs);
