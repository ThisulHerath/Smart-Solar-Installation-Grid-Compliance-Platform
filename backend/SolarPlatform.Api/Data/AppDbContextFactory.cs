using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace SolarPlatform.Api.Data;

public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
        
        var connectionString = Environment.GetEnvironmentVariable("DATABASE_CONNECTION_STRING")
            ?? "Host=ep-steep-band-56603943.us-east-2.aws.neon.tech;Database=neondb;Username=neondb_owner;Password=dummy;SSL Mode=Require;Trust Server Certificate=true";

        optionsBuilder.UseNpgsql(connectionString);

        return new AppDbContext(optionsBuilder.Options);
    }
}
