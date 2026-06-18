import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membatalkan: $e')));
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daftar Pesanan'),
          bottom: const TabBar(
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
                color: Colors.red.shade100,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                child: const Text('Anda sedang offline', textAlign: TextAlign.center),
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
              ? ListView(children: [Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))])
              : filtered.isEmpty
                  ? ListView(children: const [Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada pesanan.')))])
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, idx) {
                        if (idx >= filtered.length) {
                          return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                        }
                        final o = filtered[idx] as Map<String, dynamic>;
                        final status = o['status'] ?? '-';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text('Order ${o['order_code'] ?? o['id'] ?? '-'}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status: ${status.toUpperCase()}'),
                                if (o['total_amount'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text('Total: Rp ${o['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ],
                            ),
                            trailing: o['status'] == 'pending'
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => PaymentPage(apiService: widget.apiService, orderId: o['id'] as int),
                                            ),
                                          ).then((_) => _loadOrders(page: 1));
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                        child: const Text('Bayar'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () => _cancelOrder(o['id'] as int),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Batal'),
                                      ),
                                    ],
                                  )
                                : null,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailPage(apiService: widget.apiService, orderId: o['id'] as int),
                                ),
                              ).then((_) => _loadOrders(page: 1));
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
