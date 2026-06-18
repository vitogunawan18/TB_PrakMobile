import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import 'checkout_page.dart';

class EventDetailPage extends StatefulWidget {
  final ApiService apiService;
  final int eventId;

  const EventDetailPage({super.key, required this.apiService, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _event;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await widget.apiService.fetchEventDetail(widget.eventId);
      setState(() {
        _event = detail['data'] as Map<String, dynamic>? ?? detail;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Event')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_errorMessage!)))
              : _event == null
                  ? const Center(child: Text('Event tidak ditemukan'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((_event!['poster_url'] as String?) != null) ...[
                            SizedBox(
                              height: 200,
                              child: CachedNetworkImage(
                                imageUrl: _event!['poster_url'] as String,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, size: 48),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            _event!['title'] ?? 'Tidak ada judul',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(_event!['venue_name'] ?? 'Lokasi tidak tersedia'),
                          const SizedBox(height: 4),
                          Text(_event!['city'] ?? ''),
                          const SizedBox(height: 12),
                          Text(_event!['description'] ?? 'Tidak ada deskripsi.'),
                          const SizedBox(height: 20),
                          const Text('Tipe tiket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ...(_event!['ticket_types'] as List<dynamic>?)?.map((ticket) {
                            final item = ticket as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(item['name'] ?? 'Tiket'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Rp ${item['price'] ?? '-'} / qty'),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sisa Kuota: ${item['remaining_quantity'] ?? 0} / ${item['quota'] ?? 0}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CheckoutPage(
                                          apiService: widget.apiService,
                                          event: _event!,
                                          ticketType: item,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Beli'),
                                ),
                              ),
                            );
                          }).toList() ?? [const Text('Tidak ada tipe tiket.')],
                        ],
                      ),
                    ),
    );
  }
}
