using System.Text.Json;
using System.Data.Common;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Moq;
using Npgsql;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;
using SolarPlatform.Api.Models;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Tests;

public class PostgresFactAttribute : FactAttribute
{
    public PostgresFactAttribute()
    {
        if (string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("TEST_DATABASE_CONNECTION_STRING")))
            Skip = "Set TEST_DATABASE_CONNECTION_STRING to run isolated PostgreSQL migration and transaction tests.";
    }
}

public class InventoryPostgresTests
{
    // Each run owns a unique schema. Cleanup cannot target public or an existing project schema.
    [PostgresFact]
    public async Task Migration_Concurrency_Release_Rollback_AndConstraints()
    {
        var builder = new NpgsqlConnectionStringBuilder(Environment.GetEnvironmentVariable("TEST_DATABASE_CONNECTION_STRING")!);
        // Neon transaction pooling ignores session search_path. Isolation needs a direct connection.
        if (builder.Host?.EndsWith(".neon.tech", StringComparison.OrdinalIgnoreCase) == true)
            builder.Host = builder.Host.Replace("-pooler.", ".", StringComparison.OrdinalIgnoreCase);
        var connection = builder.ConnectionString;
        var schema = "test_inventory_" + Guid.NewGuid().ToString("N");
        await using var admin = new NpgsqlConnection(connection); await admin.OpenAsync();
        await using (var create = new NpgsqlCommand($"CREATE SCHEMA {schema}", admin)) await create.ExecuteNonQueryAsync();
        try
        {
            var scoped = new NpgsqlConnectionStringBuilder(connection) { SearchPath = schema }.ConnectionString;
            var isolate = new SchemaSession(schema);
            var options = new DbContextOptionsBuilder<AppDbContext>().UseNpgsql(scoped, o => o.MigrationsHistoryTable("__EFMigrationsHistory", schema)).AddInterceptors(isolate).Options;
            await using (var db = new AppDbContext(options))
            {
                Assert.Equal(schema, await db.Database.SqlQueryRaw<string>("SELECT current_schema() AS \"Value\"").SingleAsync());
                await db.Database.MigrateAsync();
                Assert.Equal(0, await db.CustomerProfiles.CountAsync());
            }
            var actor = Guid.Parse("eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee");
            var panel = new InventoryItem { SKU = "TEST-P", Name = "Panel", CapacityWatts = 500, UnitPriceUsd = 450, QuantityInStock = 15 };
            var inverter = new InventoryItem { SKU = "TEST-I", Name = "Inverter", Category = EquipmentCategory.INVERTER, CapacityWatts = 5000, UnitPriceUsd = 900, QuantityInStock = 3 };
            var profile = new CustomerProfile { UserId = Guid.Parse("dddddddd-dddd-dddd-dddd-dddddddddddd"), FullName = "Transaction test" };
            var survey = new SolarSurvey { CustomerId = profile.Id, PropertyAddress = "Synthetic test site", MonthlyKwh = 600, RoofAreaSqm = 80 };
            var p1 = new EngineeringProposal { SolarSurveyId = survey.Id, RecommendedKw = 5, ProposalStatus = ProposalStatus.Approved };
            var p2 = new EngineeringProposal { SolarSurveyId = survey.Id, RecommendedKw = 5, ProposalStatus = ProposalStatus.Approved };
            var lines = new List<PricingLine> { new(panel.Id, "Panel", "PANEL", 10, 450, 135000, 1350000), new(inverter.Id, "Inverter", "INVERTER", 1, 900, 270000, 270000) };
            var result = new PricingResult("VALIDATED", 300, DateTime.UtcNow, "USD", "LKR", 1620000, lines, new());
            var q1 = new EquipmentQuote { EngineeringProposalId = p1.Id, Status = "VALIDATED", ResultJson = JsonSerializer.Serialize(result) };
            var q2 = new EquipmentQuote { EngineeringProposalId = p2.Id, Status = "VALIDATED", ResultJson = JsonSerializer.Serialize(result) };
            await using (var db = new AppDbContext(options)) { db.AddRange(profile, survey, p1, p2, panel, inverter, q1, q2); await db.SaveChangesAsync(); }
            async Task<bool> Reserve(Guid id)
            {
                await using var db = new AppDbContext(options);
                try { await new InventoryService(db, Mock.Of<IEquipmentPricingClient>()).ReserveAsync(id, actor, default); return true; }
                catch (Exception e) when (e is InvalidOperationException or DbUpdateException or PostgresException) { return false; }
            }
            var outcomes = await Task.WhenAll(Reserve(q1.Id), Reserve(q2.Id));
            Assert.Single(outcomes.Where(x => x));
            var winner = outcomes[0] ? q1.Id : q2.Id;
            await using (var db = new AppDbContext(options))
            {
                Assert.Equal(10, (await db.Set<InventoryItem>().FindAsync(panel.Id))!.ReservedQuantity);
                Assert.Equal(2, await db.Set<InventoryReservation>().CountAsync(x => x.Status == ReservationStatus.RESERVED));
                await new InventoryService(db, Mock.Of<IEquipmentPricingClient>()).ReserveAsync(winner, actor, default);
                Assert.Equal(2, await db.Set<InventoryReservation>().CountAsync()); // replay is idempotent
            }
            await using (var db = new AppDbContext(options)) await new InventoryService(db, Mock.Of<IEquipmentPricingClient>()).ReleaseAsync(winner, actor, default);
            var loser = outcomes[0] ? q2.Id : q1.Id;
            var failOptions = new DbContextOptionsBuilder<AppDbContext>().UseNpgsql(scoped).AddInterceptors(isolate, new FailReservationSave()).Options;
            await using (var db = new AppDbContext(failOptions))
                await Assert.ThrowsAsync<InvalidOperationException>(() => new InventoryService(db, Mock.Of<IEquipmentPricingClient>()).ReserveAsync(loser, actor, default));
            await using (var db = new AppDbContext(options))
            {
                Assert.Equal(0, (await db.Set<InventoryItem>().FindAsync(panel.Id))!.ReservedQuantity);
                Assert.Equal("VALIDATED", (await db.Set<EquipmentQuote>().FindAsync(loser))!.Status);
                Assert.False(await db.Set<InventoryReservation>().AnyAsync(x => x.EquipmentQuoteId == loser));
                await Assert.ThrowsAsync<PostgresException>(() => db.Database.ExecuteSqlRawAsync("UPDATE \"InventoryItems\" SET \"ReservedQuantity\" = \"QuantityInStock\" + 1"));
            }
        }
        finally
        {
            await using var cleanup = new NpgsqlCommand($"DROP SCHEMA {schema} CASCADE", admin);
            await cleanup.ExecuteNonQueryAsync();
        }
    }

