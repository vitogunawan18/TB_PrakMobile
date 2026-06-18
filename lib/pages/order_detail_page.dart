import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'payment_page.dart';

class OrderDetailPage extends StatefulWidget {
  final ApiService apiService;
  final int orderId;

  const OrderDetailPage({super.key, required this.apiService, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _order;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _startPolling();
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      await _load(silent: true);
      if (_order != null && _order!['status'] != 'pending') {
        _poll?.cancel();
      }
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final res = await widget.apiService.fetchOrderDetail(widget.orderId);
      setState(() => _order = res['data'] as Map<String, dynamic>? ?? res as Map<String, dynamic>?);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (!silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel() async {
    try {
      await widget.apiService.cancelOrder(widget.orderId);
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal batalkan: $e')));
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order: ${_order?['order_code'] ?? widget.orderId}'),
                      const SizedBox(height: 8),
                      Text('Status: ${_order?['status'] ?? '-'}'),
                      const SizedBox(height: 12),
                      if (_order?['status'] == 'pending') ...[
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PaymentPage(apiService: widget.apiService, orderId: widget.orderId),
                                  ),
                                ).then((_) => _load());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Bayar Sekarang'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: _cancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Batalkan pesanan'),
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _load, child: const Text('Segarkan'))),
                    ],
                  ),
                ),
    );
  }
}
