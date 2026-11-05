import 'package:flutter/material.dart';

/// 서버의 Category enum 과 코드가 1:1로 맞아야 함
enum Category {
  engineOil('ENGINE_OIL', '엔진오일', Icons.oil_barrel),
  tire('TIRE', '타이어', Icons.tire_repair),
  brake('BRAKE', '브레이크', Icons.do_not_disturb_on_outlined),
  chain('CHAIN', '체인/스프라켓', Icons.link),
  battery('BATTERY', '배터리', Icons.battery_charging_full),
  etc('ETC', '기타', Icons.build_outlined);

  const Category(this.code, this.label, this.icon);

  final String code;
  final String label;
  final IconData icon;

  static Category fromCode(String code) =>
      Category.values.firstWhere((c) => c.code == code, orElse: () => Category.etc);
}
