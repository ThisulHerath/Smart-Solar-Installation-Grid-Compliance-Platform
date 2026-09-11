using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Data;

public static class InventoryConfiguration
{
    public static void ConfigureInventory(this ModelBuilder builder)
    {
        builder.Entity<Supplier>(e => {
            e.Property(x => x.Name).HasMaxLength(200).IsRequired();
            e.Property(x => x.ContactEmail).HasMaxLength(255);
            e.Property(x => x.Phone).HasMaxLength(50);
        });
        builder.Entity<InventoryItem>(e => {
            e.HasIndex(x => x.SKU).IsUnique();
            e.Property(x => x.SKU).HasMaxLength(80).IsRequired();
            e.Property(x => x.Name).HasMaxLength(200).IsRequired();
            e.Property(x => x.Manufacturer).HasMaxLength(200);
            e.Property(x => x.Model).HasMaxLength(200);
            e.Property(x => x.Category).HasConversion<string>().HasMaxLength(20);
            e.Property(x => x.UnitPriceUsd).HasPrecision(14, 2);
            e.Property(x => x.CapacityWatts).HasPrecision(12, 2);
            e.Property(x => x.Version).IsConcurrencyToken();
            e.HasOne(x => x.Supplier).WithMany().HasForeignKey(x => x.SupplierId).OnDelete(DeleteBehavior.Restrict);
            e.ToTable("InventoryItems", t => {
                t.HasCheckConstraint("CK_Inventory_Stock", "\"QuantityInStock\" >= 0 AND \"ReservedQuantity\" >= 0 AND \"ReservedQuantity\" <= \"QuantityInStock\" AND \"ReorderLevel\" >= 0");
                t.HasCheckConstraint("CK_Inventory_Price", "\"UnitPriceUsd\" > 0 AND \"CapacityWatts\" > 0");
            });
        });
        builder.Entity<EquipmentQuote>(e => {
            e.HasIndex(x => new { x.EngineeringProposalId, x.CreatedAt });
            e.Property(x => x.Status).HasMaxLength(30);
            e.Property(x => x.Error).HasMaxLength(500);
            e.HasOne(x => x.EngineeringProposal).WithMany().HasForeignKey(x => x.EngineeringProposalId).OnDelete(DeleteBehavior.Restrict);
        });
        builder.Entity<InventoryReservation>(e => {
            e.Property(x => x.Status).HasConversion<string>().HasMaxLength(20);
            e.Property(x => x.UnitPriceUsd).HasPrecision(14, 2);
            e.Property(x => x.ExchangeRate).HasPrecision(18, 6);
            e.Property(x => x.UnitPriceLkr).HasPrecision(18, 2);
            e.Property(x => x.TotalPriceLkr).HasPrecision(18, 2);
            e.HasIndex(x => new { x.EquipmentQuoteId, x.InventoryItemId }).IsUnique();
            e.HasIndex(x => new { x.EngineeringProposalId, x.InventoryItemId }).IsUnique().HasFilter("\"Status\" = 'RESERVED'");
            e.HasOne(x => x.EngineeringProposal).WithMany().HasForeignKey(x => x.EngineeringProposalId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.InventoryItem).WithMany().HasForeignKey(x => x.InventoryItemId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.EquipmentQuote).WithMany(x => x.Reservations).HasForeignKey(x => x.EquipmentQuoteId).OnDelete(DeleteBehavior.Restrict);
            e.ToTable("InventoryReservations", t => t.HasCheckConstraint("CK_Reservation_Quantity", "\"Quantity\" > 0"));
        });
        builder.Entity<InventoryTransaction>(e => {
            e.Property(x => x.TransactionType).HasConversion<string>().HasMaxLength(20);
            e.Property(x => x.Reason).HasMaxLength(500);
            e.HasIndex(x => new { x.InventoryItemId, x.CreatedAt });
            e.HasOne(x => x.InventoryItem).WithMany().HasForeignKey(x => x.InventoryItemId).OnDelete(DeleteBehavior.Restrict);
        });
    }
}
