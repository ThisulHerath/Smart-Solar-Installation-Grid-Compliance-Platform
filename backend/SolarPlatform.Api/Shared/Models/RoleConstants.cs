namespace SolarPlatform.Api.Models;

public static class RoleConstants
{
    public const string Homeowner = "HOMEOWNER";
    public const string FieldTechnician = "FIELD_TECHNICIAN";
    public const string SeniorEngineer = "SENIOR_ENGINEER";
    public const string InventoryOfficer = "INVENTORY_OFFICER";
    public const string Administrator = "ADMINISTRATOR";

    public static readonly string[] AllRoles = 
    {
        Homeowner,
        FieldTechnician,
        SeniorEngineer,
        InventoryOfficer,
        Administrator
    };
}
