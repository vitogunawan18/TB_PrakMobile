import 'package:flutter/material.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/main_nav.dart';
import 'services/api_service.dart';
import 'services/auth_manager.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String tickets = '/tickets';
  static const String profile = '/profile';

  static PageRouteBuilder<T> _instantRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  static Route<dynamic>? onGenerateRoute(
    RouteSettings settings,
    ApiService api,
    AuthManager auth,
  ) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SplashPage(apiService: api, authManager: auth),
        );
      case login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LoginPage(apiService: api, authManager: auth),
        );
      case register:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RegisterPage(apiService: api, authManager: auth),
        );
      case home:
        return _instantRoute(
          MainNav(apiService: api, authManager: auth, initialIndex: 0),
          settings,
        );
      case orders:
        return _instantRoute(
          MainNav(apiService: api, authManager: auth, initialIndex: 1),
          settings,
        );
      case tickets:
        return _instantRoute(
          MainNav(apiService: api, authManager: auth, initialIndex: 2),
          settings,
        );
      case profile:
        return _instantRoute(
          MainNav(apiService: api, authManager: auth, initialIndex: 3),
          settings,
        );
      default:
        return null;
    }
  }
}
