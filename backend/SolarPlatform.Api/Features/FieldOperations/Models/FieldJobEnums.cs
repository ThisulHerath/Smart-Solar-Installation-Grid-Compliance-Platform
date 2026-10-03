namespace SolarPlatform.Api.Models;

/// <summary>Controlled lifecycle for field job processing.</summary>
public enum FieldJobStatus
{
    Assigned,
    Accepted,
    InProgress,
    Submitted,
    ComplianceProcessing,
    ComplianceComplete,
    Failed
}

public enum FieldJobPriority { Low, Medium, High, Urgent }

public enum InspectionStatus { Draft, Submitted, Reviewed }

/// <summary>Supported site telemetry measurement types.</summary>
public enum MeasurementType { Voc, Isc, Vmp, Imp, Irradiance, Temperature, GridVoltage, GridFrequency }

/// <summary>Classification for site evidence photographs.</summary>
public enum SitePhotoType { Roof, Meter, ElectricalPanel, InverterLocation, SafetyIssue, Other }
