class RiskReport {
  const RiskReport({
    required this.id,
    required this.projectName,
    required this.description,
    required this.industry,
    required this.mode,
    required this.score,
    required this.level,
    required this.summary,
    required this.brief,
    required this.risks,
    required this.createdAt,
    this.source = 'fallback',
    this.fallbackReason,
  });

  factory RiskReport.create({
    required String projectName,
    required String description,
    required String industry,
    required String mode,
    required DateTime createdAt,
  }) {
    final text = description.toLowerCase();
    final risks = <RiskItem>[
      if (industry == 'Fintech' || text.contains('payment'))
        const RiskItem(
          title: 'Payment reliability',
          category: 'Technical',
          severity: 'High',
          probability: 'Medium probability',
          impact: 'High',
          owner: 'Backend Lead',
          scenario:
              'Payment authorization or callbacks fail during checkout spikes.',
          exposure:
              'The project includes payment or wallet flows that depend on reliable gateway events.',
          mitigation:
              'Add payment retries, alerting, and fallback gateway logic.',
          warningSigns: 'Rising payment failures or delayed gateway callbacks.',
          contingency: 'Route transactions through a secondary provider.',
        ),
      if (text.contains('kyc') || industry == 'Fintech')
        const RiskItem(
          title: 'KYC bottleneck',
          category: 'Compliance',
          severity: 'High',
          probability: 'Medium probability',
          impact: 'High',
          owner: 'Compliance Lead',
          scenario:
              'Automated identity verification fails and manual review queues grow.',
          exposure:
              'The project relies on onboarding checks before users can transact.',
          mitigation:
              'Define manual review queues and provider failure playbooks.',
          warningSigns: 'Growing backlog of pending verification requests.',
          contingency:
              'Temporarily reduce onboarding volume and trigger manual review.',
        ),
      if (text.contains('refund') || text.contains('checkout'))
        const RiskItem(
          title: 'Refund policy gaps',
          category: 'Customer Experience',
          severity: 'Medium',
          probability: 'High probability',
          impact: 'Medium',
          owner: 'Support Lead',
          scenario: 'Refund edge cases create repeated user complaints.',
          exposure:
              'Checkout and refund flows need clear rules before launch traffic arrives.',
          mitigation:
              'Document refund rules and escalation paths before launch.',
          warningSigns:
              'Repeated support tickets about failed or delayed refunds.',
          contingency:
              'Create a manual refund review queue with approval limits.',
        ),
      const RiskItem(
        title: 'Data privacy',
        category: 'Security',
        severity: 'Critical',
        probability: 'Low probability',
        impact: 'Critical',
        owner: 'Security Lead',
        scenario:
            'Sensitive user data is retained too long or accessed without auditability.',
        exposure:
            'The product stores operational records and user data that need strict controls.',
        mitigation: 'Minimize sensitive fields and enforce audit logging.',
        warningSigns:
            'Unreviewed data access patterns or unclear retention rules.',
        contingency: 'Pause affected workflows and perform incident review.',
      ),
      const RiskItem(
        title: 'Vendor onboarding',
        category: 'Business',
        severity: 'Medium',
        probability: 'Medium probability',
        impact: 'Medium',
        owner: 'Ops Manager',
        scenario: 'Vendors are not ready for launch workflows or payouts.',
        exposure:
            'Launch success depends on external participants completing setup steps.',
        mitigation: 'Create checklist-based onboarding with approval gates.',
        warningSigns: 'Vendors repeatedly fail document or payout setup.',
        contingency: 'Limit launch cohort to verified vendors only.',
      ),
    ];
    final rawScore =
        58 +
        risks.where((risk) => risk.severity == 'Critical').length * 10 +
        risks.where((risk) => risk.impact == 'High').length * 5 +
        (mode == 'Executive' ? 8 : 0) +
        risks.length;
    final score = rawScore.clamp(0, 96);
    final level = score >= 85
        ? 'Critical'
        : score >= 68
        ? 'High Attention'
        : score >= 40
        ? 'Moderate'
        : 'Low';
    return RiskReport(
      id: '${createdAt.microsecondsSinceEpoch}-$projectName',
      projectName: projectName,
      description: description,
      industry: industry,
      mode: mode,
      score: score,
      level: level,
      summary:
          '$projectName shows ${level.toLowerCase()} risk across ${risks.length} areas. The biggest launch exposure is ${risks.first.title.toLowerCase()}, followed by operational readiness and data controls.',
      brief: ExecutiveBrief(
        topConcern:
            '${risks.first.title} is the first area to validate before launch.',
        nextStep:
            'Run a focused review on ${risks.first.owner.toLowerCase()} actions and assign deadlines.',
        decision:
            'Confirm owners and approval gates for all high-severity risks.',
      ),
      risks: risks,
      createdAt: createdAt,
      source: 'fallback',
    );
  }

