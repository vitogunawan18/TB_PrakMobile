import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import 'ticket_detail_page.dart';

class TicketsPage extends StatefulWidget {
  final ApiService apiService;

  const TicketsPage({super.key, required this.apiService});

  @override
  State<TicketsPage> createState() => TicketsPageState();
}

class TicketsPageState extends State<TicketsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _tickets = [];

  Future<void> refresh() => _loadTickets();

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tickets = await widget.apiService.fetchTickets();
      setState(() {
        _tickets = tickets;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tiket Saya'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTicketList(activeOnly: true),
            _buildTicketList(activeOnly: false),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList({required bool activeOnly}) {
    final filtered = _tickets.where((ticket) {
      final s = (ticket['status'] as String? ?? '').toLowerCase();
      final isActive = s.contains('active') || s.contains('success') || s.contains('paid');
      return activeOnly ? isActive : !isActive;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? ListView(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_errorMessage!),
                      ),
                    ),
                  ],
                )
              : filtered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Belum ada tiket.'),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final ticket = filtered[index] as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: (ticket['event']?['poster_url'] as String?) != null
                                ? SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: CachedNetworkImage(
                                      imageUrl: ticket['event']?['poster_url'] as String,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
                                    ),
                                  )
                                : null,
                            title: Text(ticket['ticket_code'] ?? 'Kode tiket tidak tersedia'),
                            subtitle: Text(ticket['event']?['title'] ?? 'Nama event tidak tersedia'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TicketDetailPage(apiService: widget.apiService, ticket: ticket),
                                ),
                              ).then((_) => _loadTickets());
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
