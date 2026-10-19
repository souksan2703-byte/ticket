import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ticket/api_config.dart';
import 'ticket_detail_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool isScanning = true;

  Future<void> _sendTranidToAPI(String rawTranid) async {
    final tranid = ApiConfig.normalizeTranId(rawTranid);

    if (tranid.isEmpty) {
      _showResultDialog('⚠️ Error', 'ບໍ່ພົບລະຫັດບັດໃນ QR Code');
      return;
    }

    try {
      final response = await ApiConfig.postJson('check-ticket', {
        'code': tranid,
      });

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        _showResultDialog('⚠️ Error', 'Invalid response format.');
        return;
      }

      final result = decoded['result']?.toString();
      final ticket = decoded['ticket'];

      // ຖ້າຕົ໋ວຖືກຮັບໄປແລ້ວ ໃຫ້ສະແດງລາຍລະອຽດ
      // ຕົ໋ວຖືກຮັບໄປແລ້ວ: ສະແດງລາຍລະອຽດໃນ Dialog
      if (result == 'already_used' && ticket is Map) {
        if (!mounted) return;

        await _showAlreadyUsedDialog(Map<String, dynamic>.from(ticket));
        return;
      }

      // ຕົ໋ວຂາຍແລ້ວ ແຕ່ຍັງບໍ່ຮັບ
      if (result == 'ok' && ticket is Map) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    TicketDetailScreen(data: Map<String, dynamic>.from(ticket)),
          ),
        );
        return;
      }
      // ຂາຍແລ້ວ ຍັງບໍ່ຮັບຕົ໋ວ -> ໄປໜ້າລາຍລະອຽດໃຫ້ກົດຢືນຢັນຮັບຕົ໋ວຕໍ່
      if (result == 'ok' && ticket is Map) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    TicketDetailScreen(data: Map<String, dynamic>.from(ticket)),
          ),
        );
        return;
      }

      // invalid / not_sold / already_used / error -> ແຈ້ງເຕືອນແລ້ວກັບໜ້າທຳອິດ
      _showResultDialog(
        'ແຈ້ງເຕືອນ!!!',
        decoded['message']?.toString() ?? 'ບໍ່ສາມາດກວດສອບຂໍ້ມູນ',
      );
    } catch (e) {
      _showResultDialog('⚠️ Error', e.toString());
    }
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            content: Text(message),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _showAlreadyUsedDialog(Map<String, dynamic> ticket) async {
    String valueOf(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) {
        return 'ບໍ່ມີຂໍ້ມູນ';
      }
      return value.toString();
    }

    String formatDate(dynamic value) {
      if (value == null) return 'ບໍ່ມີຂໍ້ມູນ';

      try {
        final date = DateTime.parse(value.toString()).toLocal();
        String two(int n) => n.toString().padLeft(2, '0');

        return '${two(date.day)}/${two(date.month)}/${date.year} '
            '${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
      } catch (_) {
        return value.toString();
      }
    }

    Widget detail(String label, dynamic value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            SelectableText(
              valueOf(value),
              style: const TextStyle(
                color: Color(0xFF273451),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: Colors.red, size: 64),
                    const SizedBox(height: 12),
                    const Text(
                      'ຕົ໋ວຖືກຮັບໄປແລ້ວ!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    detail('ຊື່ງານ', ticket['eventName']),
                    detail('Ticket ID', ticket['tickid']),
                    detail('Ticket Code', ticket['code']),
                    detail('ຜູ້ຊື້ / ຜູ້ຮັບ', ticket['owner']),
                    detail(
                      'ລາຄາ',
                      ticket['price'] == null ? null : '${ticket['price']} LAK',
                    ),
                    detail(
                      'ສະຖານທີ່',
                      ticket['eventLocation'] ?? ticket['location'] ?? '-',
                    ),
                    detail('ວັນເວລາຂາຍຕົ໋ວ', formatDate(ticket['soldAt'])),
                    detail(
                      'ວັນເວລາຮັບຕົ໋ວ',
                      formatDate(
                        ticket['receivedAt'] ??
                            ticket['getTicket_date'] ??
                            ticket['getTicketDate'],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!isScanning) return;

    final barcode = capture.barcodes.first;
    if (barcode.rawValue != null) {
      isScanning = false;
      final tranid = barcode.rawValue!;
      cameraController.stop();
      _sendTranidToAPI(tranid);
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ສະແກນ QR Code')),
      body: MobileScanner(
        controller: cameraController,
        onDetect: _onBarcodeDetected,
      ),
    );
  }
}
