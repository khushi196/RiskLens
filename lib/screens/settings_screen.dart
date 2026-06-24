import 'package:flutter/material.dart';

import '../app_theme.dart';

typedef BackendChecker = Future<bool> Function();

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.apiBaseUrl,
    required this.onTestBackend,
  });

  final String apiBaseUrl;
  final BackendChecker onTestBackend;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var testing = false;

  Future<void> testBackend() async {
    setState(() => testing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final online = await widget.onTestBackend();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(online ? 'Backend is online' : 'Backend is offline'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Backend is offline')),
      );
    } finally {
      if (mounted) setState(() => testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'API connection',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          gap(8),
          Text(
            'FastAPI backend: ${widget.apiBaseUrl}',
            style: const TextStyle(color: AppColors.muted),
          ),
          gap(6),
          const Text(
            'Set production API with --dart-define=API_BASE_URL=https://your-api.onrender.com',
            style: TextStyle(color: AppColors.muted),
          ),
          gap(6),
          const Text(
            'AI provider, Gemini key, CORS, and fallback mode are controlled from backend environment variables.',
            style: TextStyle(color: AppColors.muted),
          ),
          gap(22),
          FilledButton.icon(
            onPressed: testing ? null : testBackend,
            icon: testing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_tethering_rounded),
            label: Text(testing ? 'Testing...' : 'Test backend'),
          ),
        ],
      ),
    );
  }
}
