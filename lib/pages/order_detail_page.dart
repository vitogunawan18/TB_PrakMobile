import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal batalkan: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.statusExpired));
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.statusPending;
      case 'success':
      case 'completed':
        return AppTheme.statusSuccess;
      case 'cancelled':
      case 'expired':
      default:
        return AppTheme.statusExpired;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _order?['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Detail Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: AppTheme.textSecondary))))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Glassmorphic Digital Receipt Container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.cardSurface.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Code & Status Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('KODE PESANAN', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '#${_order?['order_code'] ?? widget.orderId}',
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.toString().toUpperCase(),
                                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Custom Dashed separator
                            CustomPaint(
                              size: const Size(double.infinity, 1.5),
                              painter: DashedLinePainter(color: Colors.white.withOpacity(0.1)),
                            ),
                            const SizedBox(height: 20),
                            
                            // Ticket Info Details
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Pembayaran', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                                Text(
                                  'Rp ${_order?['total_amount'] ?? '-'}',
                                  style: const TextStyle(color: AppTheme.accentPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Metode Bayar', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                                Text(
                                  (_order?['payment_method'] ?? 'Simulasi').toString().replaceAll('_', ' ').toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Dibuat Pada', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                                Text(
                                  _order?['created_at'] != null 
                                      ? _order!['created_at'].toString().split('T')[0]
                                      : '-',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Pending Status Actions
                      if (_order?['status'] == 'pending') ...[
                        Row(
                          children: [
                            // Pay Now button (Gradient)
                            Expanded(
                              child: Container(
                                decoration: AppTheme.gradientButtonDecoration(),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PaymentPage(apiService: widget.apiService, orderId: widget.orderId),
                                      ),
                                    ).then((_) => _load());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Cancel button (Red outline)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _cancel,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.statusExpired,
                                  side: const BorderSide(color: AppTheme.statusExpired, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Batalkan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      const Spacer(),
                      
                      // Refresh button at the bottom
                      OutlinedButton(
                        onPressed: () => _load(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accentPrimary,
                          side: const BorderSide(color: AppTheme.accentPrimary, width: 1.2),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh, size: 18),
                            SizedBox(width: 8),
                            Text('Segarkan Detail', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// Dash line painter
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    double dashWidth = 6;
    double dashSpace = 4;
    double startX = 0;
    
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

