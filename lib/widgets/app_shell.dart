import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../models/risk_report.dart';
import '../screens/dashboard_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/settings_screen.dart';
import '../services/local_report_storage.dart';
import '../services/report_exporter.dart';
import '../services/risk_api_service.dart';

Future<bool> checkDefaultBackend() => RiskApiService().checkHealth();

class AppShell extends StatefulWidget {
  AppShell({
    super.key,
    required this.storage,
    RiskGenerator? generator,
    RiskReportExporter? exporter,
    BackendChecker? backendChecker,
    String? apiBaseUrl,
  }) : generator = generator ?? RiskApiService(),
       exporter = exporter ?? exportRiskReport,
       backendChecker = backendChecker ?? checkDefaultBackend,
       apiBaseUrl = apiBaseUrl ?? RiskApiService.defaultBaseUrl;

  final LocalReportStorage storage;
  final RiskGenerator generator;
  final RiskReportExporter exporter;
  final BackendChecker backendChecker;
  final String apiBaseUrl;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final projectController = TextEditingController(text: 'Fintech Wallet');
  final descriptionController = TextEditingController(
    text:
        'A digital wallet app with KYC onboarding, peer payments, rewards, and vendor settlement flows.',
  );
  final steps = const [
    'Mapping assumptions',
    'Checking operational gaps',
    'Estimating severity',
    'Preparing mitigation plan',
  ];

