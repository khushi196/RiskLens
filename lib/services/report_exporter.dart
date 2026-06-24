import '../models/risk_report.dart';
import 'report_exporter_stub.dart'
    if (dart.library.html) 'report_exporter_web.dart'
    as platform;

typedef RiskReportExporter = Future<void> Function(RiskReport report);

String buildReportText(RiskReport report) {
  final buffer = StringBuffer()
    ..writeln('RiskLens Risk Register')
    ..writeln('Project: ${report.projectName}')
    ..writeln('Industry: ${report.industry}')
    ..writeln('Mode: ${report.mode}')
    ..writeln(
      'Source: ${report.usedFallback ? 'Fallback analysis' : 'Gemini analysis'}',
    )
    ..writeln('Risk score: ${report.score} (${report.level})')
    ..writeln();

  if (report.fallbackReason != null && report.fallbackReason!.isNotEmpty) {
    buffer
      ..writeln('Fallback reason')
      ..writeln(report.fallbackReason)
      ..writeln();
  }

  buffer
    ..writeln('Project Description')
    ..writeln(report.description)
    ..writeln()
    ..writeln('Executive Summary')
    ..writeln(report.summary)
    ..writeln()
    ..writeln('Top concern: ${report.brief.topConcern}')
    ..writeln('Recommended next step: ${report.brief.nextStep}')
    ..writeln('Leadership decision needed: ${report.brief.decision}')
    ..writeln()
    ..writeln('Risks');

  for (var index = 0; index < report.risks.length; index += 1) {
    final risk = report.risks[index];
    buffer
      ..writeln('${index + 1}. ${risk.title}')
      ..writeln('   Category: ${risk.category}')
      ..writeln('   Severity: ${risk.severity}')
      ..writeln('   Probability: ${risk.probability}')
      ..writeln('   Impact: ${risk.impact}')
      ..writeln('   Owner: ${risk.owner}')
      ..writeln('   Scenario: ${risk.scenario}')
      ..writeln('   Why exposed: ${risk.exposure}')
      ..writeln('   Mitigation: ${risk.mitigation}')
      ..writeln('   Warning signs: ${risk.warningSigns}')
      ..writeln('   Contingency: ${risk.contingency}')
      ..writeln();
  }

  return buffer.toString().trimRight();
}

String buildReportFileName(RiskReport report) {
  final safeName = report.projectName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'risklens-${safeName.isEmpty ? 'risk-report' : safeName}.txt';
}

Future<void> exportRiskReport(RiskReport report) async {
  await platform.downloadTextFile(
    buildReportFileName(report),
    buildReportText(report),
  );
}
