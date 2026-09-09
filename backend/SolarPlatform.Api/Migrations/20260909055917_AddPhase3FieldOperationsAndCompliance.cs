using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SolarPlatform.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddPhase3FieldOperationsAndCompliance : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "FieldJobs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SolarSurveyId = table.Column<Guid>(type: "uuid", nullable: false),
                    TechnicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    AssignedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ScheduledAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Status = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Priority = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FieldJobs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_FieldJobs_SolarSurveys_SolarSurveyId",
                        column: x => x.SolarSurveyId,
                        principalTable: "SolarSurveys",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_FieldJobs_Users_TechnicianId",
                        column: x => x.TechnicianId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SiteInspections",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    FieldJobId = table.Column<Guid>(type: "uuid", nullable: false),
                    CheckInLatitude = table.Column<decimal>(type: "numeric(9,6)", precision: 9, scale: 6, nullable: true),
                    CheckInLongitude = table.Column<decimal>(type: "numeric(9,6)", precision: 9, scale: 6, nullable: true),
                    CheckInAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    RoofAreaMeasuredSqm = table.Column<decimal>(type: "numeric(12,2)", precision: 12, scale: 2, nullable: true),
                    RoofOrientation = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    RoofTilt = table.Column<decimal>(type: "numeric(6,2)", precision: 6, scale: 2, nullable: true),
                    GridTypeObserved = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    PhaseCount = table.Column<int>(type: "integer", nullable: true),
                    MainBreakerRating = table.Column<decimal>(type: "numeric(8,2)", precision: 8, scale: 2, nullable: true),
                    InverterLocationSuitable = table.Column<bool>(type: "boolean", nullable: true),
                    SafetyNotes = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    TechnicianNotes = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    InspectionStatus = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SiteInspections", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SiteInspections_FieldJobs_FieldJobId",
                        column: x => x.FieldJobId,
                        principalTable: "FieldJobs",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ComplianceAssessments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SiteInspectionId = table.Column<Guid>(type: "uuid", nullable: false),
                    WorkflowId = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    GridCompliant = table.Column<bool>(type: "boolean", nullable: false),
                    ComplianceStatus = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    RiskLevel = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ComplianceNotes = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    ValidationStatus = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ComplianceAssessments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ComplianceAssessments_SiteInspections_SiteInspectionId",
                        column: x => x.SiteInspectionId,
                        principalTable: "SiteInspections",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SitePhotos",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SiteInspectionId = table.Column<Guid>(type: "uuid", nullable: false),
                    PhotoType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    FileUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    FileName = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SitePhotos", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SitePhotos_SiteInspections_SiteInspectionId",
                        column: x => x.SiteInspectionId,
                        principalTable: "SiteInspections",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SiteTelemetry",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SiteInspectionId = table.Column<Guid>(type: "uuid", nullable: false),
                    MeasurementType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    MeasurementValue = table.Column<decimal>(type: "numeric(12,4)", precision: 12, scale: 4, nullable: false),
                    Unit = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    RecordedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SiteTelemetry", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SiteTelemetry_SiteInspections_SiteInspectionId",
                        column: x => x.SiteInspectionId,
                        principalTable: "SiteInspections",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ComplianceAssessments_SiteInspectionId",
                table: "ComplianceAssessments",
                column: "SiteInspectionId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_FieldJobs_SolarSurveyId",
                table: "FieldJobs",
                column: "SolarSurveyId");

            migrationBuilder.CreateIndex(
                name: "IX_FieldJobs_Status",
                table: "FieldJobs",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_FieldJobs_TechnicianId",
                table: "FieldJobs",
                column: "TechnicianId");

            migrationBuilder.CreateIndex(
                name: "IX_SiteInspections_FieldJobId",
                table: "SiteInspections",
                column: "FieldJobId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SitePhotos_SiteInspectionId",
                table: "SitePhotos",
                column: "SiteInspectionId");

            migrationBuilder.CreateIndex(
                name: "IX_SiteTelemetry_SiteInspectionId_MeasurementType",
                table: "SiteTelemetry",
                columns: new[] { "SiteInspectionId", "MeasurementType" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ComplianceAssessments");

            migrationBuilder.DropTable(
                name: "SitePhotos");

            migrationBuilder.DropTable(
                name: "SiteTelemetry");

            migrationBuilder.DropTable(
                name: "SiteInspections");

            migrationBuilder.DropTable(
                name: "FieldJobs");
        }
    }
}
