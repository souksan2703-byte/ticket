import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ticket/api_config.dart';

class TicketNotPage extends StatelessWidget {
  final int tickid;
  const TicketNotPage({super.key, required this.tickid});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Ticket $tickid'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'ຍັງບໍ່ຮັບບັດ'),
              Tab(text: 'ຮັບບັດແລ້ວ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BuyerList(tickid: tickid, endpoint: 'tickets-not-received'),
            _BuyerList(tickid: tickid, endpoint: 'tickets-received'),
          ],
        ),
      ),
    );
  }
}

class _BuyerList extends StatefulWidget {
  final int tickid;
  final String endpoint;
  const _BuyerList({required this.tickid, required this.endpoint});

  @override
  State<_BuyerList> createState() => _BuyerListState();
}

class _BuyerListState extends State<_BuyerList> {
  bool _isLoading = true;
  String? _error;
  List<_BuyerItem> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _items = [];
    });

    try {
      final uri = ApiConfig.url(
        widget.endpoint,
      ).replace(queryParameters: {'tickid': widget.tickid.toString()});

      final res = await http.get(uri).timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        setState(() => _error = 'Request failed (HTTP ${res.statusCode}). Please try again.');
        return;
      }

      final body = jsonDecode(res.body);
      if (body is! Map || body['status'] != true || body['data'] is! List) {
        setState(() => _error = 'Invalid response format.');
        return;
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

      if (items.isEmpty) {
        setState(() => _error = 'No data found.');
        return;
      }

      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetch,
      child: _isLoading
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
                      onPressed: _fetch,
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
                    final it = _items[index];
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
}

class _BuyerItem {
  final String buyer;
  final String status;
  _BuyerItem({required this.buyer, required this.status});
}