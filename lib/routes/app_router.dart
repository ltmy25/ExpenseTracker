import 'package:flutter/material.dart';

import 'package:expensetracker/presentation/screens/auth/auth_gate.dart';
import 'package:expensetracker/presentation/screens/auth/login_screen.dart';
import 'package:expensetracker/presentation/screens/auth/register_screen.dart';
import 'package:expensetracker/presentation/screens/home/contact_us_screen.dart';
import 'package:expensetracker/presentation/screens/home/home_screen.dart';
import 'package:expensetracker/presentation/screens/home/profile_settings_screen.dart';
import 'package:expensetracker/routes/app_routes.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.profileSettings:
        return MaterialPageRoute(builder: (_) => const ProfileSettingsScreen());
      case AppRoutes.contactUs:
        return MaterialPageRoute(builder: (_) => const ContactUsScreen());
      case AppRoutes.authGate:
      default:
        return MaterialPageRoute(builder: (_) => const AuthGate());
    }
  }
}
