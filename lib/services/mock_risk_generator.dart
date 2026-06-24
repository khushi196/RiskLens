import '../models/risk_report.dart';
import 'risk_api_service.dart';

class MockRiskGenerator implements RiskGenerator {
  const MockRiskGenerator();

  @override
  Future<RiskReport> generate({
    required String projectName,
    required String description,
    required String industry,
    required String mode,
  }) async {
    return RiskReport.create(
      projectName: projectName,
      description: description,
      industry: industry,
      mode: mode,
      createdAt: DateTime.now(),
    );
  }
}
