import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ticket/api_config.dart';

class _BuyerItem {
  final String buyer;
  final String status;
  _BuyerItem({required this.buyer, required this.status});
}

class TicketNotPage extends StatefulWidget {
  final int tickid;
  final String? eventTitle;
  const TicketNotPage({super.key, required this.tickid, this.eventTitle});

  @override
  State<TicketNotPage> createState() => _TicketNotPageState();
}

class _TicketNotPageState extends State<TicketNotPage> {
  bool _isLoadingNotReceived = true;
  bool _isLoadingReceived = true;
  String? _notReceivedError;
  String? _receivedError;
  List<_BuyerItem> _notReceivedItems = [];
  List<_BuyerItem> _receivedItems = [];

  @override
  void initState() {
    super.initState();
    // ดึงข้อมูลทั้ง 2 แท็บพร้อมกันตั้งแต่เปิดหน้ามา ไม่ต้องรอสลับแท็บถึงจะโหลด
    _fetchNotReceived();
    _fetchReceived();
  }

  Future<List<_BuyerItem>?> _fetchList(String endpoint, void Function(String) onError) async {
    try {
      final uri = ApiConfig.url(
        endpoint,
      ).replace(queryParameters: {'tickid': widget.tickid.toString()});

      final res = await http.get(uri).timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        onError('Request failed (HTTP ${res.statusCode}). Please try again.');
        return null;
      }

      final body = jsonDecode(res.body);
      if (body is! Map || body['status'] != true || body['data'] is! List) {
        onError('Invalid response format.');
        return null;
      }

      final List data = body['data'];
      final items = <_BuyerItem>[];
      for (final e in data) {
        if (e is Map) {
          final buyer  = (e['owner'] ?? '').toString().trim();
          final status = (e['status'] ?? '').toString().trim();
          if (buyer.isNotEmpty || status.isNotEmpty) {
            items.add(_BuyerItem(buyer: buyer, status: status));
          }
        }
      }
      return items;
    } catch (e) {
      onError('Error: $e');
      return null;
    }
  }

  Future<void> _fetchNotReceived() async {
    setState(() {
      _isLoadingNotReceived = true;
      _notReceivedError = null;
    });
    final items = await _fetchList(
      'tickets-not-received',
      (msg) => _notReceivedError = msg,
    );
    if (!mounted) return;
    setState(() {
      _isLoadingNotReceived = false;
      if (items != null) {
        _notReceivedItems = items;
        if (items.isEmpty) _notReceivedError = 'No data found.';
      }
    });
  }

  Future<void> _fetchReceived() async {
    setState(() {
      _isLoadingReceived = true;
      _receivedError = null;
    });
    final items = await _fetchList(
      'tickets-received',
      (msg) => _receivedError = msg,
    );
    if (!mounted) return;
    setState(() {
      _isLoadingReceived = false;
      if (items != null) {
        _receivedItems = items;
        if (items.isEmpty) _receivedError = 'No data found.';
      }
    });
  }

  String _tabLabel(String base, bool isLoading, List<_BuyerItem> items) {
    if (isLoading) return base;
    return '$base (${items.length})';
  }

  Widget _buildList(
    bool isLoading,
    String? error,
    List<_BuyerItem> items,
    Future<void> Function() onRefresh,
  ) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: isLoading
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
          : error != null
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(error, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final it = items[index];
                    return Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(
                          it.buyer.isNotEmpty ? it.buyer : 'Unknown buyer',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        subtitle: Text(it.status.isNotEmpty ? it.status : 'No status'),
                      ),
                    );
                  },
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            (widget.eventTitle != null && widget.eventTitle!.isNotEmpty)
                ? widget.eventTitle!
                : 'Ticket ${widget.tickid}',
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: _tabLabel('ຍັງບໍ່ຮັບບັດ', _isLoadingNotReceived, _notReceivedItems)),
              Tab(text: _tabLabel('ຮັບບັດແລ້ວ', _isLoadingReceived, _receivedItems)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(_isLoadingNotReceived, _notReceivedError, _notReceivedItems, _fetchNotReceived),
            _buildList(_isLoadingReceived, _receivedError, _receivedItems, _fetchReceived),
          ],
        ),
      ),
    );
  }
}