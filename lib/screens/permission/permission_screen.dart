import 'package:flutter/material.dart';

import '../../services/permission_service.dart';
import '../home/main_shell.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> with WidgetsBindingObserver {
  bool _isPermanentlyDenied = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recheckPermission();
  }

  Future<void> _recheckPermission() async {
    final granted = await PermissionService.hasAudioPermission();
    if (granted && mounted) _goToApp();
  }

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);
    final status = await PermissionService.requestAudioPermission();
    if (!mounted) return;

    if (status.isGranted) {
      _goToApp();
      return;
    }
    setState(() {
      _requesting = false;
      _isPermanentlyDenied = status.isPermanentlyDenied;
    });
  }

  void _goToApp() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary.withValues(alpha: 0.12)),
                child: Icon(Icons.library_music_rounded, size: 54, color: scheme.primary),
              ),
              const SizedBox(height: 32),
              Text('Access your music', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Zenova needs permission to see the audio files stored on your phone so it can build your library. '
                'Everything stays on this device — nothing is ever uploaded.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
              ),
              const Spacer(flex: 4),
              if (_isPermanentlyDenied) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: scheme.errorContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: scheme.error),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Permission was denied. You can turn it on from your device Settings.', style: theme.textTheme.bodySmall)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: () => PermissionService.openSettings(), child: const Text('Open App Settings')),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _requesting ? null : _requestPermission,
                    child: _requesting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                        : const Text('Grant Access'),
                  ),
                ),
              const SizedBox(height: 10),
              TextButton(onPressed: _goToApp, child: Text('Not now', style: TextStyle(color: scheme.onSurfaceVariant))),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
