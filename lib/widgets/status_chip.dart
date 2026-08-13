import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  static const Map<String, String> labels = {
    'raw': 'Сырая идея',
    'wip': 'На проработке',
    'ready': 'Рабочая',
    'stage': 'В сете',
    'dead': 'Списана',
  };

  static const Map<String, Color> colors = {
    'raw': Colors.grey,
    'wip': Colors.orange,
    'ready': Colors.green,
    'stage': Colors.blue,
    'dead': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (colors[status] ?? Colors.grey).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        labels[status] ?? status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors[status] ?? Colors.grey,
        ),
      ),
    );
  }
}
