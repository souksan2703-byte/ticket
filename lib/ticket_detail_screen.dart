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
            ? (decoded['message']?.toString() ?? 'ยืนยันรับตั๋วไม่สำเร็จ')
            : 'ยืนยันรับตั๋วไม่สำเร็จ';
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
    // แสดงเฉพาะฟิลด์ที่มีประโยชน์กับพนักงานหน้างาน (ตัดฟิลด์ที่ไม่จำเป็นออก)
    final fields = <MapEntry<String, dynamic>>[
      MapEntry('ລະຫັດບັດ', data['code'] ?? '-'),
      MapEntry('ງານ', data['eventName'] ?? '-'),
      MapEntry('ເຈົ້າຂອງບັດ', data['owner'] ?? '-'),
    ];

    // มาถึงหน้านี้ได้แปลว่า check-ticket ตอบ result 'ok' แล้ว (ขายแล้ว ยังไม่รับ)
    // จึงแสดงปุ่มยืนยันรับตั๋วเสมอ
    const bool showReceiveButton = true;
    final String code = data['code']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('ລາຍລະອຽດບັດ')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: fields.length,
              itemBuilder: (context, index) {
                final key = fields[index].key;
                final String value = fields[index].value.toString();

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          '$key:',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 17),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (showReceiveButton)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 60,
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
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontSize: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black),
                        )
                      : const Text('ຮັບບັດ'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}