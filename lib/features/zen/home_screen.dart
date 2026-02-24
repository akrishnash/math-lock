import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform/zen_platform.dart';
import '../settings/settings_state.dart';
import 'zen_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingUnlockIntent());
  }

  Future<void> _checkPendingUnlockIntent() async {
    if (!mounted) return;
    final pending = await ZenPlatform.getPendingUnlockIntent();
    if (!mounted || pending == null) return;
    context.go('/block', extra: pending);
  }

  @override
  Widget build(BuildContext context) {
    final zen = ref.watch(zenSessionProvider);
    final settings = ref.watch(settingsProvider);
    if (zen.sessionEndMillis != null &&
        zen.sessionEndMillis! < DateTime.now().millisecondsSinceEpoch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ZenPlatform.stopZenMonitoring();
        ref.read(zenSessionProvider.notifier).stopZen();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zen Mode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => context.push('/stats'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          _ZenCard(
            isOn: zen.isZenOn,
            sessionEndMillis: zen.sessionEndMillis,
            blockedCount: zen.blockedPackages.length,
            onTurnOn: () => context.push('/app-picker'),
            onTurnOff: () async {
              await ZenPlatform.stopZenMonitoring();
              ref.read(zenSessionProvider.notifier).stopZen();
            },
          ),
          const SizedBox(height: 24),
          if (zen.isZenOn && zen.blockedPackages.isNotEmpty) ...[
            Text(
              'Blocked apps (${zen.blockedPackages.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            ...zen.blockedPackages.map((p) => ListTile(
                  leading: const Icon(Icons.block),
                  title: Text(p),
                  dense: true,
                )),
            const SizedBox(height: 24),
          ],
          _PermissionCard(settings: settings),
        ],
      ),
    );
  }
}

class _ZenCard extends StatelessWidget {
  const _ZenCard({
    required this.isOn,
    required this.sessionEndMillis,
    required this.blockedCount,
    required this.onTurnOn,
    required this.onTurnOff,
  });

  final bool isOn;
  final int? sessionEndMillis;
  final int blockedCount;
  final VoidCallback onTurnOn;
  final VoidCallback onTurnOff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOn
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isOn ? Icons.self_improvement : Icons.self_improvement_outlined,
                    color: isOn
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOn ? 'Zen mode is on' : 'Zen mode',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      if (isOn && sessionEndMillis != null)
                        Text(
                          'Until ${_formatTime(sessionEndMillis!)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      else if (!isOn)
                        Text(
                          'Block distractions and focus',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isOn ? onTurnOff : onTurnOn,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(isOn ? 'Turn off Zen mode' : 'Turn on Zen mode'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    final h = d.hour;
    final m = d.minute;
    return '${h > 12 ? h - 12 : h}:${m.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}';
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.settings});

  final SettingsState settings;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _PermissionRow(
              label: 'Usage access',
              onTap: () => ZenPlatform.openUsageAccessSettings(),
            ),
            _PermissionRow(
              label: 'Display over other apps',
              onTap: () => ZenPlatform.openOverlaySettings(),
            ),
            _PermissionRow(
              label: 'Notification access',
              onTap: () => ZenPlatform.openNotificationListenerSettings(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
