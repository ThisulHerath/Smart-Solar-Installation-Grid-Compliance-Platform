import 'package:flutter_test/flutter_test.dart';
import 'package:smart_solar_mobile/models/field_job.dart';
import 'package:smart_solar_mobile/models/user.dart';

void main() {
  group('FieldJob & Compliance Model Tests', () {
    test('FieldJob parses job details, inspection status, and compliance results', () {
      final json = {
        'id': 'job-001',
        'solarSurveyId': 'survey-100',
        'technicianId': 'tech-100',
        'technicianName': 'Lead Field Technician',
        'customerName': 'Kamal Perera',
        'customerPhone': '+94771234567',
        'propertyAddress': '45 Galle Road, Colombo 03',
        'monthlyKwh': 1200.0,
        'roofAreaSqm': 85.0,
        'latitude': 6.9271,
        'longitude': 79.8612,
        'status': 'ComplianceComplete',
        'priority': 'High',
        'assignedAt': '2026-09-09T08:00:00Z',
        'hasInspection': true,
        'inspectionStatus': 'Submitted',
        'compliance': {
          'id': 'comp-001',
          'siteInspectionId': 'insp-001',
          'workflowId': 'wf-comp-test',
          'gridCompliant': true,
          'complianceStatus': 'COMPLIANT',
          'riskLevel': 'LOW',
          'complianceNotes': 'Voltage 230V stable and compliant with CEB standards.',
          'validationStatus': 'PASSED',
        },
      };

      final job = FieldJob.fromJson(json);

      expect(job.id, 'job-001');
      expect(job.customerName, 'Kamal Perera');
      expect(job.status, 'ComplianceComplete');
      expect(job.hasInspection, true);
      expect(job.compliance, isNotNull);
      expect(job.compliance!.gridCompliant, true);
      expect(job.compliance!.complianceStatus, 'COMPLIANT');
      expect(job.compliance!.riskLevel, 'LOW');
    });

    test('FieldJob parses non-compliant status and risk level correctly', () {
      final json = {
        'id': 'job-002',
        'solarSurveyId': 'survey-200',
        'technicianId': 'tech-100',
        'technicianName': 'Lead Field Technician',
        'customerName': 'Nimal Silva',
        'customerPhone': '+94779876543',
        'propertyAddress': '12 Kandy Road',
        'monthlyKwh': 800.0,
        'roofAreaSqm': 50.0,
        'status': 'Failed',
        'priority': 'Medium',
        'assignedAt': '2026-09-09T08:00:00Z',
        'hasInspection': true,
        'compliance': {
          'id': 'comp-002',
          'siteInspectionId': 'insp-002',
          'gridCompliant': false,
          'complianceStatus': 'NON_COMPLIANT',
          'riskLevel': 'HIGH',
          'complianceNotes': 'Grid voltage 258V exceeds +6% CEB statutory ceiling.',
          'validationStatus': 'PASSED',
        },
      };

      final job = FieldJob.fromJson(json);

      expect(job.status, 'Failed');
      expect(job.compliance!.gridCompliant, false);
      expect(job.compliance!.complianceStatus, 'NON_COMPLIANT');
      expect(job.compliance!.riskLevel, 'HIGH');
    });

    test('Field Technician role is identified properly', () {
      final userJson = {
        'id': 'tech-user-1',
        'email': 'technician@smartsolar.local',
        'fullName': 'Lead Field Technician',
        'roles': ['FIELD_TECHNICIAN'],
        'createdAt': '2026-09-09T00:00:00Z',
      };

      final user = User.fromJson(userJson);
      expect(user.roles, contains('FIELD_TECHNICIAN'));
    });
  });
}
