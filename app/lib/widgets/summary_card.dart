import 'package:flutter/material.dart';

import '../models/summary.dart';
import '../utils/format.dart';

/// 홈 상단: 총 정비 횟수 / 총 비용 / 최근 주행거리 + 다음 정비 예정
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.summary});

  final Summary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.primaryContainer,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _stat(context, '정비 횟수', '${summary.totalCount}회'),
                _stat(context, '총 비용', formatWon(summary.totalCost)),
                _stat(context, '최근 주행', formatKm(summary.latestMileage)),
              ],
            ),
            if (summary.nextServices.isNotEmpty) ...[
              const Divider(height: 24),
              Text('다음 정비 예정',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: scheme.onPrimaryContainer)),
              const SizedBox(height: 8),
              ...summary.nextServices.map((n) {
                final overdue = n.remainingKm <= 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(n.category.icon, size: 18, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${n.category.label}  ·  ${formatKm(n.nextMileage)}',
                            style: TextStyle(color: scheme.onPrimaryContainer)),
                      ),
                      Text(
                        overdue ? '교체 시기 지남' : '${formatKm(n.remainingKm)} 남음',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: overdue ? scheme.error : scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    final color = Theme.of(context).colorScheme.onPrimaryContainer;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }
}
