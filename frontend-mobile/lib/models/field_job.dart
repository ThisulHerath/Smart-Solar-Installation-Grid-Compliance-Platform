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
  final DateTime? checkInAt;
  final String? inspectionStatus;
  final SiteInspectionModel? inspection;
  final ComplianceAssessmentModel? compliance;
  final List<SitePhotoModel> photos;

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
    this.checkInAt,
    this.inspectionStatus,
    this.inspection,
    this.compliance,
    this.photos = const [],
  });

  factory FieldJob.fromJson(Map<String, dynamic> json) {
    final inspectionJson = json['inspection'];
    final inspection = inspectionJson is Map
        ? SiteInspectionModel.fromJson(
            Map<String, dynamic>.from(inspectionJson))
        : null;
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
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'] as String)
          : DateTime.now(),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'] as String)
          : null,
      hasInspection: json['hasInspection'] as bool? ?? false,
      checkInAt: json['checkInAt'] != null
          ? DateTime.tryParse(json['checkInAt'] as String)
          : null,
      inspectionStatus: json['inspectionStatus'] as String?,
      inspection: inspection,
      compliance: json['compliance'] != null
          ? ComplianceAssessmentModel.fromJson(
              json['compliance'] as Map<String, dynamic>)
          : null,
      photos: ((json['photos'] as List<dynamic>?) ??
                  (inspectionJson is Map
                      ? inspectionJson['photos'] as List<dynamic>?
                      : null))
              ?.map((e) =>
                  SitePhotoModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }
}

class SiteInspectionModel {
  final double? roofAreaMeasuredSqm;
  final String roofOrientation;
  final double? roofTilt;
  final String gridTypeObserved;
  final int? phaseCount;
  final double? mainBreakerRating;
  final bool? inverterLocationSuitable;
  final String? safetyNotes;
  final String? technicianNotes;
  final List<SiteTelemetryModel> telemetry;

  const SiteInspectionModel({
    this.roofAreaMeasuredSqm,
    required this.roofOrientation,
    this.roofTilt,
    required this.gridTypeObserved,
    this.phaseCount,
    this.mainBreakerRating,
    this.inverterLocationSuitable,
    this.safetyNotes,
    this.technicianNotes,
    this.telemetry = const [],
  });

  factory SiteInspectionModel.fromJson(Map<String, dynamic> json) {
    return SiteInspectionModel(
      roofAreaMeasuredSqm: (json['roofAreaMeasuredSqm'] as num?)?.toDouble(),
      roofOrientation: json['roofOrientation'] as String? ?? 'Unknown',
      roofTilt: (json['roofTilt'] as num?)?.toDouble(),
      gridTypeObserved: json['gridTypeObserved'] as String? ?? 'SinglePhase',
      phaseCount: (json['phaseCount'] as num?)?.toInt(),
      mainBreakerRating: (json['mainBreakerRating'] as num?)?.toDouble(),
      inverterLocationSuitable: json['inverterLocationSuitable'] as bool?,
      safetyNotes: json['safetyNotes'] as String?,
      technicianNotes: json['technicianNotes'] as String?,
      telemetry: (json['telemetry'] as List<dynamic>?)
              ?.map((item) => SiteTelemetryModel.fromJson(
                  Map<String, dynamic>.from(item as Map)))
              .toList() ??
          const [],
    );
  }
}

class SiteTelemetryModel {
  final String measurementType;
  final double measurementValue;
  final DateTime? recordedAt;

  const SiteTelemetryModel({
    required this.measurementType,
    required this.measurementValue,
    this.recordedAt,
  });

  factory SiteTelemetryModel.fromJson(Map<String, dynamic> json) {
    return SiteTelemetryModel(
      measurementType: json['measurementType'] as String? ?? '',
      measurementValue: (json['measurementValue'] as num?)?.toDouble() ?? 0,
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'] as String)
          : null,
    );
  }
}

class SitePhotoModel {
  final String id;
  final String siteInspectionId;
  final String photoType;
  final String fileUrl;
  final String fileName;
  final DateTime? createdAt;

  SitePhotoModel({
    required this.id,
    required this.siteInspectionId,
    required this.photoType,
    required this.fileUrl,
    required this.fileName,
    this.createdAt,
  });

  factory SitePhotoModel.fromJson(Map<String, dynamic> json) {
    return SitePhotoModel(
      id: json['id'] as String? ?? '',
      siteInspectionId: json['siteInspectionId'] as String? ?? '',
      photoType: json['photoType'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
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
