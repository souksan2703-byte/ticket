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

      if (result == 'ok' && ticket is Map) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TicketDetailScreen(
              data: Map<String, dynamic>.from(ticket),
            ),
          ),
        );
        return;
      }

      _showResultDialog(
        'message!!!',
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
      builder: (_) => AlertDialog(
        title: Text(title),
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