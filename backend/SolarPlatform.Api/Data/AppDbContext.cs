using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // User Configuration
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(u => u.Id);
            entity.HasIndex(u => u.Email).IsUnique();
            entity.Property(u => u.Email).IsRequired().HasMaxLength(255);
            entity.Property(u => u.PasswordHash).IsRequired();
            entity.Property(u => u.FullName).IsRequired().HasMaxLength(255);
            entity.Property(u => u.PhoneNumber).HasMaxLength(50);
            entity.Property(u => u.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.Property(u => u.UpdatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
        });

        // Role Configuration
        modelBuilder.Entity<Role>(entity =>
        {
            entity.HasKey(r => r.Id);
            entity.HasIndex(r => r.Name).IsUnique();
            entity.Property(r => r.Name).IsRequired().HasMaxLength(100);
            entity.Property(r => r.Description).HasMaxLength(500);
            entity.Property(r => r.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.Property(r => r.UpdatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
        });

        // UserRole Many-to-Many Configuration
        modelBuilder.Entity<UserRole>(entity =>
        {
            entity.HasKey(ur => new { ur.UserId, ur.RoleId });

            entity.HasOne(ur => ur.User)
                  .WithMany(u => u.UserRoles)
                  .HasForeignKey(ur => ur.UserId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(ur => ur.Role)
                  .WithMany(r => r.UserRoles)
                  .HasForeignKey(ur => ur.RoleId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // Seed Foundation Data
        SeedData(modelBuilder);
    }

    private static void SeedData(ModelBuilder modelBuilder)
    {
        var adminRoleId = Guid.Parse("11111111-1111-1111-1111-111111111111");
        var engineerRoleId = Guid.Parse("22222222-2222-2222-2222-222222222222");
        var techRoleId = Guid.Parse("33333333-3333-3333-3333-333333333333");
        var homeownerRoleId = Guid.Parse("44444444-4444-4444-4444-444444444444");
        var inventoryRoleId = Guid.Parse("55555555-5555-5555-5555-555555555555");

        var fixedSeedDate = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        modelBuilder.Entity<Role>().HasData(
            new Role { Id = adminRoleId, Name = RoleConstants.Administrator, Description = "Full system administration and oversight", CreatedAt = fixedSeedDate, UpdatedAt = fixedSeedDate },
            new Role { Id = engineerRoleId, Name = RoleConstants.SeniorEngineer, Description = "Technical approval and engineering validation", CreatedAt = fixedSeedDate, UpdatedAt = fixedSeedDate },
            new Role { Id = techRoleId, Name = RoleConstants.FieldTechnician, Description = "On-site solar site survey and mobile telemetry", CreatedAt = fixedSeedDate, UpdatedAt = fixedSeedDate },
            new Role { Id = homeownerRoleId, Name = RoleConstants.Homeowner, Description = "Customer solar proposal viewer and applicant", CreatedAt = fixedSeedDate, UpdatedAt = fixedSeedDate },
            new Role { Id = inventoryRoleId, Name = RoleConstants.InventoryOfficer, Description = "Stock management and hardware pricing tracking", CreatedAt = fixedSeedDate, UpdatedAt = fixedSeedDate }
        );

        // Pre-computed BCrypt hashes (work factor 11 for "Admin@123456", "Engineer@123456", etc.)
        // Password for all seed test accounts: "Password@123"
        var passwordHash = "$2a$11$I21L0j8ig1EC8yNf7e7OW./PDbdbvnJvg9EQ8jUBFpaePRnteRGAW"; // "Password@123"

        var adminUserId = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
        var engineerUserId = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
        var techUserId = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc");
        var homeownerUserId = Guid.Parse("dddddddd-dddd-dddd-dddd-dddddddddddd");
        var inventoryUserId = Guid.Parse("eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee");

        modelBuilder.Entity<User>().HasData(
            new User { Id = adminUserId, Email = "admin@smartsolar.local", PasswordHash = passwordHash, FullName = "System Administrator", PhoneNumber = "+94770000001", IsActive = true, CreatedAt = fixedSeedDate, UpdatedAt = fixedSeedDate },
            new User { Id = engineerUserId, Email = "engineer@smartsolar.local", PasswordHash = passwordHash, FullName = "Senior Grid Engineer", PhoneNumber = "+94770000002", IsActive = true, CreatedAt = fixedSeedDate, UpdatedAt = fixedSeedDate },
            new User { Id = techUserId, Email = "technician@smartsolar.local", PasswordHash = passwordHash, FullName = "Lead Field Technician", PhoneNumber = "+94770000003", IsActive = true, CreatedAt = fixedSeedDate, UpdatedAt = fixedSeedDate },
            new User { Id = homeownerUserId, Email = "homeowner@smartsolar.local", PasswordHash = passwordHash, FullName = "Sample Homeowner", PhoneNumber = "+94770000004", IsActive = true, CreatedAt = fixedSeedDate, UpdatedAt = fixedSeedDate },
            new User { Id = inventoryUserId, Email = "inventory@smartsolar.local", PasswordHash = passwordHash, FullName = "Inventory Officer", PhoneNumber = "+94770000005", IsActive = true, CreatedAt = fixedSeedDate, UpdatedAt = fixedSeedDate }
        );

        modelBuilder.Entity<UserRole>().HasData(
            new UserRole { UserId = adminUserId, RoleId = adminRoleId },
            new UserRole { UserId = engineerUserId, RoleId = engineerRoleId },
            new UserRole { UserId = techUserId, RoleId = techRoleId },
            new UserRole { UserId = homeownerUserId, RoleId = homeownerRoleId },
            new UserRole { UserId = inventoryUserId, RoleId = inventoryRoleId }
        );
    }
}
