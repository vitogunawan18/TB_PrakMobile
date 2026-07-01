import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
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
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.accentPrimary.withOpacity(0.2))),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.accentPrimary),
              SizedBox(width: 8),
              Text('Sukses', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            'Simulasi transaksi berhasil! Tiket Anda telah diaktifkan dan dapat diakses melalui tab tiket.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
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
              child: const Text('OK', style: TextStyle(color: AppTheme.accentPrimary, fontWeight: FontWeight.bold)),
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

  Widget _buildMethodCard(String value, String title, IconData icon) {
    final isSelected = _method == value;
    return GestureDetector(
      onTap: () => setState(() => _method = value),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accentPrimary : AppTheme.accentSecondary.withOpacity(0.15),
            width: isSelected ? 2.0 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.accentPrimary : AppTheme.textSecondary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.accentPrimary, size: 22)
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.textSecondary.withOpacity(0.4), width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
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
        title: const Text('Pembayaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: #${widget.orderId}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            
            // Countdown Timer Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.statusExpired.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.statusExpired.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sisa Waktu Pembayaran',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _formatTime(_secondsLeft),
                    style: const TextStyle(
                      color: AppTheme.statusExpired,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            
            const Text(
              'Pilih Metode Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            
            _buildMethodCard('bank_transfer', 'Bank Transfer', Icons.account_balance_outlined),
            _buildMethodCard('e_wallet', 'E-Wallet (Dana/OVO/GoPay)', Icons.account_balance_wallet_outlined),
            _buildMethodCard('virtual_account', 'Virtual Account', Icons.credit_card_outlined),
            
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppTheme.statusExpired, fontSize: 13)),
            ],
            
            const Spacer(),
            
            // Confirm Pay Button
            Container(
              decoration: AppTheme.gradientButtonDecoration(),
              child: ElevatedButton(
                onPressed: _isLoading || _secondsLeft <= 0 ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      ) 
                    : const Text('Bayar Sekarang (Simulasi)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
