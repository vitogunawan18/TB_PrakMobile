import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'routes.dart';
import 'services/api_service.dart';
import 'services/auth_manager.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ApiService _api;
  late final AuthManager _auth;

  @override
  void initState() {
    super.initState();
    _api = ApiService(null, () async {
      await _auth.clearToken();
      navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.splash, (route) => false);
    });
    _auth = AuthManager(_api);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Educational Ticketing',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) => AppRoutes.onGenerateRoute(settings, _api, _auth),
    );
  }
}
