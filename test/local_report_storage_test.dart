import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:risk_ai/models/risk_report.dart';
import 'package:risk_ai/services/local_report_storage.dart';

void main() {
  test('LocalReportStorage persists reports in browser storage', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalReportStorage();
    final report = RiskReport.create(
      projectName: 'Fintech Wallet',
      description: 'Wallet app with KYC and payments.',
      industry: 'Fintech',
      mode: 'Detailed',
      createdAt: DateTime(2026, 6, 24, 21),
    );

    await storage.saveReport(report);
    final loaded = await storage.loadReports();

    expect(loaded, hasLength(1));
    expect(loaded.single.projectName, 'Fintech Wallet');
  });
}