  factory RiskReport.fromBackendJson(
    Map<String, dynamic> json, {
    required String description,
    required String industry,
    required String mode,
    required DateTime createdAt,
  }) {
    final briefJson = json['executive_brief'] as Map<String, dynamic>;
    final riskJson = json['risks'] as List<dynamic>;
    return RiskReport(
      id: '${createdAt.microsecondsSinceEpoch}-${json['project_name']}',
      projectName: json['project_name'] as String,
      description: description,
      industry: industry,
      mode: mode,
      score: json['score'] as int,
      level: json['level'] as String,
      summary: json['summary'] as String,
      brief: ExecutiveBrief(
        topConcern: briefJson['top_concern'] as String,
        nextStep: briefJson['recommended_next_step'] as String,
        decision: briefJson['leadership_decision_needed'] as String,
      ),
      risks: riskJson.map((item) {
        final map = item as Map<String, dynamic>;
        return RiskItem(
          title: map['title'] as String,
          category: map['category'] as String,
          severity: map['severity'] as String,
          probability: '${map['probability']} probability',
          impact: map['impact'] as String? ?? 'Medium',
          owner: map['owner'] as String,
          scenario: map['scenario'] as String? ?? 'Review launch scenario.',
          exposure:
              map['why_this_project_is_exposed'] as String? ??
              'Exposure is based on the provided project description.',
          mitigation: map['mitigation'] as String,
          warningSigns: map['warning_signs'] as String,
          contingency: map['contingency'] as String,
        );
      }).toList(),
      createdAt: createdAt,
      source: json['source'] as String? ?? 'gemini',
      fallbackReason: json['fallback_reason'] as String?,
    );
  }

  factory RiskReport.fromJson(Map<String, dynamic> json) {
    return RiskReport(
      id: json['id'] as String,
      projectName: json['projectName'] as String,
      description: json['description'] as String,
      industry: json['industry'] as String,
      mode: json['mode'] as String,
      score: json['score'] as int,
      level: json['level'] as String,
      summary: json['summary'] as String,
      brief: ExecutiveBrief.fromJson(json['brief'] as Map<String, dynamic>),
      risks: (json['risks'] as List<dynamic>)
          .map((item) => RiskItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      source: json['source'] as String? ?? 'fallback',
      fallbackReason: json['fallbackReason'] as String?,
    );
  }

  final String id;
  final String projectName;
  final String description;
  final String industry;
  final String mode;
  final int score;
  final String level;
  final String summary;
  final ExecutiveBrief brief;
  final List<RiskItem> risks;
  final DateTime createdAt;
  final String source;
  final String? fallbackReason;

  bool get usedFallback => source == 'fallback';

  List<String> get categories {
    return risks.map((risk) => risk.category).toSet().toList()..sort();
  }

  String get createdLabel =>
      '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

  String get briefText =>
      'Executive Brief for $projectName\nTop concern: ${brief.topConcern}\nRecommended next step: ${brief.nextStep}\nLeadership decision needed: ${brief.decision}';

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectName': projectName,
    'description': description,
    'industry': industry,
    'mode': mode,
    'score': score,
    'level': level,
    'summary': summary,
    'brief': brief.toJson(),
    'risks': risks.map((risk) => risk.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'source': source,
    'fallbackReason': fallbackReason,
  };
}

class ExecutiveBrief {
  const ExecutiveBrief({
    required this.topConcern,
    required this.nextStep,
    required this.decision,
  });

  factory ExecutiveBrief.fromJson(Map<String, dynamic> json) {
    return ExecutiveBrief(
      topConcern: json['topConcern'] as String,
      nextStep: json['nextStep'] as String,
      decision: json['decision'] as String,
    );
  }

  final String topConcern;
  final String nextStep;
  final String decision;

  Map<String, dynamic> toJson() => {
    'topConcern': topConcern,
    'nextStep': nextStep,
    'decision': decision,
  };
}

class RiskItem {
  const RiskItem({
    required this.title,
    required this.category,
    required this.severity,
    required this.probability,
    required this.impact,
    required this.owner,
    required this.scenario,
    required this.exposure,
    required this.mitigation,
    required this.warningSigns,
    required this.contingency,
  });

  factory RiskItem.fromJson(Map<String, dynamic> json) {
    return RiskItem(
      title: json['title'] as String,
      category: json['category'] as String,
      severity: json['severity'] as String,
      probability: json['probability'] as String,
      impact: json['impact'] as String? ?? 'Medium',
      owner: json['owner'] as String,
      scenario: json['scenario'] as String? ?? 'Review launch scenario.',
      exposure:
          json['exposure'] as String? ??
          'Exposure is based on the provided project description.',
      mitigation: json['mitigation'] as String,
      warningSigns: json['warningSigns'] as String,
      contingency: json['contingency'] as String,
    );
  }

  final String title;
  final String category;
  final String severity;
  final String probability;
  final String impact;
  final String owner;
  final String scenario;
  final String exposure;
  final String mitigation;
  final String warningSigns;
  final String contingency;

  Map<String, dynamic> toJson() => {
    'title': title,
    'category': category,
    'severity': severity,
    'probability': probability,
    'impact': impact,
    'owner': owner,
    'scenario': scenario,
    'exposure': exposure,
    'mitigation': mitigation,
    'warningSigns': warningSigns,
    'contingency': contingency,
  };
}
