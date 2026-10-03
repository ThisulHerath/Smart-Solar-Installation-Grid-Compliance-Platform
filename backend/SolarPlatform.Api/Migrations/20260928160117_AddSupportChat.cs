using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SolarPlatform.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddSupportChat : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "SupportConversations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SolarSurveyId = table.Column<Guid>(type: "uuid", nullable: false),
                    HomeownerId = table.Column<Guid>(type: "uuid", nullable: false),
                    TechnicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    LastMessageAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SupportConversations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SupportConversations_SolarSurveys_SolarSurveyId",
                        column: x => x.SolarSurveyId,
                        principalTable: "SolarSurveys",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SupportConversations_Users_HomeownerId",
                        column: x => x.HomeownerId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SupportConversations_Users_TechnicianId",
                        column: x => x.TechnicianId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SupportMessages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ConversationId = table.Column<Guid>(type: "uuid", nullable: false),
                    SenderId = table.Column<Guid>(type: "uuid", nullable: false),
                    Body = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ReadAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                
                constraints: table =>
                {
                    table.PrimaryKey("PK_SupportMessages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SupportMessages_SupportConversations_ConversationId",
                        column: x => x.ConversationId,
                        principalTable: "SupportConversations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SupportMessages_Users_SenderId",
                        column: x => x.SenderId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SupportConversations_HomeownerId_LastMessageAt",
                table: "SupportConversations",
                columns: new[] { "HomeownerId", "LastMessageAt" });

            migrationBuilder.CreateIndex(
                name: "IX_SupportConversations_SolarSurveyId",
                table: "SupportConversations",
                column: "SolarSurveyId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SupportConversations_TechnicianId_LastMessageAt",
                table: "SupportConversations",
                columns: new[] { "TechnicianId", "LastMessageAt" });

            migrationBuilder.CreateIndex(
                name: "IX_SupportMessages_ConversationId_CreatedAt",
                table: "SupportMessages",
                columns: new[] { "ConversationId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_SupportMessages_ConversationId_ReadAt",
                table: "SupportMessages",
                columns: new[] { "ConversationId", "ReadAt" });

            migrationBuilder.CreateIndex(
                name: "IX_SupportMessages_SenderId",
                table: "SupportMessages",
                column: "SenderId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SupportMessages");

            migrationBuilder.DropTable(
                name: "SupportConversations");
        }
    }
}
