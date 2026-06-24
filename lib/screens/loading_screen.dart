import 'package:flutter/material.dart';

import '../app_theme.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  final String currentStep;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analyzing project risk',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          gap(),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: const LinearProgressIndicator(
              minHeight: 9,
              color: AppColors.cyan,
            ),
          ),
          gap(22),
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    step == currentStep
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: step == currentStep
                        ? AppColors.cyan
                        : AppColors.muted,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    step,
                    style: TextStyle(
                      color: step == currentStep
                          ? AppColors.text
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
