import 'category.dart';

class NextService {
  final Category category;
  final int lastMileage;
  final int nextMileage;
  final int remainingKm;

  NextService({
    required this.category,
    required this.lastMileage,
    required this.nextMileage,
    required this.remainingKm,
  });

  factory NextService.fromJson(Map<String, dynamic> json) => NextService(
        category: Category.fromCode(json['category'] as String),
        lastMileage: json['lastMileage'] as int,
        nextMileage: json['nextMileage'] as int,
        remainingKm: json['remainingKm'] as int,
      );
}

class Summary {
  final int totalCount;
  final int totalCost;
  final int latestMileage;
  final List<NextService> nextServices;

  Summary({
    required this.totalCount,
    required this.totalCost,
    required this.latestMileage,
    required this.nextServices,
  });

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
        totalCount: json['totalCount'] as int,
        totalCost: json['totalCost'] as int,
        latestMileage: json['latestMileage'] as int,
        nextServices: (json['nextServices'] as List)
            .map((e) => NextService.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
