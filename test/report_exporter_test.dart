import 'package:flutter_test/flutter_test.dart';
import 'package:risk_ai/models/risk_report.dart';
import 'package:risk_ai/services/report_exporter.dart';

void main() {
  test('buildReportText formats full report content', () {
    final report = RiskReport.create(
      projectName: 'Checkout Launch',
      description: 'Checkout with payments and refunds.',
      industry: 'E-commerce',
      mode: 'Executive',
      createdAt: DateTime(2026, 6, 24, 20, 30),
    );

    final text = buildReportText(report);

    expect(text, contains('RiskLens Risk Register'));
    expect(text, contains('Project: Checkout Launch'));
    expect(text, contains('Source: Fallback analysis'));
    expect(text, contains('Executive Summary'));
    expect(text, contains('Refund policy gaps'));
    expect(text, contains('Scenario:'));
    expect(text, contains('Why exposed:'));
    expect(text, contains('Mitigation:'));
    expect(text, contains('Contingency:'));
  });

  test('buildReportFileName creates a safe text file name', () {
    final report = RiskReport.create(
      projectName: 'Wallet: Beta / Launch',
      description: 'Wallet with KYC and payments.',
      industry: 'Fintech',
      mode: 'Quick',
      createdAt: DateTime(2026, 6, 24, 20, 30),
    );

    expect(buildReportFileName(report), 'risklens-wallet-beta-launch.txt');
  });
}