    private class FailReservationSave : SaveChangesInterceptor
    {
        public override ValueTask<InterceptionResult<int>> SavingChangesAsync(DbContextEventData eventData, InterceptionResult<int> result, CancellationToken cancellationToken = default)
        {
            if (eventData.Context!.ChangeTracker.Entries<InventoryReservation>().Any(x => x.State == EntityState.Added))
                throw new InvalidOperationException("Injected persistence failure");
            return base.SavingChangesAsync(eventData, result, cancellationToken);
        }
    }

    private sealed class SchemaSession(string schema) : DbConnectionInterceptor
    {
        public override void ConnectionOpened(DbConnection connection, ConnectionEndEventData eventData)
        {
            using var command = connection.CreateCommand();
            command.CommandText = $"SET search_path TO {schema}";
            command.ExecuteNonQuery();
            command.CommandText = "SELECT current_schema()";
            Assert.Equal(schema, (string?)command.ExecuteScalar());
        }
        public override async Task ConnectionOpenedAsync(DbConnection connection, ConnectionEndEventData eventData, CancellationToken cancellationToken = default)
        {
            await using var command = connection.CreateCommand();
            command.CommandText = $"SET search_path TO {schema}";
            await command.ExecuteNonQueryAsync(cancellationToken);
            command.CommandText = "SELECT current_schema()";
            Assert.Equal(schema, (string?)await command.ExecuteScalarAsync(cancellationToken));
        }
    }
}
