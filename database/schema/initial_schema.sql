CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

START TRANSACTION;

CREATE TABLE "Roles" (
    "Id" uuid NOT NULL,
    "Name" character varying(100) NOT NULL,
    "Description" character varying(500),
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT (CURRENT_TIMESTAMP),
    "UpdatedAt" timestamp with time zone NOT NULL DEFAULT (CURRENT_TIMESTAMP),
    CONSTRAINT "PK_Roles" PRIMARY KEY ("Id")
);

CREATE TABLE "Users" (
    "Id" uuid NOT NULL,
    "Email" character varying(255) NOT NULL,
    "PasswordHash" text NOT NULL,
    "FullName" character varying(255) NOT NULL,
    "PhoneNumber" character varying(50),
    "IsActive" boolean NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT (CURRENT_TIMESTAMP),
    "UpdatedAt" timestamp with time zone NOT NULL DEFAULT (CURRENT_TIMESTAMP),
    CONSTRAINT "PK_Users" PRIMARY KEY ("Id")
);

CREATE TABLE "UserRoles" (
    "UserId" uuid NOT NULL,
    "RoleId" uuid NOT NULL,
    CONSTRAINT "PK_UserRoles" PRIMARY KEY ("UserId", "RoleId"),
    CONSTRAINT "FK_UserRoles_Roles_RoleId" FOREIGN KEY ("RoleId") REFERENCES "Roles" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_UserRoles_Users_UserId" FOREIGN KEY ("UserId") REFERENCES "Users" ("Id") ON DELETE CASCADE
);

INSERT INTO "Roles" ("Id", "CreatedAt", "Description", "Name", "UpdatedAt")
VALUES ('11111111-1111-1111-1111-111111111111', TIMESTAMPTZ '2026-01-01T00:00:00Z', 'Full system administration and oversight', 'ADMINISTRATOR', TIMESTAMPTZ '2026-01-01T00:00:00Z');
INSERT INTO "Roles" ("Id", "CreatedAt", "Description", "Name", "UpdatedAt")
VALUES ('22222222-2222-2222-2222-222222222222', TIMESTAMPTZ '2026-01-01T00:00:00Z', 'Technical approval and engineering validation', 'SENIOR_ENGINEER', TIMESTAMPTZ '2026-01-01T00:00:00Z');
INSERT INTO "Roles" ("Id", "CreatedAt", "Description", "Name", "UpdatedAt")
VALUES ('33333333-3333-3333-3333-333333333333', TIMESTAMPTZ '2026-01-01T00:00:00Z', 'On-site solar site survey and mobile telemetry', 'FIELD_TECHNICIAN', TIMESTAMPTZ '2026-01-01T00:00:00Z');
INSERT INTO "Roles" ("Id", "CreatedAt", "Description", "Name", "UpdatedAt")
VALUES ('44444444-4444-4444-4444-444444444444', TIMESTAMPTZ '2026-01-01T00:00:00Z', 'Customer solar proposal viewer and applicant', 'HOMEOWNER', TIMESTAMPTZ '2026-01-01T00:00:00Z');
INSERT INTO "Roles" ("Id", "CreatedAt", "Description", "Name", "UpdatedAt")
VALUES ('55555555-5555-5555-5555-555555555555', TIMESTAMPTZ '2026-01-01T00:00:00Z', 'Stock management and hardware pricing tracking', 'INVENTORY_OFFICER', TIMESTAMPTZ '2026-01-01T00:00:00Z');

INSERT INTO "Users" ("Id", "CreatedAt", "Email", "FullName", "IsActive", "PasswordHash", "PhoneNumber", "UpdatedAt")
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', TIMESTAMPTZ '2026-01-01T00:00:00Z', 'admin@smartsolar.local', 'System Administrator', TRUE, '$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '+94770000001', TIMESTAMPTZ '2026-01-01T00:00:00Z');
INSERT INTO "Users" ("Id", "CreatedAt", "Email", "FullName", "IsActive", "PasswordHash", "PhoneNumber", "UpdatedAt")
VALUES ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', TIMESTAMPTZ '2026-01-01T00:00:00Z', 'engineer@smartsolar.local', 'Senior Grid Engineer', TRUE, '$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '+94770000002', TIMESTAMPTZ '2026-01-01T00:00:00Z');
INSERT INTO "Users" ("Id", "CreatedAt", "Email", "FullName", "IsActive", "PasswordHash", "PhoneNumber", "UpdatedAt")
VALUES ('cccccccc-cccc-cccc-cccc-cccccccccccc', TIMESTAMPTZ '2026-01-01T00:00:00Z', 'technician@smartsolar.local', 'Lead Field Technician', TRUE, '$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '+94770000003', TIMESTAMPTZ '2026-01-01T00:00:00Z');
INSERT INTO "Users" ("Id", "CreatedAt", "Email", "FullName", "IsActive", "PasswordHash", "PhoneNumber", "UpdatedAt")
VALUES ('dddddddd-dddd-dddd-dddd-dddddddddddd', TIMESTAMPTZ '2026-01-01T00:00:00Z', 'homeowner@smartsolar.local', 'Sample Homeowner', TRUE, '$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '+94770000004', TIMESTAMPTZ '2026-01-01T00:00:00Z');
INSERT INTO "Users" ("Id", "CreatedAt", "Email", "FullName", "IsActive", "PasswordHash", "PhoneNumber", "UpdatedAt")
VALUES ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', TIMESTAMPTZ '2026-01-01T00:00:00Z', 'inventory@smartsolar.local', 'Inventory Officer', TRUE, '$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '+94770000005', TIMESTAMPTZ '2026-01-01T00:00:00Z');

INSERT INTO "UserRoles" ("RoleId", "UserId")
VALUES ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
INSERT INTO "UserRoles" ("RoleId", "UserId")
VALUES ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
INSERT INTO "UserRoles" ("RoleId", "UserId")
VALUES ('33333333-3333-3333-3333-333333333333', 'cccccccc-cccc-cccc-cccc-cccccccccccc');
INSERT INTO "UserRoles" ("RoleId", "UserId")
VALUES ('44444444-4444-4444-4444-444444444444', 'dddddddd-dddd-dddd-dddd-dddddddddddd');
INSERT INTO "UserRoles" ("RoleId", "UserId")
VALUES ('55555555-5555-5555-5555-555555555555', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee');

CREATE UNIQUE INDEX "IX_Roles_Name" ON "Roles" ("Name");

CREATE INDEX "IX_UserRoles_RoleId" ON "UserRoles" ("RoleId");

CREATE UNIQUE INDEX "IX_Users_Email" ON "Users" ("Email");

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260907135359_InitialCreate', '8.0.8');

COMMIT;

