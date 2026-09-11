using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SolarPlatform.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddPhase4LifecycleAuditEvents : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ProposalLifecycleAuditEvents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    EngineeringProposalId = table.Column<Guid>(type: "uuid", nullable: false),
                    WorkflowId = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Event = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Details = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    Timestamp = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProposalLifecycleAuditEvents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ProposalLifecycleAuditEvents_EngineeringProposals_Engineeri~",
                        column: x => x.EngineeringProposalId,
                        principalTable: "EngineeringProposals",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ProposalLifecycleAuditEvents_EngineeringProposalId",
                table: "ProposalLifecycleAuditEvents",
                column: "EngineeringProposalId");

            migrationBuilder.CreateIndex(
                name: "IX_ProposalLifecycleAuditEvents_Timestamp",
                table: "ProposalLifecycleAuditEvents",
                column: "Timestamp");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ProposalLifecycleAuditEvents");
        }
    }
}
