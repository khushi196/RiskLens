import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/risk_report.dart';

class LocalReportStorage {
  const LocalReportStorage();

  static const _key = 'redflag_ai_reports';

  Future<List<RiskReport>> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getStringList(_key) ?? <String>[];
    return encoded
        .map(
          (item) =>
              RiskReport.fromJson(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveReport(RiskReport report) async {
    final reports = await loadReports();
    final updated = [report, ...reports.where((item) => item.id != report.id)];
    await _saveAll(updated);
  }

  Future<void> deleteReport(String id) async {
    final reports = await loadReports();
    await _saveAll(reports.where((item) => item.id != id).toList());
  }

  Future<void> _saveAll(List<RiskReport> reports) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = reports.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_key, encoded);
  }
}
