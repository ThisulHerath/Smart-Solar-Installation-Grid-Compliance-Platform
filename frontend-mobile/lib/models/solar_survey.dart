class SolarSurvey {
  final String id;
  final double monthlyKwh;
  final double roofAreaSqm;
  final String gridType;
  final String propertyAddress;
  final String surveyStatus;
  final List<dynamic> workflows;

  SolarSurvey({required this.id, required this.monthlyKwh, required this.roofAreaSqm, required this.gridType, required this.propertyAddress, required this.surveyStatus, required this.workflows});

  factory SolarSurvey.fromJson(Map<String, dynamic> json) => SolarSurvey(
    id: json['id'], monthlyKwh: (json['monthlyKwh'] as num).toDouble(), roofAreaSqm: (json['roofAreaSqm'] as num).toDouble(),
    gridType: json['gridType'].toString(), propertyAddress: json['propertyAddress'], surveyStatus: json['surveyStatus'].toString(), workflows: json['workflows'] ?? [],
  );
}
