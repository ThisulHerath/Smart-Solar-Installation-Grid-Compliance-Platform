import 'package:flutter/foundation.dart';

class AppConstants {
  // Configurable API base URL (ASP.NET Core REST gateway)
  // Flutter web runs in the host browser; Android Emulator uses 10.0.2.2.
  static String get defaultApiBaseUrl =>
      const String.fromEnvironment('API_BASE_URL', defaultValue: '') != ''
          ? const String.fromEnvironment('API_BASE_URL')
          : kIsWeb ? 'http://localhost:5116' : 'http://10.0.2.2:5116';
  
  static const String roleAdministrator = 'ADMINISTRATOR';
  static const String roleSeniorEngineer = 'SENIOR_ENGINEER';
  static const String roleFieldTechnician = 'FIELD_TECHNICIAN';
  static const String roleHomeowner = 'HOMEOWNER';
  static const String roleInventoryOfficer = 'INVENTORY_OFFICER';
}
