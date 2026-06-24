import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:risk_ai/services/risk_api_service.dart';

void main() {
  test('RiskApiService maps backend risk register response', () async {
    final service = RiskApiService(
      baseUrl: 'http://example.test',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/generate-risk-register');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['project_name'], 'Fintech Wallet');

        return http.Response(
          jsonEncode({
            'project_name': 'Fintech Wallet',
            'score': 78,
            'level': 'High Attention',
            'summary': 'Backend generated summary.',
            'source': 'gemini',
            'fallback_reason': null,
            'executive_brief': {
              'top_concern': 'Payment reliability is the top concern.',
              'recommended_next_step': 'Run payment failure drills.',
              'leadership_decision_needed': 'Approve backup provider budget.',
            },
            'risks': [
              {
                'title': 'Payment reliability',
                'category': 'Technical',
                'severity': 'High',
                'probability': 'Medium',
                'impact': 'High',
                'owner': 'Backend Lead',
                'scenario': 'Gateway callbacks arrive late.',
                'why_this_project_is_exposed':
                    'The wallet relies on payment callbacks.',
                'mitigation': 'Add retries and fallback gateway.',
                'warning_signs': 'Gateway callback delays.',
                'contingency': 'Route through backup provider.',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final report = await service.generate(
      projectName: 'Fintech Wallet',
      description: 'Wallet app with KYC and payments.',
      industry: 'Fintech',
      mode: 'Executive',
    );

    expect(report.projectName, 'Fintech Wallet');
    expect(report.score, 78);
    expect(report.source, 'gemini');
    expect(report.brief.nextStep, 'Run payment failure drills.');
    expect(report.risks.single.scenario, 'Gateway callbacks arrive late.');
    expect(
      report.risks.single.exposure,
      'The wallet relies on payment callbacks.',
    );
  });
}
