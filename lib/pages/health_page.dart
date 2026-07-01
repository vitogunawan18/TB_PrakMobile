import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HealthPage extends StatefulWidget {
  final ApiService apiService;

  const HealthPage({super.key, required this.apiService});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  bool _isLoading = true;
  String? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await widget.apiService.fetchHealth();
      setState(() {
        _status = res['status']?.toString() ?? 'OK';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Status Server', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'DIAGNOSTIK KONEKSI',
              style: TextStyle(color: AppTheme.accentPrimary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 16),
            
            // Terminal Console Container
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF070B14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EDUTICK TERMINAL DIAGNOSTIC v1.0.0',
                        style: TextStyle(color: Color(0xFF475569), fontFamily: 'Courier', fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        '----------------------------------',
                        style: TextStyle(color: Color(0xFF475569), fontFamily: 'Courier', fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '[INFO] Memulai diagnosa kesehatan server...',
                        style: TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 13),
                      ),
                      const Text(
                        '[TARGET] Host: http://35.255.129.123:8080/health',
                        style: TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      
                      if (_isLoading) ...[
                        const Text(
                          '[STATUS] Mengirim request ping...',
                          style: TextStyle(color: AppTheme.statusPending, fontFamily: 'Courier', fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPrimary)),
                        ),
                      ] else if (_error != null) ...[
                        Text(
                          '[STATUS] Request gagal!',
                          style: TextStyle(color: AppTheme.statusExpired, fontFamily: 'Courier', fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '[ERROR] Details: $_error',
                          style: TextStyle(color: AppTheme.statusExpired, fontFamily: 'Courier', fontSize: 13),
                        ),
                      ] else ...[
                        const Text(
                          '[STATUS] Request berhasil diterima.',
                          style: TextStyle(color: AppTheme.statusSuccess, fontFamily: 'Courier', fontSize: 13),
                        ),
                        Text(
                          '[PAYLOAD] Status: $_status',
                          style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'SYSTEM DIAGNOSTIC: PASSED ✓',
                          style: TextStyle(color: AppTheme.accentPrimary, fontFamily: 'Courier', fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80), // bottom margin
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentPrimary.withOpacity(0.25),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _check,
          backgroundColor: AppTheme.accentPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
      ),
    );
  }
}

