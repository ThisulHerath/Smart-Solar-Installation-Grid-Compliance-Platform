# Database Design & Schema

## Database Provider
- **Provider**: Neon Managed PostgreSQL
- **Project ID**: `steep-band-56603943`
- **Branch**: `production`
- **ORM**: Entity Framework Core 8.0 with `Npgsql.EntityFrameworkCore.PostgreSQL`

## Entity-Relationship Model
```mermaid
erDiagram
    USERS ||--o{ USER_ROLES : has
    ROLES ||--o{ USER_ROLES : assigned_to

    USERS {
        uuid Id PK
        varchar(255) Email UK
        text PasswordHash
        varchar(255) FullName
        varchar(50) PhoneNumber
        boolean IsActive
        timestamp CreatedAt
        timestamp UpdatedAt
    }

    ROLES {
        uuid Id PK
        varchar(100) Name UK
        varchar(500) Description
        timestamp CreatedAt
        timestamp UpdatedAt
    }

    USER_ROLES {
        uuid UserId PK, FK
        uuid RoleId PK, FK
    }
```

## Core Seed Data
The database seeds 5 core system roles:
- `ADMINISTRATOR`
- `SENIOR_ENGINEER`
- `FIELD_TECHNICIAN`
- `HOMEOWNER`
- `INVENTORY_OFFICER`
