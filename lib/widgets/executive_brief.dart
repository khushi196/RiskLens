import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/risk_report.dart';

class ExecutiveBriefPanel extends StatelessWidget {
  const ExecutiveBriefPanel({
    super.key,
    required this.report,
    required this.onCopy,
  });

  final RiskReport report;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Executive summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          gap(),
          _BriefItem(label: 'Top concern', value: report.brief.topConcern),
          _BriefItem(
            label: 'Recommended next step',
            value: report.brief.nextStep,
          ),
          _BriefItem(
            label: 'Leadership decision needed',
            value: report.brief.decision,
          ),
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy brief'),
          ),
        ],
      ),
    );
  }
}

class _BriefItem extends StatelessWidget {
  const _BriefItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(value, style: const TextStyle(height: 1.45)),
        ],
      ),
    );
  }
}
