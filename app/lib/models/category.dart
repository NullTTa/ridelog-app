import 'package:flutter/material.dart';

/// 서버의 Category enum 과 코드·권장 주기가 1:1로 맞아야 함
enum Category {
  engineOil('ENGINE_OIL', '엔진오일', Icons.oil_barrel, 3000),
  tire('TIRE', '타이어', Icons.tire_repair, 15000),
  brake('BRAKE', '브레이크', Icons.do_not_disturb_on_outlined, 10000),
  chain('CHAIN', '체인/스프라켓', Icons.link, 15000),
  battery('BATTERY', '배터리', Icons.battery_charging_full, 0),
  etc('ETC', '기타', Icons.build_outlined, 0);

  const Category(this.code, this.label, this.icon, this.intervalKm);

  final String code;
  final String label;
  final IconData icon;

  /// 권장 교체 주기(km). 0이면 주기 없음 → 다음 정비 예정에 표시하지 않음
  final int intervalKm;

  static Category fromCode(String code) =>
      Category.values.firstWhere((c) => c.code == code, orElse: () => Category.etc);
}
