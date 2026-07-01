import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'payment_page.dart';

class CheckoutPage extends StatefulWidget {
  final ApiService apiService;
  final Map<String, dynamic> event;
  final Map<String, dynamic> ticketType;

  const CheckoutPage({
    super.key,
    required this.apiService,
    required this.event,
    required this.ticketType,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _quantity = 1;
  bool _isLoading = false;
  String? _error;

  double get _price => (widget.ticketType['price'] as num?)?.toDouble() ?? 0.0;
  double get _totalPrice => _price * _quantity;

  Future<void> _checkout() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ticketTypeId = widget.ticketType['id'] as int;
      final response = await widget.apiService.createOrder(ticketTypeId, _quantity);
      final order = response['data'] as Map<String, dynamic>? ?? response;
      final orderId = order['id'] as int? ?? order['order_id'] as int?;
      
      if (orderId == null) {
        throw Exception('Gagal membuat pesanan: ID pesanan tidak ditemukan');
      }

      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentPage(apiService: widget.apiService, orderId: orderId),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
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
    final posterUrl = widget.event['poster_url'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Checkout Tiket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Poster
                  if (posterUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: AppTheme.getDirectImageUrl(posterUrl),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => CachedNetworkImage(
                            imageUrl: AppTheme.getEventPlaceholder(widget.event['title'] as String?, widget.event['category']?['name'] as String?),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, err) => const Icon(Icons.image, size: 48, color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Event Title
                  Text(
                    widget.event['title'] ?? 'Nama Event',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  
                  // Location Row
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppTheme.accentPrimary),
                      const SizedBox(width: 6),
                      Text(
                        widget.event['city'] ?? 'Kota tidak tersedia',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const Divider(height: 36, color: Colors.white10),
                  
                  const Text(
                    'Detail Tiket',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  
                  // Ticket Stub Design Card using Custom Paint
                  CustomPaint(
                    painter: TicketStubPainter(
                      color: AppTheme.cardSurface.withOpacity(0.85),
                      borderColor: AppTheme.accentSecondary.withOpacity(0.15),
                    ),
                    child: Container(
                      height: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          // Left side: Ticket Details
                          Expanded(
                            flex: 13,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.ticketType['name'] ?? 'Tipe Tiket',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Rp $_price / qty',
                                  style: const TextStyle(color: AppTheme.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          
                          // Spacing for vertical dash separator
                          const Expanded(flex: 2, child: SizedBox()),
                          
                          // Right side: Quantity Editor
                          Expanded(
                            flex: 7,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Minus Button
                                InkWell(
                                  onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _quantity > 1 ? AppTheme.accentPrimary : Colors.white12,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      size: 14,
                                      color: _quantity > 1 ? AppTheme.accentPrimary : Colors.white12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '$_quantity',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                // Plus Button
                                InkWell(
                                  onTap: _quantity < 10 ? () => setState(() => _quantity++) : null,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _quantity < 10 ? AppTheme.accentPrimary : Colors.white12,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 14,
                                      color: _quantity < 10 ? AppTheme.accentPrimary : Colors.white12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.statusExpired, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Total Pembayaran Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Rp $_totalPrice',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Confirm Order Button
                  Container(
                    decoration: AppTheme.gradientButtonDecoration(),
                    child: ElevatedButton(
                      onPressed: _checkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Pesan Tiket Sekarang',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Custom Painter for ticket stub aesthetics
class TicketStubPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  TicketStubPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    double w = size.width;
    double h = size.height;
    double r = 16.0; // corner radius
    double cutR = 8.0; // side cutouts radius

    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    
    // Right cutout in the middle of vertical edge
    path.lineTo(w, h / 2 - cutR);
    path.arcToPoint(Offset(w, h / 2 + cutR), radius: Radius.circular(cutR), clockwise: false);
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    
    // Left cutout in the middle of vertical edge
    path.lineTo(0, h / 2 + cutR);
    path.arcToPoint(Offset(0, h / 2 - cutR), radius: Radius.circular(cutR), clockwise: false);
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // Draw dashed separator line vertically in alignment with cutouts
    final dashPaint = Paint()
      ..color = borderColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    double dashWidth = 5;
    double dashSpace = 4;
    double dashY = 0;
    // Align with separator ratio: 65% width
    double targetX = w * 0.65;
    
    while (dashY < h) {
      canvas.drawLine(Offset(targetX, dashY), Offset(targetX, dashY + dashWidth), dashPaint);
      dashY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

