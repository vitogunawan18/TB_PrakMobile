import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_nav.dart';

class PaymentPage extends StatefulWidget {
  final ApiService apiService;
  final int orderId;

  const PaymentPage({super.key, required this.apiService, required this.orderId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _method = 'bank_transfer';
  bool _isLoading = false;
  String? _error;
  int _secondsLeft = 300; // 5 minutes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
      });
      if (_secondsLeft <= 0) {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _pay() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await widget.apiService.payOrder(widget.orderId, _method);
      // assume success when no exception thrown
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Pembayaran Berhasil'),
          content: const Text('Tiket akan diaktifkan dan muncul di My Tickets.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => MainNav(
                      apiService: widget.apiService,
                      initialIndex: 2,
                    ),
                  ),
                  (route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')), 
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: ${widget.orderId}'),
            const SizedBox(height: 12),
            Text('Sisa waktu pembayaran: ${_formatTime(_secondsLeft)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Pilih metode pembayaran'),
            const SizedBox(height: 8),
            RadioListTile<String>(
              value: 'bank_transfer',
              groupValue: _method,
              title: const Text('Bank Transfer'),
              onChanged: (v) => setState(() => _method = v!),
            ),
            RadioListTile<String>(
              value: 'e_wallet',
              groupValue: _method,
              title: const Text('E-Wallet'),
              onChanged: (v) => setState(() => _method = v!),
            ),
            RadioListTile<String>(
              value: 'virtual_account',
              groupValue: _method,
              title: const Text('Virtual Account'),
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _secondsLeft <= 0 ? null : _pay,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Bayar (Simulasi)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
