import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';
import '../models/maintenance_record.dart';
import '../models/summary.dart';
import 'api_service.dart';
import 'record_repository.dart';

/// 오프라인 데모 모드 저장소
/// 서버 없이 기기 내부(shared_preferences)에 정비 기록을 JSON 으로 저장한다.
/// 정렬·입력 검증·요약 계산 규칙은 서버(MaintenanceRecordService, RecordRequest)와 동일.
class LocalRecordRepository implements RecordRepository {
  LocalRecordRepository({this.seedOnFirstRun = true});

  /// 처음 실행할 때 샘플 기록을 넣을지 여부 (테스트에서는 false)
  final bool seedOnFirstRun;

  static const recordsKey = 'ridelog.records';
  static const nextIdKey = 'ridelog.nextId';
  static const seededKey = 'ridelog.seeded';

  static const _maxInt = 2147483647; // 서버 Integer 최대값

  @override
  bool get isDemo => true;

  // ---- 조회 ----

  @override
  Future<List<MaintenanceRecord>> fetchRecords({Category? category}) async {
    final all = await _loadAll();
    final list = category == null ? all : all.where((r) => r.category == category).toList();
    // 서버와 동일: 정비일 내림차순, 같으면 id 내림차순
    list.sort((a, b) {
      final byDate = b.serviceDate.compareTo(a.serviceDate);
      return byDate != 0 ? byDate : b.id!.compareTo(a.id!);
    });
    return list;
  }

  @override
  Future<MaintenanceRecord> fetchRecord(int id) async {
    final all = await _loadAll();
    return all.firstWhere((r) => r.id == id, orElse: () => throw _notFound(id));
  }

  @override
  Future<List<Category>> fetchCategories() async => Category.values.toList();

  @override
  Future<Summary> fetchSummary() async {
    final all = await _loadAll();
    final totalCost = all.fold<int>(0, (sum, r) => sum + r.cost);
    // 전체 기록 중 최대 주행거리 (기록이 없으면 0)
    final latestMileage = all.fold<int>(0, (m, r) => r.mileage > m ? r.mileage : m);

    final next = <NextService>[];
    for (final c in Category.values) {
      if (c.intervalKm == 0) continue; // 배터리·기타: 주기 없음
      final inCategory = all.where((r) => r.category == c);
      if (inCategory.isEmpty) continue;
      // 분류별 마지막 정비 = 해당 분류에서 주행거리가 가장 큰 기록
      final lastMileage = inCategory.map((r) => r.mileage).reduce((a, b) => a > b ? a : b);
      final nextMileage = lastMileage + c.intervalKm;
      next.add(NextService(
        category: c,
        lastMileage: lastMileage,
        nextMileage: nextMileage,
        remainingKm: nextMileage - latestMileage,
      ));
    }

    return Summary(
      totalCount: all.length,
      totalCost: totalCost,
      latestMileage: latestMileage,
      nextServices: next,
    );
  }

  // ---- 변경 ----

  @override
  Future<MaintenanceRecord> createRecord(MaintenanceRecord record) async {
    _validate(record);
    final prefs = await _prefs();
    final all = await _loadAll();
    final id = _nextId(prefs, all);
    final saved = _withId(record, id);
    all.add(saved);
    await prefs.setInt(nextIdKey, id + 1);
    await _saveAll(prefs, all);
    return saved;
  }

  @override
  Future<MaintenanceRecord> updateRecord(int id, MaintenanceRecord record) async {
    final prefs = await _prefs();
    final all = await _loadAll();
    final index = all.indexWhere((r) => r.id == id);
    if (index < 0) throw _notFound(id); // 서버와 동일하게 존재 확인 후 검증
    _validate(record);
    final saved = _withId(record, id);
    all[index] = saved;
    await _saveAll(prefs, all);
    return saved;
  }

  @override
  Future<void> deleteRecord(int id) async {
    final prefs = await _prefs();
    final all = await _loadAll();
    final before = all.length;
    all.removeWhere((r) => r.id == id);
    if (all.length == before) throw _notFound(id);
    await _saveAll(prefs, all);
  }

  // ---- 입력 검증 (서버 RecordRequest 의 Bean Validation 과 동일한 규칙) ----

