import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/category.dart';
import '../models/maintenance_record.dart';
import '../services/record_repository.dart';
import '../utils/format.dart';

/// 정비 기록 등록 / 수정 화면 (initial 이 있으면 수정 모드)
class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({super.key, this.initial});

  final MaintenanceRecord? initial;

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final RecordRepository _api = Repositories.current;

  late Category _category;
  late DateTime _date;
  late final TextEditingController _title;
  late final TextEditingController _mileage;
  late final TextEditingController _cost;
  late final TextEditingController _shop;
  late final TextEditingController _memo;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _category = r?.category ?? Category.engineOil;
    _date = r?.serviceDate ?? DateTime.now();
    _title = TextEditingController(text: r?.title ?? '');
    _mileage = TextEditingController(text: r?.mileage.toString() ?? '');
    _cost = TextEditingController(text: r?.cost.toString() ?? '');
    _shop = TextEditingController(text: r?.shop ?? '');
    _memo = TextEditingController(text: r?.memo ?? '');
  }

  @override
  void dispose() {
    for (final c in [_title, _mileage, _cost, _shop, _memo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final record = MaintenanceRecord(
      category: _category,
      title: _title.text.trim(),
      mileage: int.parse(_mileage.text),
      cost: int.parse(_cost.text),
      serviceDate: _date,
      shop: _shop.text.trim().isEmpty ? null : _shop.text.trim(),
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
    );

    try {
      if (_isEdit) {
        await _api.updateRecord(widget.initial!.id!, record);
      } else {
        await _api.createRecord(record);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '수정되었습니다.' : '등록되었습니다.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? '필수 입력입니다.' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '정비 기록 수정' : '정비 기록 등록')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('분류', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: Category.values
                  .map((c) => ChoiceChip(
                        avatar: Icon(c.icon, size: 18),
                        label: Text(c.label),
                        selected: _category == c,
                        onSelected: (_) => setState(() {
                          _category = c;
                          // 제목이 비어 있으면 분류명으로 자동 채움
                          if (_title.text.isEmpty) _title.text = '${c.label} 교체';
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: '정비 내용 *', hintText: '예) 엔진오일 교체'),
              validator: _required,
              maxLength: 100,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _mileage,
                    decoration: const InputDecoration(labelText: '주행거리 *', suffixText: 'km'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cost,
                    decoration: const InputDecoration(labelText: '비용 *', suffixText: '원'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _required,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '정비일 *',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(formatDate(_date)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _shop,
              decoration: const InputDecoration(labelText: '정비소'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _memo,
              decoration: const InputDecoration(labelText: '메모', alignLabelWithHint: true),
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(_isEdit ? '수정하기' : '저장하기'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}
