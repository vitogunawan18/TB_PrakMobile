import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_manager.dart';
import 'login_page.dart';
import 'main_nav.dart';

class SplashPage extends StatefulWidget {
  final ApiService apiService;
  final AuthManager authManager;

  const SplashPage({super.key, required this.apiService, required this.authManager});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await widget.authManager.loadToken();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainNav(apiService: widget.apiService, authManager: widget.authManager),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LoginPage(apiService: widget.apiService, authManager: widget.authManager),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
