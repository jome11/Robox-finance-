import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<Map<String, dynamic>> _log = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final log = await context.read<FinanceProvider>().loadAudit();
    if (!mounted) return;
    setState(() {
      _log = log;
      _loading = false;
    });
  }

  String _fmt(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final deleted = finance.deletedTransactions;

    return Scaffold(
      appBar: AppBar(title: const Text('Deleted & activity')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Deleted transactions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (deleted.isEmpty) const Text('Nothing has been deleted.'),
                  for (final t in deleted)
                    Card(
                      child: ListTile(
                        title: Text(
                          t.title,
                          style: const TextStyle(decoration: TextDecoration.lineThrough),
                        ),
                        subtitle: Text(
                          'Br ${t.amount.toStringAsFixed(2)} (${t.type})\n'
                          'Deleted by ${t.deletedBy} on ${_fmt(t.deletedAt)}',
                        ),
                        isThreeLine: true,
                        trailing: TextButton(
                          onPressed: () async {
                            await finance.restoreTransaction(t.id);
                            await _refresh();
                          },
                          child: const Text('Restore'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text('Recent activity',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_log.isEmpty) const Text('No activity yet.'),
                  for (final e in _log)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${e['actor']} - ${e['action']}'),
                      subtitle: Text('${e['summary'] ?? ''}\n${_fmt('${e['at']}')}'),
                      isThreeLine: true,
                    ),
                ],
              ),
            ),
    );
  }
}