  static void _validate(MaintenanceRecord r) {
    String? error;
    if (r.title.trim().isEmpty) {
      error = 'title: 필수 입력입니다.';
    } else if (r.title.length > 100) {
      error = 'title: 100자 이하로 입력해 주세요.';
    } else if (r.mileage < 0 || r.mileage > _maxInt) {
      error = 'mileage: 0 이상의 올바른 숫자를 입력해 주세요.';
    } else if (r.cost < 0 || r.cost > _maxInt) {
      error = 'cost: 0 이상의 올바른 숫자를 입력해 주세요.';
    } else if ((r.shop?.length ?? 0) > 100) {
      error = 'shop: 100자 이하로 입력해 주세요.';
    } else if ((r.memo?.length ?? 0) > 500) {
      error = 'memo: 500자 이하로 입력해 주세요.';
    }
    if (error != null) throw ApiException(error);
  }

  // ---- 저장소 처리 ----

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<List<MaintenanceRecord>> _loadAll() async {
    final prefs = await _prefs();
    if (seedOnFirstRun && !(prefs.getBool(seededKey) ?? false)) {
      await _seed(prefs);
    }
    final raw = prefs.getString(recordsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveAll(SharedPreferences prefs, List<MaintenanceRecord> all) async {
    final json = all.map((r) => {'id': r.id, ...r.toJson()}).toList();
    await prefs.setString(recordsKey, jsonEncode(json));
  }

  int _nextId(SharedPreferences prefs, List<MaintenanceRecord> all) {
    final stored = prefs.getInt(nextIdKey) ?? 1;
    final maxId = all.fold<int>(0, (m, r) => r.id! > m ? r.id! : m);
    return stored > maxId ? stored : maxId + 1;
  }

  static MaintenanceRecord _withId(MaintenanceRecord r, int id) => MaintenanceRecord(
        id: id,
        category: r.category,
        title: r.title,
        mileage: r.mileage,
        cost: r.cost,
        serviceDate: r.serviceDate,
        shop: r.shop,
        memo: r.memo,
      );

  static ApiException _notFound(int id) => ApiException('정비 기록을 찾을 수 없습니다. id=$id');

  /// 처음 실행할 때만 샘플 기록 5개를 넣는다.
  /// 최근 주행거리 15,200km 기준 → 엔진오일(11,800 + 3,000 = 14,800)은 교체 시기가 지나 빨간 경고로 표시됨.
  /// 이후 사용자가 전부 삭제해도 다시 채우지 않는다.
  Future<void> _seed(SharedPreferences prefs) async {
    final samples = [
      MaintenanceRecord(
          id: 1,
          category: Category.tire,
          title: '앞·뒤 타이어 교체',
          mileage: 8000,
          cost: 280000,
          serviceDate: DateTime(2026, 3, 14),
          shop: '부평 바이크',
          memo: '미쉐린 로드6'),
      MaintenanceRecord(
          id: 2,
          category: Category.battery,
          title: '배터리 교체',
          mileage: 9500,
          cost: 65000,
          serviceDate: DateTime(2026, 5, 2),
          shop: '부평 바이크'),
      MaintenanceRecord(
          id: 3,
          category: Category.engineOil,
          title: '엔진오일 교체',
          mileage: 11800,
          cost: 35000,
          serviceDate: DateTime(2026, 7, 20),
          shop: '부평 바이크',
          memo: '10W-30 / 교체 시기 지남 예시'),
      MaintenanceRecord(
          id: 4,
          category: Category.brake,
          title: '앞 브레이크 패드 교체',
          mileage: 12500,
          cost: 48000,
          serviceDate: DateTime(2026, 8, 30),
          shop: '인천 모터스'),
      MaintenanceRecord(
          id: 5,
          category: Category.chain,
          title: '체인/스프라켓 세트 교체',
          mileage: 15200,
          cost: 160000,
          serviceDate: DateTime(2026, 10, 25),
          shop: '인천 모터스',
          memo: 'DID 520 체인'),
    ];
    await _saveAll(prefs, samples);
    await prefs.setInt(nextIdKey, samples.length + 1);
    await prefs.setBool(seededKey, true);
  }
}
