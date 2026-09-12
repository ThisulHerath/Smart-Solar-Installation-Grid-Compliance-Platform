using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SolarPlatform.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddEmailVerification : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "EmailVerifiedAt",
                table: "Users",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SecurityVersion",
                table: "Users",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "EmailChallenges",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    Purpose = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: true),
                    UserVersion = table.Column<int>(type: "integer", nullable: false),
                    CodeHash = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    PasswordHash = table.Column<string>(type: "text", nullable: true),
                    FullName = table.Column<string>(type: "text", nullable: true),
                    PhoneNumber = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ConsumedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Attempts = table.Column<int>(type: "integer", nullable: false),
                    Revision = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EmailChallenges", x => x.Id);
                });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"),
                columns: new[] { "EmailVerifiedAt", "SecurityVersion" },
                values: new object[] { null, 0 });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"),
                columns: new[] { "EmailVerifiedAt", "SecurityVersion" },
                values: new object[] { null, 0 });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-cccc-cccc-cccc-cccccccccccc"),
                columns: new[] { "EmailVerifiedAt", "SecurityVersion" },
                values: new object[] { null, 0 });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("dddddddd-dddd-dddd-dddd-dddddddddddd"),
                columns: new[] { "EmailVerifiedAt", "SecurityVersion" },
                values: new object[] { null, 0 });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"),
                columns: new[] { "EmailVerifiedAt", "SecurityVersion" },
                values: new object[] { null, 0 });

            migrationBuilder.CreateIndex(
                name: "IX_EmailChallenges_Email_CreatedAt",
                table: "EmailChallenges",
                columns: new[] { "Email", "CreatedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "EmailChallenges");

            migrationBuilder.DropColumn(
                name: "EmailVerifiedAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "SecurityVersion",
                table: "Users");
        }
    }
}
