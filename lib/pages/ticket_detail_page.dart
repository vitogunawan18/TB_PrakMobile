import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';

class TicketDetailPage extends StatelessWidget {
  final ApiService apiService;
  final Map<String, dynamic> ticket;
  TicketDetailPage({super.key, required this.apiService, required this.ticket}) : _qrKey = GlobalKey();

  final GlobalKey _qrKey;

  @override
  Widget build(BuildContext context) {
    final event = ticket['event'] as Map<String, dynamic>?;
    final qrValue = ticket['qr_code_value'] as String? ?? ticket['ticket_code'] as String? ?? '';
    final holderName = ticket['holder_name'] as String? ?? ticket['user']?['name'] as String? ?? '-';
    final status = ticket['status'] as String? ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tiket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (event != null && (event['poster_url'] as String?) != null) ...[
              SizedBox(
                height: 180,
                child: CachedNetworkImage(
                  imageUrl: event['poster_url'] as String,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, size: 48),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              event?['title'] ?? ticket['ticket_code'] ?? 'Tiket',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(holderName, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Chip(
              label: Text(status.toUpperCase()),
              backgroundColor: _statusColor(status),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  RepaintBoundary(
                    key: _qrKey,
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: QrImageView(
                        data: qrValue,
                        size: 240,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText('Kode: ${ticket['ticket_code'] ?? '-'}'),
                  const SizedBox(height: 8),
                  Text('Tipe: ${ticket['ticket_type_name'] ?? '-'}'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal bagikan: $e')));
                }
              },
              icon: const Icon(Icons.share),
              label: const Text('Bagikan / Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('active') || s.contains('success') || s.contains('paid')) return Colors.green.shade600;
    if (s.contains('pending')) return Colors.orange.shade600;
    if (s.contains('cancel') || s.contains('expired') || s.contains('batal')) return Colors.red.shade600;
    return Colors.grey.shade400;
  }
}
