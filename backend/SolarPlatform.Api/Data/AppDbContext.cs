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
    public DbSet<CustomerProfile> CustomerProfiles => Set<CustomerProfile>();
    public DbSet<SolarSurvey> SolarSurveys => Set<SolarSurvey>();
    public DbSet<SolarSurveyImage> SolarSurveyImages => Set<SolarSurveyImage>();
    public DbSet<AgentWorkflow> AgentWorkflows => Set<AgentWorkflow>();
    public DbSet<AgentExecutionLog> AgentExecutionLogs => Set<AgentExecutionLog>();
    public DbSet<FieldJob> FieldJobs => Set<FieldJob>();
    public DbSet<SiteInspection> SiteInspections => Set<SiteInspection>();
    public DbSet<SiteTelemetry> SiteTelemetry => Set<SiteTelemetry>();
    public DbSet<SitePhoto> SitePhotos => Set<SitePhoto>();
    public DbSet<ComplianceAssessment> ComplianceAssessments => Set<ComplianceAssessment>();

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

        modelBuilder.Entity<CustomerProfile>(entity =>
        {
            entity.HasKey(p => p.Id);
            entity.HasIndex(p => p.UserId).IsUnique();
            entity.Property(p => p.FullName).IsRequired().HasMaxLength(255);
            entity.Property(p => p.PhoneNumber).HasMaxLength(50);
            entity.Property(p => p.Address).HasMaxLength(500);
            entity.HasOne(p => p.User).WithOne(u => u.CustomerProfile).HasForeignKey<CustomerProfile>(p => p.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<SolarSurvey>(entity =>
        {
            entity.HasKey(s => s.Id);
            entity.HasIndex(s => new { s.CustomerId, s.SurveyStatus });
            entity.Property(s => s.MonthlyKwh).HasPrecision(12, 2).IsRequired();
            entity.Property(s => s.RoofAreaSqm).HasPrecision(12, 2).IsRequired();
            entity.Property(s => s.Latitude).HasPrecision(9, 6);
            entity.Property(s => s.Longitude).HasPrecision(9, 6);
            entity.Property(s => s.PropertyAddress).IsRequired().HasMaxLength(500);
            entity.HasOne(s => s.Customer).WithMany(p => p.Surveys).HasForeignKey(s => s.CustomerId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<SolarSurveyImage>(entity =>
        {
            entity.HasKey(i => i.Id);
            entity.HasIndex(i => i.SolarSurveyId);
            entity.Property(i => i.FileUrl).IsRequired().HasMaxLength(1000);
            entity.Property(i => i.FileName).IsRequired().HasMaxLength(255);
            entity.HasOne(i => i.SolarSurvey).WithMany(s => s.Images).HasForeignKey(i => i.SolarSurveyId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<AgentWorkflow>(entity =>
        {
            entity.HasKey(w => w.Id);
            entity.HasIndex(w => w.WorkflowId).IsUnique();
            entity.HasIndex(w => new { w.SolarSurveyId, w.Status });
            entity.Property(w => w.WorkflowId).IsRequired().HasMaxLength(100);
            entity.Property(w => w.Objective).IsRequired().HasMaxLength(500);
            entity.HasOne(w => w.SolarSurvey).WithMany(s => s.Workflows).HasForeignKey(w => w.SolarSurveyId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<AgentExecutionLog>(entity =>
        {
            entity.HasKey(l => l.Id);
            entity.HasIndex(l => new { l.AgentWorkflowId, l.StartedAt });
            entity.Property(l => l.AgentName).IsRequired().HasMaxLength(100);
            entity.Property(l => l.StepName).IsRequired().HasMaxLength(100);
            entity.Property(l => l.Status).IsRequired().HasMaxLength(50);
            entity.Property(l => l.OutputSummary).HasMaxLength(1000);
            entity.Property(l => l.ErrorMessage).HasMaxLength(1000);
            entity.HasOne(l => l.AgentWorkflow).WithMany(w => w.ExecutionLogs).HasForeignKey(l => l.AgentWorkflowId).OnDelete(DeleteBehavior.Cascade);
        });

        // Field Job Configuration
        modelBuilder.Entity<FieldJob>(entity =>
        {
            entity.HasKey(j => j.Id);
            entity.HasIndex(j => j.SolarSurveyId);
            entity.HasIndex(j => j.TechnicianId);
            entity.HasIndex(j => j.Status);
            entity.Property(j => j.Status).HasConversion<string>().HasMaxLength(50);
            entity.Property(j => j.Priority).HasConversion<string>().HasMaxLength(50);
            entity.HasOne(j => j.SolarSurvey).WithMany().HasForeignKey(j => j.SolarSurveyId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(j => j.Technician).WithMany().HasForeignKey(j => j.TechnicianId).OnDelete(DeleteBehavior.Restrict);
        });

        // Site Inspection Configuration
        modelBuilder.Entity<SiteInspection>(entity =>
        {
            entity.HasKey(i => i.Id);
            entity.HasIndex(i => i.FieldJobId).IsUnique();
            entity.Property(i => i.CheckInLatitude).HasPrecision(9, 6);
            entity.Property(i => i.CheckInLongitude).HasPrecision(9, 6);
            entity.Property(i => i.RoofAreaMeasuredSqm).HasPrecision(12, 2);
            entity.Property(i => i.RoofTilt).HasPrecision(6, 2);
            entity.Property(i => i.MainBreakerRating).HasPrecision(8, 2);
            entity.Property(i => i.RoofOrientation).HasConversion<string>().HasMaxLength(50);
            entity.Property(i => i.GridTypeObserved).HasConversion<string>().HasMaxLength(50);
            entity.Property(i => i.InspectionStatus).HasConversion<string>().HasMaxLength(50);
            entity.Property(i => i.SafetyNotes).HasMaxLength(2000);
            entity.Property(i => i.TechnicianNotes).HasMaxLength(2000);
            entity.HasOne(i => i.FieldJob).WithOne(j => j.Inspection).HasForeignKey<SiteInspection>(i => i.FieldJobId).OnDelete(DeleteBehavior.Cascade);
        });

        // Site Telemetry Configuration
        modelBuilder.Entity<SiteTelemetry>(entity =>
        {
            entity.HasKey(t => t.Id);
            entity.HasIndex(t => new { t.SiteInspectionId, t.MeasurementType });
            entity.Property(t => t.MeasurementType).HasConversion<string>().HasMaxLength(50);
            entity.Property(t => t.MeasurementValue).HasPrecision(12, 4);
            entity.Property(t => t.Unit).HasMaxLength(50);
            entity.HasOne(t => t.SiteInspection).WithMany(i => i.Telemetry).HasForeignKey(t => t.SiteInspectionId).OnDelete(DeleteBehavior.Cascade);
        });

        // Site Photo Configuration
        modelBuilder.Entity<SitePhoto>(entity =>
        {
            entity.HasKey(p => p.Id);
            entity.HasIndex(p => p.SiteInspectionId);
            entity.Property(p => p.PhotoType).HasConversion<string>().HasMaxLength(50);
            entity.Property(p => p.FileUrl).IsRequired().HasMaxLength(1000);
            entity.Property(p => p.FileName).IsRequired().HasMaxLength(255);
            entity.HasOne(p => p.SiteInspection).WithMany(i => i.Photos).HasForeignKey(p => p.SiteInspectionId).OnDelete(DeleteBehavior.Cascade);
        });

        // Compliance Assessment Configuration
        modelBuilder.Entity<ComplianceAssessment>(entity =>
        {
            entity.HasKey(c => c.Id);
            entity.HasIndex(c => c.SiteInspectionId).IsUnique();
            entity.Property(c => c.WorkflowId).HasMaxLength(100);
            entity.Property(c => c.ComplianceStatus).IsRequired().HasMaxLength(50);
            entity.Property(c => c.RiskLevel).IsRequired().HasMaxLength(50);
            entity.Property(c => c.ValidationStatus).HasMaxLength(50);
            entity.Property(c => c.ComplianceNotes).HasMaxLength(2000);
            entity.HasOne(c => c.SiteInspection).WithOne(i => i.ComplianceAssessment).HasForeignKey<ComplianceAssessment>(c => c.SiteInspectionId).OnDelete(DeleteBehavior.Cascade);
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
