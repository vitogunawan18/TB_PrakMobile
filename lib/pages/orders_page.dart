import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'order_detail_page.dart';
import 'payment_page.dart';

class OrdersPage extends StatefulWidget {
  final ApiService apiService;

  const OrdersPage({super.key, required this.apiService});

  @override
  State<OrdersPage> createState() => OrdersPageState();
}

class OrdersPageState extends State<OrdersPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _orders = [];
  bool _online = true;
  late final Stream<ConnectivityResult> _connStream;

  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  Future<void> refresh() => _loadOrders(page: 1);

  @override
  void initState() {
    super.initState();
    _connStream = Connectivity().onConnectivityChanged;
    _connStream.listen((event) {
      setState(() {
        _online = event != ConnectivityResult.none;
      });
    });
    _scrollController.addListener(_onScroll);
    _loadOrders();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore) return;
    _page++;
    await _loadOrders(page: _page);
  }

  Future<void> _loadOrders({int page = 1}) async {
    if (page == 1) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }
    try {
      final orders = await widget.apiService.fetchOrders(page: page, perPage: 10);
      setState(() {
        if (page == 1) {
          _orders = orders;
          _page = 1;
        } else {
          _orders.addAll(orders);
        }
        _hasMore = orders.length >= 10;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _cancelOrder(int id) async {
    try {
      await widget.apiService.cancelOrder(id);
      await _loadOrders(page: 1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membatalkan: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.statusExpired));
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Daftar Pesanan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: AppTheme.accentPrimary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelColor: AppTheme.textSecondary,
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Selesai / Batal'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (!_online)
              Container(
                color: AppTheme.statusExpired.withOpacity(0.2),
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                child: const Text('Anda sedang offline', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOrderList(pendingOnly: true),
                  _buildOrderList(pendingOnly: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList({required bool pendingOnly}) {
    final filtered = _orders.where((o) {
      final isPending = o['status'] == 'pending';
      return pendingOnly ? isPending : !isPending;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        _page = 1;
        _hasMore = true;
        await _loadOrders(page: 1);
      },
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(children: [Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: AppTheme.textSecondary))))])
              : filtered.isEmpty
                  ? ListView(children: const [Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada pesanan.', style: TextStyle(color: AppTheme.textSecondary))))])
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80), // extra padding at bottom to clear floating bottom bar
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, idx) {
                        if (idx >= filtered.length) {
                          return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                        }
                        final o = filtered[idx] as Map<String, dynamic>;
                        final status = o['status'] ?? '-';
                        final statusColor = _getStatusColor(status);
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardSurface.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: statusColor, width: 4.5),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Order #${o['order_code'] ?? o['id'] ?? '-'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        status.toString().toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    if (o['total_amount'] != null) ...[
                                      Text(
                                        'Total: Rp ${o['total_amount']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.accentPrimary,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                    if (o['status'] == 'pending') ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          // Action button Bayar (Gradient)
                                          Container(
                                            decoration: AppTheme.gradientButtonDecoration(),
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => PaymentPage(apiService: widget.apiService, orderId: o['id'] as int),
                                                  ),
                                                ).then((_) => _loadOrders(page: 1));
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              child: const Text('Bayar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Action button Batal (Red outline)
                                          OutlinedButton(
                                            onPressed: () => _cancelOrder(o['id'] as int),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppTheme.statusExpired,
                                              side: const BorderSide(color: AppTheme.statusExpired, width: 1.2),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          ),
                                        ],
                                      ),
                                    ]
                                  ],
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => OrderDetailPage(apiService: widget.apiService, orderId: o['id'] as int),
                                    ),
                                  ).then((_) => _loadOrders(page: 1));
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
