import 'dart:convert';

class SolarSurvey {
  final String id;
  final double monthlyKwh;
  final double roofAreaSqm;
  final String gridType;
  final String propertyAddress;
  final String surveyStatus;
  final List<dynamic> workflows;

  SolarSurvey({
    required this.id,
    required this.monthlyKwh,
    required this.roofAreaSqm,
    required this.gridType,
    required this.propertyAddress,
    required this.surveyStatus,
    required this.workflows,
  });

  factory SolarSurvey.fromJson(Map<String, dynamic> json) => SolarSurvey(
        id: json['id']?.toString() ?? '',
        monthlyKwh: (json['monthlyKwh'] as num?)?.toDouble() ?? 0.0,
        roofAreaSqm: (json['roofAreaSqm'] as num?)?.toDouble() ?? 0.0,
        gridType: json['gridType']?.toString() ?? 'SinglePhase',
        propertyAddress: json['propertyAddress']?.toString() ?? '',
        surveyStatus: json['surveyStatus']?.toString() ?? 'Draft',
        workflows: json['workflows'] ?? [],
      );

  Map<String, dynamic>? get latestWorkflow {
    if (workflows.isEmpty) return null;
    final item = workflows.last;
    return item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map);
  }

  Map<String, dynamic>? get parsedResult {
    final wf = latestWorkflow;
    if (wf == null || wf['resultJson'] == null) return null;
    try {
      final raw = wf['resultJson'].toString();
      if (raw.isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? get parsedValidation {
    final wf = latestWorkflow;
    if (wf == null || wf['validationJson'] == null) return null;
    try {
      final raw = wf['validationJson'].toString();
      if (raw.isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  double? get recommendedKw {
    final res = parsedResult;
    if (res == null || res['recommended_kw'] == null) return null;
    return (res['recommended_kw'] as num).toDouble();
  }

  int? get panelCount {
    final res = parsedResult;
    if (res == null || res['estimated_panel_count'] == null) return null;
    return (res['estimated_panel_count'] as num).toInt();
  }

  double? get inverterKw {
    final res = parsedResult;
    if (res == null || res['estimated_inverter_kw'] == null) return null;
    return (res['estimated_inverter_kw'] as num).toDouble();
  }

  bool? get isValid {
    final val = parsedValidation;
    if (val == null || val['valid'] == null) return null;
    return val['valid'] as bool;
  }

  String? get errorMessage {
    final wf = latestWorkflow;
    if (wf != null && wf['errorMessage'] != null && wf['errorMessage'].toString().isNotEmpty) {
      return wf['errorMessage'].toString();
    }
    return null;
  }
}
