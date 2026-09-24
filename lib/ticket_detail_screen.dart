import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ticket/api_config.dart';
import 'package:ticket/successScreen.dart';

class TicketDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const TicketDetailScreen({super.key, required this.data});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  bool _isLoading = false;

  Future<void> _receiveTicket(String code) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiConfig.postJson('receive-ticket', {
        'code': code,
      });
      final decoded = jsonDecode(response.body);
      final result = decoded is Map ? decoded['result']?.toString() : null;

      if (result == 'success') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
        );
      } else {
        final message = decoded is Map
            ? (decoded['message']?.toString() ?? 'ຢືນຢັນຮັບຕົ໋ວບໍ່ສຳເລັດ')
            : 'ຢືນຢັນຮັບຕົ໋ວບໍ່ສຳເລັດ';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error: $e')),
      );
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
    final data = widget.data;
    // ສະແດງສະເພາະຟິວທີ່ມີປະໂຫຍດກັບພະນັກງານໜ້າງານ (ຕັດຟິວທີ່ບໍ່ຈຳເປັນອອກ)
    final fields = <MapEntry<String, dynamic>>[
      MapEntry('ລະຫັດບັດ', data['code'] ?? '-'),
      MapEntry('ງານ', data['eventName'] ?? '-'),
      MapEntry('ວັນທີ/ເວລາ', data['eventDate'] ?? '-'),
      MapEntry('ສະຖານທີ່', data['eventLocation'] ?? '-'),
      MapEntry('ເຈົ້າຂອງບັດ', data['owner'] ?? '-'),
    ];

    // ມາຮອດໜ້ານີ້ໄດ້ໝາຍວ່າ check-ticket ຕອບ result 'ok' ແລ້ວ (ຂາຍແລ້ວ ຍັງບໍ່ຮັບ)
    // ຈຶ່ງສະແດງປຸ່ມຢືນຢັນຮັບຕົ໋ວສະເໝີ
    const bool showReceiveButton = true;
    final String code = data['code']?.toString() ?? '';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD11C21), Color(0xFF0D47A1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ແຖບເທິງ: ປຸ່ມກັບຄືນ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Text(
                      'ລາຍລະອຽດບັດ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.confirmation_num_outlined,
                                color: Color(0xFF2E7D32),
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'ພົບຂໍ້ມູນບັດ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            ...fields.map((entry) {
                              final value = entry.value.toString();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Flexible(
                                      child: Text(
                                        value,
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showReceiveButton)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('ຢືນຢັນ'),
                                  content:
                                      const Text('ທ່ານຕ້ອງການຮັບບັດນີ້ແທ້ບໍ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('ຍົກເລີກ'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _receiveTicket(code);
                                      },
                                      child: const Text('ຢືນຢັນ'),
                                    ),
                                  ],
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD11C21),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text('ຮັບບັດ'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}