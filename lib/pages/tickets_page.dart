import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
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
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Tiket Saya',
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
                        child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.textSecondary)),
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
                            child: Text('Belum ada tiket.', style: TextStyle(color: AppTheme.textSecondary)),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80), // extra padding to avoid floating bottom nav overlapping
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final ticket = filtered[index] as Map<String, dynamic>;
                        final event = ticket['event'] as Map<String, dynamic>? ?? {};
                        final posterUrl = event['poster_url'] as String?;
                        final ticketCode = ticket['ticket_code'] ?? 'TICKET';
                        final status = ticket['status'] ?? 'UNKNOWN';
                        final isUsed = status.toString().toLowerCase().contains('used') || status.toString().toLowerCase().contains('redeemed');
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TicketDetailPage(apiService: widget.apiService, ticket: ticket),
                              ),
                            ).then((_) => _loadTickets());
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: CustomPaint(
                              painter: TicketListStubPainter(
                                color: AppTheme.cardSurface.withOpacity(0.85),
                                borderColor: AppTheme.accentSecondary.withOpacity(0.15),
                              ),
                              child: Container(
                                height: 110,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    // 1. Poster Image (Square rounded)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 70,
                                        height: 70,
                                        child: posterUrl != null
                                            ? CachedNetworkImage(
                                                imageUrl: AppTheme.getDirectImageUrl(posterUrl),
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                errorWidget: (context, url, error) => CachedNetworkImage(
                                                   imageUrl: AppTheme.getEventPlaceholder(event['title'] as String?, event['category']?['name'] as String?),
                                                   fit: BoxFit.cover,
                                                   placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                   errorWidget: (context, url, err) => const Icon(Icons.image, color: AppTheme.textSecondary),
                                                 ),
                                              )
                                            : Container(color: AppTheme.bgPrimary, child: const Icon(Icons.image, color: AppTheme.textSecondary)),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    
                                    // 2. Ticket details (middle area)
                                    Expanded(
                                      flex: 12,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            event['title'] ?? 'Nama Event',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'KODE: $ticketCode',
                                            style: const TextStyle(color: AppTheme.accentPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isUsed ? AppTheme.statusExpired : AppTheme.accentPrimary).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              status.toString().toUpperCase(),
                                              style: TextStyle(
                                                color: isUsed ? AppTheme.statusExpired : AppTheme.accentPrimary,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Spacing for divider cutouts
                                    const Expanded(flex: 2, child: SizedBox()),
                                    
                                    // 3. Trailing Chevron / Action Area
                                    const Expanded(
                                      flex: 3,
                                      child: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

// Custom Painter for horizontal ticket stub in lists
class TicketListStubPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  TicketListStubPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path();
    double w = size.width;
    double h = size.height;
    double r = 16.0;
    double cutR = 8.0;

    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    
    // Vertical cutout on the right
    path.lineTo(w, h / 2 - cutR);
    path.arcToPoint(Offset(w, h / 2 + cutR), radius: Radius.circular(cutR), clockwise: false);
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    
    // Left cutout in alignment
    path.lineTo(0, h / 2 + cutR);
    path.arcToPoint(Offset(0, h / 2 - cutR), radius: Radius.circular(cutR), clockwise: false);
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // Dashed line
    final dashPaint = Paint()
      ..color = borderColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
      
    double dashWidth = 5;
    double dashSpace = 4;
    double dashY = 0;
    double targetX = w * 0.78; // vertical dash at 78%
    
    while (dashY < h) {
      canvas.drawLine(Offset(targetX, dashY), Offset(targetX, dashY + dashWidth), dashPaint);
      dashY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

