import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
      appBar: AppBar(title: const Text('Health Status')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _error != null
                ? Text('Error: $_error')
                : Text('Status: $_status'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _check,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
