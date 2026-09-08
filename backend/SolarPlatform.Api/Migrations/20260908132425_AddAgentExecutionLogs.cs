using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SolarPlatform.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddAgentExecutionLogs : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AgentExecutionLogs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    AgentWorkflowId = table.Column<Guid>(type: "uuid", nullable: false),
                    AgentName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    StepName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Status = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    StartedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DurationMs = table.Column<long>(type: "bigint", nullable: true),
                    OutputSummary = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    ValidationResult = table.Column<string>(type: "text", nullable: true),
                    ErrorMessage = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    RetryCount = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AgentExecutionLogs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AgentExecutionLogs_AgentWorkflows_AgentWorkflowId",
                        column: x => x.AgentWorkflowId,
                        principalTable: "AgentWorkflows",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AgentExecutionLogs_AgentWorkflowId_StartedAt",
                table: "AgentExecutionLogs",
                columns: new[] { "AgentWorkflowId", "StartedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AgentExecutionLogs");
        }
    }
}
