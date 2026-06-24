import 'package:flutter/material.dart';

import '../app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.projectController,
    required this.descriptionController,
    required this.industry,
    required this.mode,
    required this.error,
    required this.onIndustryChanged,
    required this.onModeChanged,
    required this.onGenerate,
  });

  final TextEditingController projectController;
  final TextEditingController descriptionController;
  final String industry;
  final String mode;
  final String? error;
  final ValueChanged<String> onIndustryChanged;
  final ValueChanged<String> onModeChanged;
  final VoidCallback onGenerate;

  static const industries = ['Fintech', 'SaaS', 'Healthcare', 'E-commerce'];
  static const modes = ['Quick', 'Detailed', 'Executive'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RiskLens',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI risk analysis for product launches',
            style: TextStyle(color: AppColors.muted, fontSize: 16),
          ),
          gap(24),
          TextField(
            key: const Key('project-name-field'),
            controller: projectController,
            decoration: fieldDecoration('Project name'),
          ),
          gap(14),
          TextField(
            key: const Key('project-description-field'),
            controller: descriptionController,
            minLines: 5,
            maxLines: 7,
            decoration: fieldDecoration('Project description'),
          ),
          if (error != null) ...[
            gap(12),
            Text(error!, style: const TextStyle(color: AppColors.coral)),
          ],
          gap(16),
          DropdownButtonFormField<String>(
            initialValue: industry,
            decoration: fieldDecoration('Industry'),
            items: [
              for (final item in industries)
                DropdownMenuItem(value: item, child: Text(item)),
            ],
            onChanged: (value) {
              if (value != null) onIndustryChanged(value);
            },
          ),
          gap(16),
          const Text(
            'Analysis mode',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          gap(10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final item in modes)
                ChoiceChip(
                  selected: mode == item,
                  label: Text(item),
                  onSelected: (_) => onModeChanged(item),
                  selectedColor: AppColors.violet.withValues(alpha: 0.18),
                ),
            ],
          ),
          gap(24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('generate-button'),
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Generate risk register'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
