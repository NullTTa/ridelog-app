import 'package:flutter_test/flutter_test.dart';
import 'package:ridelog/models/category.dart';
import 'package:ridelog/models/maintenance_record.dart';
import 'package:ridelog/services/api_service.dart';
import 'package:ridelog/services/local_record_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

MaintenanceRecord _record(Category c, int mileage, DateTime date,
        {String? title, int cost = 10000, String? memo}) =>
    MaintenanceRecord(
      category: c,
      title: title ?? '${c.label} 교체',
      mileage: mileage,
      cost: cost,
      serviceDate: date,
      memo: memo,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('등록 → 목록/필터 → 요약 계산 → 수정 → 삭제', () async {
    final repo = LocalRecordRepository(seedOnFirstRun: false);
    expect(repo.isDemo, isTrue);
    expect(await repo.fetchRecords(), isEmpty);

    // 등록
    final oil = await repo.createRecord(
        _record(Category.engineOil, 10000, DateTime(2026, 9, 1), cost: 35000));
    final tire = await repo.createRecord(
        _record(Category.tire, 12000, DateTime(2026, 10, 1), cost: 200000));
    final battery = await repo.createRecord(
        _record(Category.battery, 12500, DateTime(2026, 10, 1), cost: 60000));
    expect([oil.id, tire.id, battery.id], [1, 2, 3]);

    // 목록: 정비일 내림차순, 같은 날이면 id 내림차순 (서버와 동일)
    final list = await repo.fetchRecords();
    expect(list.map((r) => r.id), [3, 2, 1]);
    expect((await repo.fetchRecords(category: Category.tire)).single.id, tire.id);
    expect((await repo.fetchRecord(oil.id!)).cost, 35000);

    // 요약: 최대 주행거리 12,500 기준
    var s = await repo.fetchSummary();
    expect(s.totalCount, 3);
    expect(s.totalCost, 295000);
    expect(s.latestMileage, 12500);
    // 배터리는 주기 없음 → 표시 안 함
    expect(s.nextServices.map((n) => n.category), [Category.engineOil, Category.tire]);
    final oilNext = s.nextServices.first;
    expect(oilNext.lastMileage, 10000);
    expect(oilNext.nextMileage, 13000); // 10,000 + 3,000
    expect(oilNext.remainingKm, 500); // 13,000 - 12,500
    expect(s.nextServices[1].remainingKm, 27000 - 12500); // 12,000 + 15,000

    // 수정: 엔진오일 주행거리를 9,000으로 → 남은 km 가 음수(교체 시기 지남)
    final updated = await repo.updateRecord(
        oil.id!, _record(Category.engineOil, 9000, DateTime(2026, 9, 1), memo: '수정됨'));
    expect(updated.id, oil.id);
    expect((await repo.fetchRecord(oil.id!)).memo, '수정됨');
    s = await repo.fetchSummary();
    expect(s.nextServices.first.remainingKm, 12000 - 12500);

    // 삭제
    await repo.deleteRecord(tire.id!);
    expect((await repo.fetchRecords()).map((r) => r.id), [3, 1]);
    s = await repo.fetchSummary();
    expect(s.totalCount, 2);
    expect(s.nextServices.map((n) => n.category), [Category.engineOil]);

    // 삭제 후 새 기록의 id 는 재사용하지 않음
    final again = await repo.createRecord(_record(Category.etc, 13000, DateTime(2026, 11, 1)));
    expect(again.id, 4);

    // 없는 기록
    expect(() => repo.fetchRecord(99), throwsA(isA<ApiException>()));
    expect(() => repo.deleteRecord(tire.id!), throwsA(isA<ApiException>()));
  });

  test('입력 검증은 서버와 같은 규칙(필수값, 0 이상, 길이 제한)', () async {
    final repo = LocalRecordRepository(seedOnFirstRun: false);
    final date = DateTime(2026, 11, 1);

    Future<void> expectInvalid(MaintenanceRecord r, String field) => expectLater(
          repo.createRecord(r),
          throwsA(isA<ApiException>().having((e) => e.message, 'message', startsWith(field))),
        );

    await expectInvalid(_record(Category.tire, 100, date, title: '  '), 'title');
    await expectInvalid(_record(Category.tire, 100, date, title: 'a' * 101), 'title');
    await expectInvalid(_record(Category.tire, -1, date), 'mileage');
    await expectInvalid(_record(Category.tire, 100, date, cost: -1), 'cost');
    await expectInvalid(_record(Category.tire, 100, date, memo: 'a' * 501), 'memo');
    expect(await repo.fetchRecords(), isEmpty);

    // 경계값은 통과
    await repo.createRecord(_record(Category.tire, 0, date, title: 'a' * 100, cost: 0, memo: 'a' * 500));
    expect((await repo.fetchRecords()).length, 1);
  });

  test('처음 실행 시에만 샘플 기록을 넣고, 그중 하나는 교체 시기가 지나 있다', () async {
    final repo = LocalRecordRepository();
    final records = await repo.fetchRecords();
    expect(records.length, 5);
    expect(records.map((r) => r.category).toSet(),
        containsAll([Category.engineOil, Category.tire, Category.brake, Category.chain]));

    final s = await repo.fetchSummary();
    expect(s.nextServices.where((n) => n.remainingKm <= 0).map((n) => n.category),
        [Category.engineOil]);

    // 전부 지운 뒤 다시 열어도 샘플이 다시 생기지 않음
    for (final r in records) {
      await repo.deleteRecord(r.id!);
    }
    expect(await LocalRecordRepository().fetchRecords(), isEmpty);
  });
}
