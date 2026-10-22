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
        return '-';
      }
      return value.toString();
    }

    dynamic firstValue(List<String> keys) {
      for (final key in keys) {
        final value = ticket[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value;
        }
      }
      return null;
    }

    String formatDate(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) {
        return '-';
      }

      try {
        final date = DateTime.parse(value.toString()).toLocal();
        String two(int n) => n.toString().padLeft(2, '0');

        return '${two(date.day)}/${two(date.month)}/${date.year} '
            '${two(date.hour)}:${two(date.minute)}';
      } catch (_) {
        return value.toString();
      }
    }

    Widget detail(String label, dynamic value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: Text(
                valueOf(value),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF273451),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),

          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),

          contentPadding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.red,
                      size: 58,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ຕົ໋ວຖືກຮັບໄປແລ້ວ!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    valueOf(firstValue(['eventName', 'Title', 'title'])),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF273451),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  detail('Ticket ID', firstValue(['tickid', 'ticketId', 'id'])),
                  detail('Ticket Code', firstValue(['code', 'ticketCode'])),
                  detail(
                    'ຜູ້ຊື້ / ຜູ້ຮັບ',
                    firstValue(['owner', 'customerName', 'phone']),
                  ),
                  detail(
                    'ລາຄາ',
                    firstValue(['price', 'amount']) == null
                        ? '-'
                        : '${valueOf(firstValue(['price', 'amount']))} LAK',
                  ),
                  detail(
                    'ສະຖານທີ່',
                    firstValue(['eventLocation', 'location', 'Location']),
                  ),
                  detail(
                    'ວັນເວລາຂາຍຕົ໋ວ',
                    formatDate(firstValue(['soldAt', 'saleDate', 'createdAt'])),
                  ),
                  detail(
                    'ວັນເວລາຮັບຕົ໋ວ',
                    formatDate(
                      firstValue([
                        'receivedAt',
                        'getTicket_date',
                        'getTicketDate',
                      ]),
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
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    // ເປີດກ້ອງສະແກນຄືນ
    isScanning = true;
    await cameraController.start();
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
