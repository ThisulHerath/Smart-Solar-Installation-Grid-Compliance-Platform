using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SolarPlatform.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddPhase4EngineeringProposal : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "EngineeringProposals",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SolarSurveyId = table.Column<Guid>(type: "uuid", nullable: false),
                    WorkflowId = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    RecommendedKw = table.Column<decimal>(type: "numeric(10,3)", precision: 10, scale: 3, nullable: false),
                    PanelCount = table.Column<int>(type: "integer", nullable: false),
                    InverterSizeKw = table.Column<decimal>(type: "numeric(10,3)", precision: 10, scale: 3, nullable: false),
                    EstimatedCostLkr = table.Column<decimal>(type: "numeric(14,2)", precision: 14, scale: 2, nullable: false),
                    GridComplianceStatus = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    RiskLevel = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    SafetyStatus = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ProposalStatus = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    RecommendationSummary = table.Column<string>(type: "character varying(4000)", maxLength: 4000, nullable: true),
                    EngineerNotes = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    GuardrailResultJson = table.Column<string>(type: "text", nullable: true),
                    ValidationResultJson = table.Column<string>(type: "text", nullable: true),
                    RequiresApproval = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EngineeringProposals", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EngineeringProposals_SolarSurveys_SolarSurveyId",
                        column: x => x.SolarSurveyId,
                        principalTable: "SolarSurveys",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ApprovalAuditLogs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    EngineeringProposalId = table.Column<Guid>(type: "uuid", nullable: false),
                    WorkflowId = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Decision = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Comment = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    Timestamp = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ApprovalAuditLogs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ApprovalAuditLogs_EngineeringProposals_EngineeringProposalId",
                        column: x => x.EngineeringProposalId,
                        principalTable: "EngineeringProposals",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ApprovalAuditLogs_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ApprovalAuditLogs_EngineeringProposalId",
                table: "ApprovalAuditLogs",
                column: "EngineeringProposalId");

            migrationBuilder.CreateIndex(
                name: "IX_ApprovalAuditLogs_Timestamp",
                table: "ApprovalAuditLogs",
                column: "Timestamp");

            migrationBuilder.CreateIndex(
                name: "IX_ApprovalAuditLogs_UserId",
                table: "ApprovalAuditLogs",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_EngineeringProposals_ProposalStatus",
                table: "EngineeringProposals",
                column: "ProposalStatus");

            migrationBuilder.CreateIndex(
                name: "IX_EngineeringProposals_SolarSurveyId",
                table: "EngineeringProposals",
                column: "SolarSurveyId");

            migrationBuilder.CreateIndex(
                name: "IX_EngineeringProposals_SolarSurveyId_ProposalStatus",
                table: "EngineeringProposals",
                columns: new[] { "SolarSurveyId", "ProposalStatus" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ApprovalAuditLogs");

            migrationBuilder.DropTable(
                name: "EngineeringProposals");
        }
    }
}