  var selectedView = AppView.home;
  var industry = 'Fintech';
  var mode = 'Executive';
  var loadingStep = 'Mapping assumptions';
  String? error;
  RiskReport? currentReport;
  List<RiskReport> reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    projectController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    final loaded = await widget.storage.loadReports();
    if (!mounted) return;
    setState(() {
      reports = loaded;
      currentReport ??= loaded.isEmpty ? null : loaded.first;
    });
  }

  Future<void> generateReport() async {
    final projectName = projectController.text.trim();
    final description = descriptionController.text.trim();
    if (projectName.isEmpty) {
      setState(() => error = 'Add a project name first');
      return;
    }
    if (description.isEmpty) {
      setState(() => error = 'Add a project description first');
      return;
    }

    setState(() {
      error = null;
      selectedView = AppView.loading;
      loadingStep = steps.first;
    });

    for (final step in steps) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      setState(() => loadingStep = step);
    }

    try {
      final report = await widget.generator.generate(
        projectName: projectName,
        description: description,
        industry: industry,
        mode: mode,
      );
      await widget.storage.saveReport(report);
      final loaded = await widget.storage.loadReports();
      if (!mounted) return;
      setState(() {
        reports = loaded;
        currentReport = report;
        selectedView = AppView.dashboard;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        selectedView = AppView.home;
        error =
            'Could not reach the backend. Make sure FastAPI is running on 127.0.0.1:8000.';
      });
    }
  }

  Future<void> deleteReport(RiskReport report) async {
    await widget.storage.deleteReport(report.id);
    final loaded = await widget.storage.loadReports();
    if (!mounted) return;
    setState(() {
      reports = loaded;
      if (currentReport?.id == report.id) {
        currentReport = loaded.isEmpty ? null : loaded.first;
      }
    });
  }

  Future<void> confirmDeleteReport(RiskReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete report?'),
          content: Text('Remove ${report.projectName} from saved history?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    await deleteReport(report);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Report deleted')));
  }

  void openReport(RiskReport report) {
    setState(() {
      currentReport = report;
      projectController.text = report.projectName;
      descriptionController.text = report.description;
      industry = report.industry;
      mode = report.mode;
      selectedView = AppView.dashboard;
    });
  }

  void startNewAnalysis() {
    setState(() {
      selectedView = AppView.home;
      currentReport = null;
      error = null;
      projectController.clear();
      descriptionController.clear();
      industry = 'Fintech';
      mode = 'Executive';
    });
  }

  Future<void> copyBrief() async {
    final report = currentReport;
    if (report == null) return;
    await Clipboard.setData(ClipboardData(text: report.briefText));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Executive brief copied')));
  }

  Future<void> exportCurrentReport() async {
    final report = currentReport;
    if (report == null) return;
    try {
      await widget.exporter(report);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report exported')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not export report')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bg, AppColors.bg2],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 950;
              final content = SingleChildScrollView(
                padding: EdgeInsets.all(compact ? 20 : 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (compact) ...[
                      const _Brand(),
                      gap(),
                      _CompactNav(
                        selectedView: selectedView,
                        onSelect: setView,
                      ),
                      gap(),
                    ] else
                      _PageHeader(
                        selectedView: selectedView,
                        onNew: startNewAnalysis,
                      ),
                    bodyForView(),
                  ],
                ),
              );
              if (compact) return content;
              return Row(
                children: [
                  _Sidebar(
                    selectedView: selectedView,
                    reportCount: reports.length,
                    onSelect: setView,
                  ),
                  Expanded(child: content),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void setView(AppView view) {
    if (view == AppView.dashboard && currentReport == null) {
      setState(() => selectedView = AppView.home);
      return;
    }
    setState(() => selectedView = view);
  }

  Widget bodyForView() {
    return switch (selectedView) {
      AppView.home => HomeScreen(
        projectController: projectController,
        descriptionController: descriptionController,
        industry: industry,
        mode: mode,
        error: error,
        onIndustryChanged: (value) => setState(() => industry = value),
        onModeChanged: (value) => setState(() => mode = value),
        onGenerate: generateReport,
      ),
      AppView.loading => LoadingScreen(currentStep: loadingStep, steps: steps),
      AppView.dashboard =>
        currentReport == null
            ? HomeScreen(
                projectController: projectController,
                descriptionController: descriptionController,
                industry: industry,
                mode: mode,
                error: error,
                onIndustryChanged: (value) => setState(() => industry = value),
                onModeChanged: (value) => setState(() => mode = value),
                onGenerate: generateReport,
              )
            : DashboardScreen(
                report: currentReport!,
                onCopyBrief: copyBrief,
                onExportReport: exportCurrentReport,
              ),
      AppView.history => HistoryScreen(
        reports: reports,
        onOpen: openReport,
        onDelete: confirmDeleteReport,
      ),
      AppView.settings => SettingsScreen(
        apiBaseUrl: widget.apiBaseUrl,
        onTestBackend: widget.backendChecker,
      ),
    };
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedView,
    required this.reportCount,
    required this.onSelect,
  });

  final AppView selectedView;
  final int reportCount;
  final ValueChanged<AppView> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(20),
      decoration: panelDecoration(radius: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Brand(),
          gap(34),
          for (final view in AppView.values.where(
            (view) => view != AppView.loading,
          ))
            _NavItem(
              view: view,
              active: selectedView == view,
              onTap: () => onSelect(view),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: panelDecoration(color: AppColors.panel2, radius: 22),
            child: Text(
              'Reports saved: $reportCount',
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [AppColors.cyan, AppColors.violet],
            ),
          ),
          child: const Icon(Icons.flag_rounded, color: Colors.black),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'RiskLens',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.selectedView, required this.onNew});

  final AppView selectedView;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedView.title,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
            ),
          ),
          FilledButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New analysis'),
          ),
        ],
      ),
    );
  }
}

class _CompactNav extends StatelessWidget {
  const _CompactNav({required this.selectedView, required this.onSelect});

  final AppView selectedView;
  final ValueChanged<AppView> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final view in AppView.values.where(
          (view) => view != AppView.loading,
        ))
          ChoiceChip(
            selected: selectedView == view,
            label: Text(view.label),
            onSelected: (_) => onSelect(view),
          ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.view,
    required this.active,
    required this.onTap,
  });

  final AppView view;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: active ? AppColors.cyan.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? AppColors.cyan.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                view.icon,
                size: 20,
                color: active ? AppColors.cyan : AppColors.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  view.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? AppColors.text : AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AppView {
  home('Home', 'Home', Icons.auto_awesome_rounded),
  loading('Loading', 'Loading', Icons.radar_rounded),
  dashboard('Dashboard', 'Dashboard', Icons.insert_chart_outlined_rounded),
  history('History', 'History', Icons.history_rounded),
  settings('Settings', 'Settings', Icons.settings_outlined);

  const AppView(this.label, this.title, this.icon);
  final String label;
  final String title;
  final IconData icon;
}
