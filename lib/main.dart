import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ticket/api_config.dart';
import 'package:ticket/logo_page.dart';
import 'qr_scanner_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Scanner App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? scannedResult;
  Uint8List? _logoBytes;
  bool _isLoadingLogo = false;
  String? _logoError;

  Future<void> _navigateToScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );

    if (result != null) {
      setState(() {
        scannedResult = result;
      });
    }
  }

  Future<void> _fetchLogo() async {
    setState(() {
      _isLoadingLogo = true;
      _logoError = null;
      _logoBytes = null;
    });

    try {
      final res = await ApiConfig.postEmpty('Get_Logo').timeout(
        const Duration(seconds: 20),
      );

      if (res.statusCode == 200) {
        setState(() {
          _logoBytes = res.bodyBytes;
        });
      } else {
        setState(() {
          _logoError =
              'Request failed (HTTP ${res.statusCode}). Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _logoError = 'Error: $e\nURL: ${ApiConfig.url('Get_Logo')}';
      });
    } finally {
      setState(() {
        _isLoadingLogo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('ໜ້າຫຼັກ')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TicketPage()),
                );
              },
              icon: const Icon(Icons.list_alt, color: Colors.white),
              label: const Text(
                'ລູກຄ້າທີຍັງບໍ່ຮັບບັດ',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD11C21),
                elevation: 2,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _navigateToScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  style: ElevatedButton.styleFrom(
                    elevation: 1.5,
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: const Text('ສະແກນ QR'),
                ),
              ),

              const SizedBox(height: 24),
              if (_isLoadingLogo) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text('Loading...'),
              ] else if (_logoError != null) ...[
                Text(
                  _logoError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFD11C21)),
                ),
              ] else if (_logoBytes != null) ...[
                const Text(
                  'From API:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _logoBytes!,
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
              ] else ...[
              ],

              const SizedBox(height: 32),

              if (scannedResult != null) ...[
                const Text(
                  'Scan Result:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText(scannedResult!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
