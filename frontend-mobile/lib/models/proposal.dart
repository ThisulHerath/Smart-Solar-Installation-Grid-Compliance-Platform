class EngineeringProposalModel {
  final String id;
  final String solarSurveyId;
  final String? workflowId;
  final double recommendedKw;
  final int panelCount;
  final double inverterSizeKw;
  final double estimatedCostLkr;
  final String gridComplianceStatus;
  final String riskLevel;
  final String safetyStatus;
  final String proposalStatus;
  final String? recommendationSummary;
  final String? engineerNotes;
  final String? createdAt;
  final String? updatedAt;
  final List<dynamic> auditLogs;

  EngineeringProposalModel({
    required this.id,
    required this.solarSurveyId,
    this.workflowId,
    required this.recommendedKw,
    required this.panelCount,
    required this.inverterSizeKw,
    required this.estimatedCostLkr,
    required this.gridComplianceStatus,
    required this.riskLevel,
    required this.safetyStatus,
    required this.proposalStatus,
    this.recommendationSummary,
    this.engineerNotes,
    this.createdAt,
    this.updatedAt,
    required this.auditLogs,
  });

  factory EngineeringProposalModel.fromJson(Map<String, dynamic> json) => EngineeringProposalModel(
        id: json['id']?.toString() ?? '',
        solarSurveyId: json['solarSurveyId']?.toString() ?? '',
        workflowId: json['workflowId']?.toString(),
        recommendedKw: (json['recommendedKw'] as num?)?.toDouble() ?? 0.0,
        panelCount: (json['panelCount'] as num?)?.toInt() ?? 0,
        inverterSizeKw: (json['inverterSizeKw'] as num?)?.toDouble() ?? 0.0,
        estimatedCostLkr: (json['estimatedCostLkr'] as num?)?.toDouble() ?? 0.0,
        gridComplianceStatus: json['gridComplianceStatus']?.toString() ?? 'PENDING',
        riskLevel: json['riskLevel']?.toString() ?? 'MEDIUM',
        safetyStatus: json['safetyStatus']?.toString() ?? 'REQUIRES_APPROVAL',
        proposalStatus: json['proposalStatus']?.toString() ?? 'Draft',
        recommendationSummary: json['recommendationSummary']?.toString(),
        engineerNotes: json['engineerNotes']?.toString(),
        createdAt: json['createdAt']?.toString(),
        updatedAt: json['updatedAt']?.toString(),
        auditLogs: json['auditLogs'] ?? [],
      );
}

List<Map<String, dynamic>> parseProposalList(dynamic response) {
  if (response is! List) return <Map<String, dynamic>>[];
  return response
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}
