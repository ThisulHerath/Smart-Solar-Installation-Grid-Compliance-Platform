using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SolarPlatform.Api.Migrations
{
    /// <inheritdoc />
    public partial class StrengthenAgentWorkflowState : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ApprovalStatus",
                table: "AgentWorkflows",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "NOT_REQUESTED");

            migrationBuilder.AddColumn<string>(
                name: "CurrentStep",
                table: "AgentWorkflows",
                type: "character varying(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "planning");

            migrationBuilder.AddColumn<int>(
                name: "RetryCount",
                table: "AgentWorkflows",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "StateJson",
                table: "AgentWorkflows",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SpanId",
                table: "AgentExecutionLogs",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ToolName",
                table: "AgentExecutionLogs",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TraceId",
                table: "AgentExecutionLogs",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ApprovalStatus",
                table: "AgentWorkflows");

            migrationBuilder.DropColumn(
                name: "CurrentStep",
                table: "AgentWorkflows");

            migrationBuilder.DropColumn(
                name: "RetryCount",
                table: "AgentWorkflows");

            migrationBuilder.DropColumn(
                name: "StateJson",
                table: "AgentWorkflows");

            migrationBuilder.DropColumn(
                name: "SpanId",
                table: "AgentExecutionLogs");

            migrationBuilder.DropColumn(
                name: "ToolName",
                table: "AgentExecutionLogs");

            migrationBuilder.DropColumn(
                name: "TraceId",
                table: "AgentExecutionLogs");
        }
    }
}
