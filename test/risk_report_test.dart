import 'package:flutter_test/flutter_test.dart';
import 'package:risk_ai/models/risk_report.dart';

void main() {
  test('RiskReport round-trips through JSON', () {
    final report = RiskReport.create(
      projectName: 'Checkout Launch',
      description: 'Checkout with payments and refunds.',
      industry: 'E-commerce',
      mode: 'Executive',
      createdAt: DateTime(2026, 6, 24, 20, 30),
    );

    final restored = RiskReport.fromJson(report.toJson());

    expect(restored.projectName, 'Checkout Launch');
    expect(
      restored.risks.map((risk) => risk.title),
      contains('Refund policy gaps'),
    );
    expect(restored.brief.topConcern, report.brief.topConcern);
  });
}
