import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:risk_ai/main.dart';
import 'package:risk_ai/models/risk_report.dart';
import 'package:risk_ai/services/mock_risk_generator.dart';

void main() {
  testWidgets('generates report and shows it in History screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(const RiskLensApp(generator: MockRiskGenerator()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('project-name-field')),
      'Retail Checkout',
    );
    await tester.enterText(
      find.byKey(const Key('project-description-field')),
      'A web checkout with payments, coupons, vendor settlement, and refunds.',
    );

    await tester.tap(find.byKey(const Key('generate-button')));
    await tester.pump();
    expect(find.text('Analyzing project risk'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Retail Checkout'), findsWidgets);
    expect(find.text('Refund policy gaps'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Saved generated reports'), findsOneWidget);
    expect(find.text('Retail Checkout'), findsOneWidget);
  });

  testWidgets('export report button exports the current report', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    RiskReport? exportedReport;
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(
      RiskLensApp(
        generator: const MockRiskGenerator(),
        exporter: (report) async => exportedReport = report,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('project-name-field')),
      'Ops AI',
    );
    await tester.enterText(
      find.byKey(const Key('project-description-field')),
      'AI workflow with vendor onboarding and reporting.',
    );
    await tester.tap(find.byKey(const Key('generate-button')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.text('Export report'));
    await tester.pumpAndSettle();

    expect(exportedReport?.projectName, 'Ops AI');
    expect(find.text('Report exported'), findsOneWidget);
  });

  testWidgets(
    'delete report asks for confirmation before removing history item',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(
        const RiskLensApp(generator: MockRiskGenerator()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('project-name-field')),
        'Vendor Portal',
      );
      await tester.enterText(
        find.byKey(const Key('project-description-field')),
        'Vendor onboarding, payouts, documents, and admin reviews.',
      );
      await tester.tap(find.byKey(const Key('generate-button')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete report'));
      await tester.pumpAndSettle();
      expect(find.text('Delete report?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Generated reports will appear here after you run an analysis.',
        ),
        findsOneWidget,
      );
      expect(find.text('Report deleted'), findsOneWidget);
    },
  );

  testWidgets('new analysis clears the previous form values', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(const RiskLensApp(generator: MockRiskGenerator()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('project-name-field')),
      'Old Launch',
    );
    await tester.enterText(
      find.byKey(const Key('project-description-field')),
      'Payments and refunds.',
    );
    await tester.tap(find.byKey(const Key('generate-button')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.text('New analysis'));
    await tester.pumpAndSettle();

    final projectField = tester.widget<TextField>(
      find.byKey(const Key('project-name-field')),
    );
    final descriptionField = tester.widget<TextField>(
      find.byKey(const Key('project-description-field')),
    );
    expect(projectField.controller?.text, isEmpty);
    expect(descriptionField.controller?.text, isEmpty);
  });

  testWidgets('settings button can test backend connectivity', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(
      RiskLensApp(
        generator: const MockRiskGenerator(),
        backendChecker: () async => true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('API connection'), findsOneWidget);

    await tester.tap(find.text('Test backend'));
    await tester.pumpAndSettle();

    expect(find.text('Backend is online'), findsOneWidget);
  });
}
