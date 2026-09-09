class FieldJob {
  final String id;
  final String solarSurveyId;
  final String technicianId;
  final String technicianName;
  final String customerName;
  final String customerPhone;
  final String propertyAddress;
  final double monthlyKwh;
  final double roofAreaSqm;
  final double? latitude;
  final double? longitude;
  final String status;
  final String priority;
  final DateTime assignedAt;
  final DateTime? scheduledAt;
  final bool hasInspection;
  final String? inspectionStatus;
  final ComplianceAssessmentModel? compliance;

  FieldJob({
    required this.id,
    required this.solarSurveyId,
    required this.technicianId,
    required this.technicianName,
    required this.customerName,
    required this.customerPhone,
    required this.propertyAddress,
    required this.monthlyKwh,
    required this.roofAreaSqm,
    this.latitude,
    this.longitude,
    required this.status,
    required this.priority,
    required this.assignedAt,
    this.scheduledAt,
    required this.hasInspection,
    this.inspectionStatus,
    this.compliance,
  });

  factory FieldJob.fromJson(Map<String, dynamic> json) {
    return FieldJob(
      id: json['id'] as String,
      solarSurveyId: json['solarSurveyId'] as String,
      technicianId: json['technicianId'] as String,
      technicianName: json['technicianName'] as String? ?? 'Unassigned',
      customerName: json['customerName'] as String? ?? 'Unknown Customer',
      customerPhone: json['customerPhone'] as String? ?? '',
      propertyAddress: json['propertyAddress'] as String? ?? '',
      monthlyKwh: (json['monthlyKwh'] as num?)?.toDouble() ?? 0.0,
      roofAreaSqm: (json['roofAreaSqm'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'Assigned',
      priority: json['priority'] as String? ?? 'Medium',
      assignedAt: json['assignedAt'] != null ? DateTime.parse(json['assignedAt'] as String) : DateTime.now(),
      scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt'] as String) : null,
      hasInspection: json['hasInspection'] as bool? ?? false,
      inspectionStatus: json['inspectionStatus'] as String?,
      compliance: json['compliance'] != null
          ? ComplianceAssessmentModel.fromJson(json['compliance'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ComplianceAssessmentModel {
  final String id;
  final String siteInspectionId;
  final String? workflowId;
  final bool gridCompliant;
  final String complianceStatus;
  final String riskLevel;
  final String? complianceNotes;
  final String? validationStatus;

  ComplianceAssessmentModel({
    required this.id,
    required this.siteInspectionId,
    this.workflowId,
    required this.gridCompliant,
    required this.complianceStatus,
    required this.riskLevel,
    this.complianceNotes,
    this.validationStatus,
  });

  factory ComplianceAssessmentModel.fromJson(Map<String, dynamic> json) {
    return ComplianceAssessmentModel(
      id: json['id'] as String,
      siteInspectionId: json['siteInspectionId'] as String,
      workflowId: json['workflowId'] as String?,
      gridCompliant: json['gridCompliant'] as bool? ?? false,
      complianceStatus: json['complianceStatus'] as String? ?? 'Non-Compliant',
      riskLevel: json['riskLevel'] as String? ?? 'High',
      complianceNotes: json['complianceNotes'] as String?,
      validationStatus: json['validationStatus'] as String?,
    );
  }
}
