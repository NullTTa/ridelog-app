import 'package:flutter/material.dart';

import '../models/maintenance_record.dart';
import '../services/record_repository.dart';
import '../utils/format.dart';
import 'record_form_screen.dart';

class RecordDetailScreen extends StatefulWidget {
  const RecordDetailScreen({super.key, required this.recordId});

  final int recordId;

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  final RecordRepository _api = Repositories.current;
  MaintenanceRecord? _record;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await _api.fetchRecord(widget.recordId);
      if (mounted) setState(() => _record = r);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _edit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RecordFormScreen(initial: _record)),
    );
    if (saved == true) _load();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: const Text('삭제한 정비 기록은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _api.deleteRecord(widget.recordId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('정비 상세'),
          actions: [
            if (_record != null) ...[
              IconButton(onPressed: _edit, icon: const Icon(Icons.edit), tooltip: '수정'),
              IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline), tooltip: '삭제'),
            ],
          ],
        ),
        body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) return Center(child: Text(_error!));
    final r = _record;
    if (r == null) return const Center(child: CircularProgressIndicator());

    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: scheme.primaryContainer,
              child: Icon(r.category.icon, size: 28, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.category.label, style: TextStyle(color: scheme.primary)),
                  Text(r.title, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _row('정비일', formatDate(r.serviceDate)),
        _row('주행거리', formatKm(r.mileage)),
        _row('비용', formatWon(r.cost)),
        _row('정비소', (r.shop == null || r.shop!.isEmpty) ? '-' : r.shop!),
        const Divider(height: 32),
        Text('메모', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text((r.memo == null || r.memo!.isEmpty) ? '메모 없음' : r.memo!),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
          ],
        ),
      );
}
