import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_info.dart';
import '../../core/platform/zen_platform.dart';
import '../settings/settings_state.dart';
import 'zen_state.dart';

class AppPickerScreen extends ConsumerStatefulWidget {
  const AppPickerScreen({super.key});

  @override
  ConsumerState<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends ConsumerState<AppPickerScreen> {
  List<AppInfo> _apps = [];
  final Set<String> _selected = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApps();
    final blocked = ref.read(zenSessionProvider).blockedPackages;
    _selected.addAll(blocked);
  }

  Future<void> _loadApps() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ZenPlatform.getInstalledApps();
      setState(() {
        _apps = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Choose apps to block'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Choose apps to block'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadApps,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose apps to block'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select apps to lock during Zen mode. Grant "Usage access" if the list is empty.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _apps.length,
              itemBuilder: (context, i) {
                final app = _apps[i];
                final selected = _selected.contains(app.packageName);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (_) {
                    setState(() {
                      if (selected) {
                        _selected.remove(app.packageName);
                      } else {
                        _selected.add(app.packageName);
                      }
                    });
                  },
                  title: Text(app.label),
                  subtitle: Text(
                    app.packageName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () async {
                      await ref
                          .read(zenSessionProvider.notifier)
                          .setBlockedPackages(_selected.toList());
                      final settings = ref.read(settingsProvider);
                      await ref.read(zenSessionProvider.notifier).startZen(
                            sessionDurationMinutes:
                                settings.sessionDurationMinutes,
                            blockedPackageNames: _selected.toList(),
                          );
                      final sessionEnd = ref
                          .read(zenSessionProvider)
                          .sessionEndMillis;
                      if (sessionEnd != null) {
                        await ZenPlatform.startZenMonitoring(
                          blockedPackageNames: _selected.toList(),
                          sessionEndMillis: sessionEnd,
                        );
                      }
                      if (context.mounted) context.go('/');
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text('Start Zen mode (${_selected.length} apps)'),
            ),
          ),
        ],
      ),
    );
  }
}
