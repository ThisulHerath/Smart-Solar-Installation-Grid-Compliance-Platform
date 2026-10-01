using System.ComponentModel.DataAnnotations.Schema;

namespace SolarPlatform.Api.Models;

public enum EquipmentCategory { PANEL, INVERTER }
public enum ReservationStatus { PENDING, RESERVED, RELEASED, CANCELLED }
public enum StockTransactionType { RESERVATION, RELEASE, ADJUSTMENT, RESTOCK }

public class Supplier
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = "";
    public string? ContactEmail { get; set; }
    public string? Phone { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class InventoryItem
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string SKU { get; set; } = "";
    public string Name { get; set; } = "";
    public EquipmentCategory Category { get; set; }
    public string Manufacturer { get; set; } = "";
    public string Model { get; set; } = "";
    public Guid? SupplierId { get; set; }
    public Supplier? Supplier { get; set; }
    public decimal CapacityWatts { get; set; }
    public int QuantityInStock { get; set; }
    public int ReservedQuantity { get; set; }
    public int ReorderLevel { get; set; }
    public decimal UnitPriceUsd { get; set; }
    public bool Active { get; set; } = true;
    public Guid Version { get; set; } = Guid.NewGuid();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    [NotMapped] public int AvailableQuantity => QuantityInStock - ReservedQuantity;
    [NotMapped] public bool LowStock => AvailableQuantity <= ReorderLevel;
}

public class EquipmentQuote
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid EngineeringProposalId { get; set; }
    public EngineeringProposal EngineeringProposal { get; set; } = null!;
    public string Status { get; set; } = "PROCESSING";
    public string? Error { get; set; }
    public string ResultJson { get; set; } = "{}";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; } = DateTime.UtcNow.AddHours(1);
    public ICollection<InventoryReservation> Reservations { get; set; } = new List<InventoryReservation>();
}

public class InventoryReservation
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid EngineeringProposalId { get; set; }
    public EngineeringProposal EngineeringProposal { get; set; } = null!;
    public Guid EquipmentQuoteId { get; set; }
    public EquipmentQuote EquipmentQuote { get; set; } = null!;
    public Guid InventoryItemId { get; set; }
    public InventoryItem InventoryItem { get; set; } = null!;
    public int Quantity { get; set; }
    public decimal UnitPriceUsd { get; set; }
    public decimal ExchangeRate { get; set; }
    public decimal UnitPriceLkr { get; set; }
    public decimal TotalPriceLkr { get; set; }
    public ReservationStatus Status { get; set; } = ReservationStatus.PENDING;
    public DateTime? ReservedAt { get; set; }
    public DateTime? ReleasedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class InventoryTransaction
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid InventoryItemId { get; set; }
    public InventoryItem InventoryItem { get; set; } = null!;
    public StockTransactionType TransactionType { get; set; }
    public int Quantity { get; set; }
    public Guid ReferenceId { get; set; }
    public Guid ActorId { get; set; }
    public string Reason { get; set; } = "";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
