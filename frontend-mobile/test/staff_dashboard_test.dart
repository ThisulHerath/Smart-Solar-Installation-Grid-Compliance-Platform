import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_solar_mobile/services/api_service.dart';
import 'package:smart_solar_mobile/theme/solar_theme.dart';
import 'package:smart_solar_mobile/utils/constants.dart';
import 'package:smart_solar_mobile/widgets/staff_dashboard.dart';

class DashboardApi extends ApiService {
  bool fail = false;
  int reportCalls = 0;
  int jobCalls = 0;
  @override
  Future<dynamic> get(String endpoint, {bool requiresAuth = true}) async {
    expect(endpoint, '/api/reports/overview');
    reportCalls++;
    if (fail) throw Exception('offline');
    return {
      'surveyCount': 14,
      'pendingApprovals': 3,
      'approvedProposals': 7,
      'lowStockItems': 2
    };
  }

  @override
  Future<List<dynamic>> getTechnicianJobs({String? status}) async {
    jobCalls++;
    return [
      {'status': 'Assigned'},
      {'status': 'InProgress'},
      {'status': 'ComplianceComplete'}
    ];
  }
}

Future<void> mountDashboard(WidgetTester tester, String role, DashboardApi api,
    {double width = 390, double scale = 1}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
      theme: buildSolarTheme(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: Scaffold(
          body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: StaffDashboard(
                  roles: [role], name: 'Kamal Perera', api: api)))));
  await tester.pumpAndSettle();
}

void main() {
  for (final role in [
    AppConstants.roleAdministrator,
    AppConstants.roleSeniorEngineer,
    AppConstants.roleInventoryOfficer
  ]) {
    testWidgets('$role shows real report counts and fits a narrow phone',
        (tester) async {
      final api = DashboardApi();
      await mountDashboard(tester, role, api, width: 320, scale: 1.4);
      expect(api.reportCalls, 1);
      expect(api.jobCalls, 0);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('7 approved · 3 awaiting approval'), findsOneWidget);
      expect(find.text('4.82'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'technician uses assigned jobs without the staff reporting endpoint',
      (tester) async {
    final api = DashboardApi();
    await mountDashboard(tester, AppConstants.roleFieldTechnician, api);
    expect(api.jobCalls, 1);
    expect(api.reportCalls, 0);
    expect(find.text('1 of 3 jobs have completed compliance.'), findsOneWidget);
    expect(find.text('FIELD WORKSPACE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'failed overview can be retried without displaying invented totals',
      (tester) async {
    final api = DashboardApi()..fail = true;
    await mountDashboard(tester, AppConstants.roleAdministrator, api);
    expect(find.text('Overview unavailable'), findsOneWidget);
    expect(find.text('14'), findsNothing);
    api.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Overview unavailable'), findsNothing);
    expect(find.text('14'), findsOneWidget);
    expect(api.reportCalls, 2);
    expect(tester.takeException(), isNull);
  });
}
