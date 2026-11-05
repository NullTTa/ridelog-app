import 'category.dart';

class MaintenanceRecord {
  final int? id;
  final Category category;
  final String title;
  final int mileage;
  final int cost;
  final DateTime serviceDate;
  final String? shop;
  final String? memo;

  MaintenanceRecord({
    this.id,
    required this.category,
    required this.title,
    required this.mileage,
    required this.cost,
    required this.serviceDate,
    this.shop,
    this.memo,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as int?,
      category: Category.fromCode(json['category'] as String),
      title: json['title'] as String,
      mileage: json['mileage'] as int,
      cost: json['cost'] as int,
      serviceDate: DateTime.parse(json['serviceDate'] as String),
      shop: json['shop'] as String?,
      memo: json['memo'] as String?,
    );
  }

  /// 서버 RecordRequest 형식으로 변환 (id 제외)
  Map<String, dynamic> toJson() {
    final d = serviceDate;
    final date =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return {
      'category': category.code,
      'title': title,
      'mileage': mileage,
      'cost': cost,
      'serviceDate': date,
      'shop': shop,
      'memo': memo,
    };
  }
}
