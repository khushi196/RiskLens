import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/risk_report.dart';
import '../widgets/executive_brief.dart';
import '../widgets/metric_card.dart';
import '../widgets/risk_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.report,
    required this.onCopyBrief,
    required this.onExportReport,
  });

  final RiskReport report;
  final VoidCallback onCopyBrief;
  final VoidCallback onExportReport;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...widget.report.categories];
    final visibleRisks = selectedCategory == 'All'
        ? widget.report.risks
        : widget.report.risks
              .where((risk) => risk.category == selectedCategory)
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              widget.report.projectName,
              style: const TextStyle(color: AppColors.muted, fontSize: 16),
            ),
            Chip(
              label: Text(
                widget.report.usedFallback
                    ? 'Fallback analysis'
                    : 'Gemini analysis',
              ),
              avatar: Icon(
                widget.report.usedFallback
                    ? Icons.shield_outlined
                    : Icons.auto_awesome_rounded,
                size: 16,
              ),
            ),
          ],
        ),
        gap(22),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 700 ? 2 : 4;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: columns == 2 ? 0.9 : 1.1,
              children: [
                MetricCard(
                  label: 'Risk score',
                  value: '${widget.report.score}',
                  helper: widget.report.level,
                  color: AppColors.cyan,
                ),
                MetricCard(
                  label: 'Risks',
                  value: '${widget.report.risks.length}',
                  helper: 'Generated items',
                  color: AppColors.violet,
                ),
                MetricCard(
                  label: 'Industry',
                  value: widget.report.industry,
                  helper: widget.report.mode,
                  color: AppColors.amber,
                ),
                MetricCard(
                  label: 'Critical',
                  value:
                      '${widget.report.risks.where((risk) => risk.severity == 'Critical').length}',
                  helper: 'Needs review',
                  color: AppColors.coral,
                ),
              ],
            );
          },
        ),
        gap(22),
        ExecutiveBriefPanel(report: widget.report, onCopy: widget.onCopyBrief),
        gap(22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: panelDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Risk register',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onExportReport,
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Export report'),
                  ),
                ],
              ),
              gap(14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final category in categories)
                    ChoiceChip(
                      selected: selectedCategory == category,
                      label: Text(category),
                      onSelected: (_) =>
                          setState(() => selectedCategory = category),
                      selectedColor: AppColors.cyan.withValues(alpha: 0.16),
                    ),
                ],
              ),
              gap(18),
              for (final risk in visibleRisks) ...[
                RiskCard(risk: risk, expanded: true),
                gap(12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
