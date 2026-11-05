import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/maintenance_record.dart';
import '../models/summary.dart';
import '../services/api_service.dart';
import '../widgets/record_tile.dart';
import '../widgets/summary_card.dart';
import 'record_detail_screen.dart';
import 'record_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();

  List<MaintenanceRecord> _records = [];
  Summary? _summary;
  Category? _filter; // null = 전체
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 목록과 요약을 동시에 요청
      final results = await Future.wait([
        _api.fetchRecords(category: _filter),
        _api.fetchSummary(),
      ]);
      if (!mounted) return;
      setState(() {
        _records = results[0] as List<MaintenanceRecord>;
        _summary = results[1] as Summary;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RecordFormScreen()),
    );
    if (saved == true) _load();
  }

  Future<void> _openDetail(MaintenanceRecord r) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecordDetailScreen(recordId: r.id!)),
    );
    _load(); // 상세에서 수정/삭제했을 수 있으니 돌아오면 새로고침
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RideLog', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: '새로고침'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('정비 기록'),
      ),
      body: RefreshIndicator(onRefresh: _load, child: _body()),
    );
  }

  Widget _body() {
    if (_loading && _summary == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.cloud_off, size: 56),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          Center(child: FilledButton(onPressed: _load, child: const Text('다시 시도'))),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (_summary != null) SummaryCard(summary: _summary!),
        _filterChips(),
        if (_records.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: Text('정비 기록이 없습니다.\n오른쪽 아래 버튼으로 추가해 보세요.',
                textAlign: TextAlign.center)),
          )
        else
          ..._records.map((r) => RecordTile(record: r, onTap: () => _openDetail(r))),
      ],
    );
  }

  Widget _filterChips() {
    Widget chip(String label, Category? value) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: _filter == value,
            onSelected: (_) {
              setState(() => _filter = value);
              _load();
            },
          ),
        );

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip('전체', null),
          ...Category.values.map((c) => chip(c.label, c)),
        ],
      ),
    );
  }
}
