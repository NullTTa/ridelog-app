import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridelog/models/category.dart';
import 'package:ridelog/models/summary.dart';
import 'package:ridelog/widgets/summary_card.dart';

void main() {
  testWidgets('요약 카드에 총 비용과 다음 정비가 표시된다', (tester) async {
    final summary = Summary(
      totalCount: 2,
      totalCost: 85000,
      latestMileage: 12500,
      nextServices: [
        NextService(
            category: Category.engineOil,
            lastMileage: 12000,
            nextMileage: 15000,
            remainingKm: 2500),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SummaryCard(summary: summary))));

    expect(find.text('2회'), findsOneWidget);
    expect(find.text('85,000원'), findsOneWidget);
    expect(find.text('2,500km 남음'), findsOneWidget);
  });
}
