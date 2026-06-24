import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/risk_report.dart';

class RiskCard extends StatelessWidget {
  const RiskCard({super.key, required this.risk, this.expanded = false});

  final RiskItem risk;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(color: AppColors.field, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  risk.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SeverityBadge(label: risk.severity),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _Meta(icon: Icons.folder_outlined, label: risk.category),
              _Meta(icon: Icons.person_outline, label: risk.owner),
              _Meta(icon: Icons.trending_up_rounded, label: risk.probability),
              _Meta(icon: Icons.bolt_outlined, label: '${risk.impact} impact'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            risk.scenario,
            style: const TextStyle(color: AppColors.text, height: 1.45),
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            Text(
              'Why exposed: ${risk.exposure}',
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 8),
            Text(
              'Mitigation: ${risk.mitigation}',
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 8),
            Text(
              'Warning signs: ${risk.warningSigns}',
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 8),
            Text(
              'Contingency: ${risk.contingency}',
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

class SeverityBadge extends StatelessWidget {
  const SeverityBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Critical' => AppColors.coral,
      'High' || 'High Attention' => AppColors.amber,
      _ => AppColors.cyan,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.muted),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: AppColors.muted)),
      ],
    );
  }
}
