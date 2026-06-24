import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'screens/settings_screen.dart';
import 'services/local_report_storage.dart';
import 'services/report_exporter.dart';
import 'services/risk_api_service.dart';
import 'widgets/app_shell.dart';

void main() => runApp(const RiskLensApp());

class RiskLensApp extends StatelessWidget {
  const RiskLensApp({
    super.key,
    this.storage = const LocalReportStorage(),
    this.generator,
    this.exporter,
    this.backendChecker,
  });

  final LocalReportStorage storage;
  final RiskGenerator? generator;
  final RiskReportExporter? exporter;
  final BackendChecker? backendChecker;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RiskLens',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.cyan,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: AppShell(
        storage: storage,
        generator: generator,
        exporter: exporter,
        backendChecker: backendChecker,
      ),
    );
  }
}
