// ===== Router =====
import 'package:flutter/material.dart';

import '../main.dart';

class Routes {
  static const splash = '/';
  static const signIn = '/auth/sign-in';
  static const signUp = '/auth/sign-up';
  static const dashboard = '/dashboard';
  static const users = '/users';
  static const settings = '/settings';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    switch (s.name) {
      case Routes.splash:
        return _page(const SplashGate());
      case Routes.signIn:
        return _page(const SignInView());
      case Routes.signUp:
        return _page(const SignUpView());
      case Routes.users:
        return _page(const UsersView());
      case Routes.dashboard:
        return _page(const DashboardView());
      case Routes.settings:
        return _page(const SettingsView());
      default:
        return _page(
          Scaffold(
            body: Center(child: Text('Unknown route: ${s.name}')),
          ),
        );
    }
  }

  static MaterialPageRoute _page(Widget child) => MaterialPageRoute(builder: (_) => child);
}