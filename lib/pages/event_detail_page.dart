import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
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

  String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (_) {
      return isoString;
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
        title: const Text('Detail Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      extendBodyBehindAppBar: true, // Let background poster overlap behind transparent appBar
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.textSecondary))))
              : _event == null
                  ? const Center(child: Text('Event tidak ditemukan', style: TextStyle(color: AppTheme.textSecondary)))
                  : Stack(
                      children: [
                        // 1. Poster Image with Scrim Fade Gradient Overlay
                        if ((_event!['poster_url'] as String?) != null)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 320,
                            child: ShaderMask(
                              shaderCallback: (rect) {
                                return const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black, Colors.transparent],
                                ).createShader(Rect.fromLTRB(0, 120, rect.width, rect.height));
                              },
                              blendMode: BlendMode.dstIn,
                              child: CachedNetworkImage(
                                imageUrl: AppTheme.getDirectImageUrl(_event!['poster_url'] as String?),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => CachedNetworkImage(
                                  imageUrl: AppTheme.getEventPlaceholder(_event!['title'] as String?, _event!['category']?['name'] as String?),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, err) => const Icon(Icons.image, size: 48, color: AppTheme.textSecondary),
                                ),
                              ),
                            ),
                          ),
                        
                        // 2. Scrollable sheet overlay
                        Positioned.fill(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(top: 240),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.bgPrimary,
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.cardSurface.withOpacity(0.95),
                                    AppTheme.bgPrimary,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(32),
                                  topRight: Radius.circular(32),
                                ),
                                border: Border.all(color: AppTheme.accentSecondary.withOpacity(0.12), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Event Title
                                  Text(
                                    _event!['title'] ?? 'Tidak ada judul',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Details Grid Info
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgPrimary.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, color: AppTheme.accentPrimary, size: 20),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                '${_event!['venue_name'] ?? 'Lokasi tidak tersedia'}, ${_event!['city'] ?? ''}',
                                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_month, color: AppTheme.accentPrimary, size: 20),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                _event!['event_at'] != null 
                                                    ? _formatDate(_event!['event_at'] as String)
                                                    : 'Tanggal tidak tersedia',
                                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // About Event Description
                                  const Text(
                                    'Tentang Event',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _event!['description'] ?? 'Tidak ada deskripsi.',
                                    style: const TextStyle(color: AppTheme.textSecondary, height: 1.5, fontSize: 14),
                                  ),
                                  const SizedBox(height: 28),

                                  // Ticket Types Section
                                  const Text(
                                    'Tipe Tiket',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 12),
                                  ...(_event!['ticket_types'] as List<dynamic>?)?.map((ticket) {
                                    final item = ticket as Map<String, dynamic>;
                                    final remaining = item['remaining_quantity'] ?? 0;
                                    final isLowStock = remaining < 10;
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      padding: const EdgeInsets.all(16),
                                      decoration: AppTheme.glassCardDecoration(),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['name'] ?? 'Tiket',
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Rp ${item['price'] ?? '-'}',
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.accentPrimary),
                                                ),
                                                const SizedBox(height: 10),
                                                // Status badge based on remaining quantity
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: (isLowStock ? AppTheme.statusExpired : AppTheme.accentPrimary).withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'Sisa Kuota: $remaining',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: isLowStock ? AppTheme.statusExpired : AppTheme.accentPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Buy ticket button
                                          Container(
                                            decoration: AppTheme.gradientButtonDecoration(),
                                            child: ElevatedButton(
                                              onPressed: remaining <= 0
                                                  ? null
                                                  : () {
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
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              ),
                                              child: Text(
                                                remaining <= 0 ? 'Habis' : 'Beli',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList() ?? [const Text('Tidak ada tipe tiket.', style: TextStyle(color: AppTheme.textSecondary))],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

