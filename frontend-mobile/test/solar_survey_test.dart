import 'package:flutter_test/flutter_test.dart';
import 'package:smart_solar_mobile/models/solar_survey.dart';
import 'package:smart_solar_mobile/models/user.dart';
import 'package:smart_solar_mobile/models/auth_response.dart';

void main() {
  group('SolarSurvey Model & Result Parsing Tests', () {
    test('SolarSurvey parses basic survey data and status', () {
      final json = {
        'id': 'survey-123',
        'monthlyKwh': 1200.0,
        'roofAreaSqm': 80.0,
        'gridType': 'SinglePhase',
        'propertyAddress': '45 Park Road, Colombo',
        'surveyStatus': 'AnalysisComplete',
        'workflows': [],
      };

      final survey = SolarSurvey.fromJson(json);

      expect(survey.id, 'survey-123');
      expect(survey.monthlyKwh, 1200.0);
      expect(survey.roofAreaSqm, 80.0);
      expect(survey.gridType, 'SinglePhase');
      expect(survey.propertyAddress, '45 Park Road, Colombo');
      expect(survey.surveyStatus, 'AnalysisComplete');
    });

    test('SolarSurvey parses AI sizing recommendation and validation results correctly', () {
      final json = {
        'id': 'survey-456',
        'monthlyKwh': 1200.0,
        'roofAreaSqm': 80.0,
        'gridType': 'SinglePhase',
        'propertyAddress': '123 Solar Blvd',
        'surveyStatus': 'AnalysisComplete',
        'workflows': [
          {
            'workflowId': 'wf-789',
            'status': 'Completed',
            'resultJson': '{"recommended_kw": 10.0, "estimated_panel_count": 25, "estimated_inverter_kw": 10.0, "reason": "Sizing complete"}',
            'validationJson': '{"valid": true, "checks": {"monthly_kwh_valid": true, "roof_area_valid": true}}',
            'errorMessage': null,
          }
        ],
      };

      final survey = SolarSurvey.fromJson(json);

      expect(survey.recommendedKw, 10.0);
      expect(survey.panelCount, 25);
      expect(survey.inverterKw, 10.0);
      expect(survey.isValid, true);
      expect(survey.errorMessage, null);
    });

    test('SolarSurvey handles workflow failure state and safe error message without crashing', () {
      final json = {
        'id': 'survey-789',
        'monthlyKwh': 500.0,
        'roofAreaSqm': 30.0,
        'gridType': 'SinglePhase',
        'propertyAddress': '789 Faulty Way',
        'surveyStatus': 'Failed',
        'workflows': [
          {
            'workflowId': 'wf-failed',
            'status': 'Failed',
            'resultJson': null,
            'validationJson': null,
            'errorMessage': 'Agentic AI service execution timeout',
          }
        ],
      };

      final survey = SolarSurvey.fromJson(json);

      expect(survey.surveyStatus, 'Failed');
      expect(survey.recommendedKw, null);
      expect(survey.panelCount, null);
      expect(survey.inverterKw, null);
      expect(survey.isValid, null);
      expect(survey.errorMessage, 'Agentic AI service execution timeout');
    });
  });

  group('Authentication State & User Role Tests', () {
    test('Homeowner user authentication payload deserializes correctly', () {
      final json = {
        'token': 'jwt.homeowner.token',
        'tokenType': 'Bearer',
        'expiresIn': 3600,
        'user': {
          'id': 'homeowner-id-1',
          'email': 'homeowner@smartsolar.local',
          'fullName': 'John Homeowner',
          'roles': ['HOMEOWNER'],
          'createdAt': '2026-09-08T00:00:00Z',
        },
      };

      final authRes = AuthResponse.fromJson(json);
      final user = User.fromJson(json['user'] as Map<String, dynamic>);
      expect(user.fullName, 'John Homeowner');
      expect(authRes.user.roles, contains('HOMEOWNER'));
      expect(authRes.token, 'jwt.homeowner.token');
    });
  });

  group('Survey Form Validation Logic', () {
    test('Validates positive monthly usage, roof area, and non-empty property address', () {
      double? usage = double.tryParse('1200');
      double? roof = double.tryParse('80');
      String address = '   123 Solar Street   ';

      expect(usage != null && usage > 0, true);
      expect(roof != null && roof > 0, true);
      expect(address.trim().isNotEmpty, true);

      // Invalid cases
      double? invalidUsage = double.tryParse('-10');
      double? invalidRoof = double.tryParse('0');
      String emptyAddress = '   ';

      expect(invalidUsage == null || invalidUsage <= 0, true);
      expect(invalidRoof == null || invalidRoof <= 0, true);
      expect(emptyAddress.trim().isEmpty, true);
    });
  });
}
