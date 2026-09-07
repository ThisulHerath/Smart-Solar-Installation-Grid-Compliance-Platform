# Smart Solar Database Foundation

## Overview
The Smart Solar Installation & Grid Compliance Platform uses **Neon Managed PostgreSQL** as its single source of truth database.

- **Neon Project ID**: `steep-band-56603943`
- **Branch**: `production`
- **ORM Provider**: Entity Framework Core 8.0 with `Npgsql.EntityFrameworkCore.PostgreSQL`

## Schema Management & Migrations
Database schemas are managed using Entity Framework Core code-first migrations. Destructive database drops are strictly prohibited.

### Applying Migrations
To apply migrations to your configured Neon PostgreSQL instance:
```bash
cd backend/SolarPlatform.Api
dotnet ef database update
```

### Adding New Migrations
```bash
cd backend/SolarPlatform.Api
dotnet ef migrations add <MigrationName> --output-dir Migrations
```

### Generating SQL Script
```bash
cd backend/SolarPlatform.Api
dotnet ef migrations script -o ../../database/schema/<script_name>.sql
```

## Seed Data & Roles
The foundation schema seeds the 5 core development roles and test accounts:
1. `ADMINISTRATOR` (`admin@smartsolar.local`)
2. `SENIOR_ENGINEER` (`engineer@smartsolar.local`)
3. `FIELD_TECHNICIAN` (`technician@smartsolar.local`)
4. `HOMEOWNER` (`homeowner@smartsolar.local`)
5. `INVENTORY_OFFICER` (`inventory@smartsolar.local`)

*Default development password for all seed accounts:* `Password@123`
