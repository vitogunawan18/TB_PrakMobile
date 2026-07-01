import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class TicketDetailPage extends StatelessWidget {
  final ApiService apiService;
  final Map<String, dynamic> ticket;
  TicketDetailPage({super.key, required this.apiService, required this.ticket}) : _qrKey = GlobalKey();

  final GlobalKey _qrKey;

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('active') || s.contains('success') || s.contains('paid')) return AppTheme.statusSuccess;
    if (s.contains('pending')) return AppTheme.statusPending;
    if (s.contains('cancel') || s.contains('expired') || s.contains('batal') || s.contains('used') || s.contains('redeemed')) return AppTheme.statusExpired;
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final event = ticket['event'] as Map<String, dynamic>?;
    final qrValue = ticket['qr_code_value'] as String? ?? ticket['ticket_code'] as String? ?? '';
    final holderName = ticket['holder_name'] as String? ?? ticket['user']?['name'] as String? ?? '-';
    final status = ticket['status'] as String? ?? '-';
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
        title: const Text('Detail Tiket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Vertical Ticket Stub Card
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardSurface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.accentSecondary.withOpacity(0.15), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Poster Image (rounded top corners)
                  if (event != null && (event['poster_url'] as String?) != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: AppTheme.getDirectImageUrl(event['poster_url'] as String?),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => CachedNetworkImage(
                            imageUrl: AppTheme.getEventPlaceholder(event['title'] as String?, event['category']?['name'] as String?),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, err) => const Icon(Icons.image, size: 48, color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  
                  // 2. Ticket Details Body
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          event?['title'] ?? ticket['ticket_code'] ?? 'Tiket',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Holder: $holderName',
                          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Dashed separator line
                        CustomPaint(
                          size: const Size(double.infinity, 1.5),
                          painter: DashedLinePainter(color: Colors.white.withOpacity(0.1)),
                        ),
                        const SizedBox(height: 24),
                        
                        // 3. QR Code Area (RepaintBoundary must enclose the QR code for capturing image)
                        RepaintBoundary(
                          key: _qrKey,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: 180,
                              height: 180,
                              child: QrImageView(
                                data: qrValue,
                                size: 180,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        SelectableText(
                          'Kode: ${ticket['ticket_code'] ?? '-'}',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tipe: ${ticket['ticket_type_name'] ?? '-'}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Share / Save Button
            Container(
              decoration: AppTheme.gradientButtonDecoration(),
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                    if (boundary == null) throw Exception('QR capture failed');
                    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                    final pngBytes = byteData!.buffer.asUint8List();
                    final dir = await getTemporaryDirectory();
                    final file = File('${dir.path}/ticket_${ticket['id'] ?? DateTime.now().millisecondsSinceEpoch}.png');
                    await file.writeAsBytes(pngBytes);
                    await Share.shareXFiles([XFile(file.path)], text: 'Tiket ${ticket['ticket_code'] ?? ''}');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal bagikan: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.statusExpired));
                  }
                },
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text('Bagikan / Simpan Tiket', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
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

