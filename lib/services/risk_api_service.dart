import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/risk_report.dart';

abstract class RiskGenerator {
  Future<RiskReport> generate({
    required String projectName,
    required String description,
    required String industry,
    required String mode,
  });
}

class RiskApiService implements RiskGenerator {
  RiskApiService({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? defaultBaseUrl,
      _client = client ?? http.Client();

  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  final String baseUrl;
  final http.Client _client;

  Future<bool> checkHealth() async {
    final response = await _client.get(Uri.parse('$baseUrl/health'));
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  @override
  Future<RiskReport> generate({
    required String projectName,
    required String description,
    required String industry,
    required String mode,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/generate-risk-register'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'project_name': projectName,
        'description': description,
        'industry': industry,
        'mode': mode,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RiskApiException('Backend returned ${response.statusCode}.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return RiskReport.fromBackendJson(
      json,
      description: description,
      industry: industry,
      mode: mode,
      createdAt: DateTime.now(),
    );
  }
}

class RiskApiException implements Exception {
  const RiskApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
