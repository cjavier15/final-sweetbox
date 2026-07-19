import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/pos_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/branch_manager_screen.dart';
import 'screens/enterprise_dashboard_screen.dart';
import 'screens/user_management_screen.dart'; // New Import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SweetBoxApp());
}

class SweetBoxApp extends StatelessWidget {
  const SweetBoxApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sweet Box',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/otp': (context) => const OtpScreen(),
        '/pos': (context) => const PosScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/branch-manager': (context) => const BranchManagerScreen(),
        '/enterprise': (context) => const EnterpriseDashboardScreen(),
        '/admin': (context) => const UserManagementScreen(), // New Route
      },
    );
  }
}
