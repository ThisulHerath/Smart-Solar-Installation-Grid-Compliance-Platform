import 'package:flutter_test/flutter_test.dart';
import 'package:smart_solar_mobile/features/field_operations/models/field_job.dart';
import 'package:smart_solar_mobile/core/auth/models/user.dart';

void main() {
  group('FieldJob & Compliance Model Tests', () {
    test(
        'FieldJob parses job details, inspection status, and compliance results',
        () {
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
          'complianceNotes':
              'Voltage 230V stable and compliant with CEB standards.',
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
          'complianceNotes':
              'Grid voltage 258V exceeds +6% CEB statutory ceiling.',
          'validationStatus': 'PASSED',
        },
      };

      final job = FieldJob.fromJson(json);

      expect(job.status, 'Failed');
      expect(job.compliance!.gridCompliant, false);
      expect(job.compliance!.complianceStatus, 'NON_COMPLIANT');
      expect(job.compliance!.riskLevel, 'HIGH');
    });

    test('FieldJob parses photos correctly', () {
      final json = {
        'id': 'job-003',
        'solarSurveyId': 'survey-300',
        'technicianId': 'tech-100',
        'technicianName': 'Lead Field Technician',
        'customerName': 'Saman Kumara',
        'customerPhone': '+94771122334',
        'propertyAddress': '100 Negombo Road',
        'monthlyKwh': 500.0,
        'roofAreaSqm': 40.0,
        'status': 'Assigned',
        'priority': 'Low',
        'assignedAt': '2026-09-09T08:00:00Z',
        'hasInspection': true,
        'photos': [
          {
            'id': 'photo-1',
            'siteInspectionId': 'insp-1',
            'photoType': 'Roof',
            'fileUrl': '/uploads/site-photos/roof1.jpg',
            'fileName': 'roof1.jpg',
            'createdAt': '2026-09-09T09:00:00Z',
          },
          {
            'id': 'photo-2',
            'siteInspectionId': 'insp-1',
            'photoType': 'Meter',
            'fileUrl': '/uploads/site-photos/meter1.jpg',
            'fileName': 'meter1.jpg',
            'createdAt': '2026-09-09T09:05:00Z',
          }
        ],
      };

      final job = FieldJob.fromJson(json);
      expect(job.photos.length, 2);
      expect(job.photos[0].photoType, 'Roof');
      expect(job.photos[0].fileUrl, '/uploads/site-photos/roof1.jpg');
      expect(job.photos[1].photoType, 'Meter');
    });

    test('FieldJob restores a saved incomplete inspection draft', () {
      final json = {
        'id': 'job-draft',
        'solarSurveyId': 'survey-draft',
        'technicianId': 'tech-100',
        'technicianName': 'Lead Field Technician',
        'customerName': 'Draft Customer',
        'customerPhone': '+94770000000',
        'propertyAddress': 'Colombo',
        'monthlyKwh': 450,
        'roofAreaSqm': 70,
        'status': 'InProgress',
        'priority': 'Medium',
        'assignedAt': '2026-09-29T08:00:00Z',
        'hasInspection': true,
        'inspectionStatus': 'Draft',
        'inspection': {
          'roofAreaMeasuredSqm': 63.5,
          'roofOrientation': 'South',
          'roofTilt': null,
          'gridTypeObserved': 'ThreePhase',
          'phaseCount': 3,
          'mainBreakerRating': 63,
          'inverterLocationSuitable': true,
          'safetyNotes': 'Access checked',
          'technicianNotes': null,
          'telemetry': [
            {
              'measurementType': 'GridVoltage',
              'measurementValue': 400,
              'recordedAt': '2026-09-29T08:10:00Z'
            }
          ],
          'photos': []
        }
      };

      final job = FieldJob.fromJson(json);

      expect(job.inspection, isNotNull);
      expect(job.inspection!.roofAreaMeasuredSqm, 63.5);
      expect(job.inspection!.roofTilt, isNull);
      expect(job.inspection!.gridTypeObserved, 'ThreePhase');
      expect(job.inspection!.mainBreakerRating, 63);
      expect(job.inspection!.telemetry.single.measurementType, 'GridVoltage');
      expect(job.inspection!.telemetry.single.measurementValue, 400);
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
