import 'package:flutter_test/flutter_test.dart';
import 'package:ridelog/models/category.dart';
import 'package:ridelog/models/maintenance_record.dart';

void main() {
  test('서버 JSON → 모델 → 요청 JSON 변환', () {
    final r = MaintenanceRecord.fromJson({
      'id': 1,
      'category': 'ENGINE_OIL',
      'categoryLabel': '엔진오일',
      'title': '엔진오일 교체',
      'mileage': 12000,
      'cost': 35000,
      'serviceDate': '2026-11-01',
      'shop': null,
      'memo': null,
    });

    expect(r.category, Category.engineOil);
    expect(r.toJson()['serviceDate'], '2026-11-01');
    expect(r.toJson()['category'], 'ENGINE_OIL');
  });
}
