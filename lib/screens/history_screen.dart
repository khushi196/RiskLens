import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/risk_report.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.reports,
    required this.onOpen,
    required this.onDelete,
  });

  final List<RiskReport> reports;
  final ValueChanged<RiskReport> onOpen;
  final ValueChanged<RiskReport> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saved generated reports',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          gap(),
          if (reports.isEmpty)
            const Text(
              'Generated reports will appear here after you run an analysis.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            for (final report in reports)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: panelDecoration(color: AppColors.field, radius: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.projectName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${report.level} | ${report.risks.length} risks | ${report.createdLabel}',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => onOpen(report),
                      child: const Text('Open'),
                    ),
                    IconButton(
                      onPressed: () => onDelete(report),
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Delete report',
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
