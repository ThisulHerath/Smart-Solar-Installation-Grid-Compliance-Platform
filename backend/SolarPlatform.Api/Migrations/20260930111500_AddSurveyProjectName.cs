using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using SolarPlatform.Api.Data;

#nullable disable

namespace SolarPlatform.Api.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("20260930111500_AddSurveyProjectName")]
public partial class AddSurveyProjectName : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(
            name: "ProjectName",
            table: "SolarSurveys",
            type: "character varying(120)",
            maxLength: 120,
            nullable: false,
            defaultValue: "Solar project");

        migrationBuilder.Sql(
            "UPDATE \"SolarSurveys\" SET \"ProjectName\" = LEFT(\"PropertyAddress\", 120) " +
            "WHERE \"PropertyAddress\" IS NOT NULL AND BTRIM(\"PropertyAddress\") <> '';");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(name: "ProjectName", table: "SolarSurveys");
    }
}
