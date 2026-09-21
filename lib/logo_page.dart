import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ticket/api_config.dart';

import 'ticket_not_page.dart';

class TicketPage extends StatefulWidget {
  const TicketPage({super.key});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  bool _isLoading = true;
  String? _error;
  List<_TicketItem> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _items = [];
    });

    try {
      final res = await ApiConfig.postEmpty('Get_Logo').timeout(
        const Duration(seconds: 20),
      );

      if (res.statusCode != 200) {
        setState(() {
          _error = 'Request failed (HTTP ${res.statusCode}).';
        });
        return;
      }

      final body = jsonDecode(res.body);
      if (body is! Map || body['status'] != true || body['data'] is! List) {
        setState(() {
          _error = 'Invalid response format.';
        });
        return;
      }

      final List data = body['data'];
      final items = <_TicketItem>[];
      for (final e in data) {
        if (e is Map) {
          final desc = (e['Description'] ?? e['type'] ?? '')
              .toString()
              .trim();
          final id = e['tickid'];
          items.add(
            _TicketItem(
              tickid: id is int ? id : int.tryParse('$id'),
              description: desc,
            ),
          );
        }
      }

      if (items.isEmpty) {
        setState(() => _error = 'No tickets found.');
        return;
      }

      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = 'Error: $e\nURL: ${ApiConfig.url('Get_Licket_Not')}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tickets')),
      body: RefreshIndicator(
        onRefresh: _fetchTickets,
        child:
            _isLoading
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Loading...'),
                    ],
                  ),
                )
                : _error != null
                ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _fetchTickets,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                )
                : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: const Icon(Icons.confirmation_number),
                        title: Text(
                          item.description?.isNotEmpty == true
                              ? item.description!
                              : 'No description',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle:
                            item.tickid != null
                                ? Text('Ticket ID: ${item.tickid}')
                                : const Text('Ticket ID: -'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          if (item.tickid != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => TicketNotPage(tickid: item.tickid!),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fetchTickets,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }
}

class _TicketItem {
  final int? tickid;
  final String? description;
  _TicketItem({this.tickid, this.description});
}
