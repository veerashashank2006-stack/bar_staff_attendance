import 'package:flutter/material.dart';
import '../presentation/settings/settings.dart';
import '../presentation/notifications/notifications.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/leave_request/leave_request.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/dashboard/dashboard.dart';
import '../presentation/attendance_reports/attendance_reports.dart';
import '../presentation/qr_scanner/qr_scanner.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String splash = '/splash-screen';
  static const String leaveRequest = '/leave-request';
  static const String login = '/login-screen';
  static const String dashboard = '/dashboard';
  static const String attendanceReports = '/attendance-reports';
  static const String qrScanner = '/qr-scanner';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    settings: (context) => const Settings(),
    notifications: (context) => const Notifications(),
    splash: (context) => const SplashScreen(),
    leaveRequest: (context) => const LeaveRequest(),
    login: (context) => const LoginScreen(),
    dashboard: (context) => const Dashboard(),
    attendanceReports: (context) => const AttendanceReports(),
    qrScanner: (context) => const QrScanner(),
    // TODO: Add your other routes here
  };
}
