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

  Future<void> _receiveTicket(String tranid) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiConfig.postJson('Get_Ticket', {
        'tranid': tranid,
      });
      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final fields = data.entries.toList();

    final bool showReceiveButton =
        data['ສະຖານະບັດ'] == true && data['ສະຖານະການຮັບບັດ'] == false;
    final String tranid = data['ລະຫັດບັດ']?.toString() ?? '';

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
                dynamic value = fields[index].value;

                if (key == 'ສະຖານະບັດ') {
                  value = value == true ? 'ຊື້ແລ້ວ' : 'ຍັງບໍ່ຊື້';
                } else if (key == 'ສະຖານະການຮັບບັດ') {
                  value = value == true ? 'ຮັບບັດແລ້ວ' : 'ລໍຖ້າການຮັບບັດ';
                }

                value = value.toString();

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
                                    _receiveTicket(tranid);
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
