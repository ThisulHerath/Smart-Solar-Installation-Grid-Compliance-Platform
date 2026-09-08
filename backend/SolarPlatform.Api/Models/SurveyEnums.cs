namespace SolarPlatform.Api.Models;

public enum GridType { SinglePhase, ThreePhase, Unknown }
public enum RoofOrientation { North, South, East, West, NorthEast, NorthWest, SouthEast, SouthWest, Unknown }
public enum SurveyStatus { Draft, Submitted, Processing, AnalysisComplete, Failed, Cancelled }
public enum WorkflowStatus { Pending, Processing, Completed, Failed }
public enum SurveyImageType { ElectricityBill, RoofSite }
