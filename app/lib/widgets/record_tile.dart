import 'package:flutter/material.dart';

import '../models/maintenance_record.dart';
import '../utils/format.dart';

class RecordTile extends StatelessWidget {
  const RecordTile({super.key, required this.record, required this.onTap});

  final MaintenanceRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          child: Icon(record.category.icon, color: scheme.onSecondaryContainer),
        ),
        title: Text(record.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
            '${record.category.label} · ${formatDate(record.serviceDate)} · ${formatKm(record.mileage)}'),
        trailing: Text(formatWon(record.cost),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
