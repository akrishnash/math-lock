import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/models/app_info.dart';
import '../../core/platform/zen_platform.dart';
import '../../core/utils/app_log.dart' as app_log;
import '../auth/auth_state.dart';
import '../settings/settings_state.dart';
import 'intervention_screen.dart';
import 'zen_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    app_log.log('Home', 'initState: will check pending unlock after delay');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      await _checkPendingUnlockIntent(from: 'initState');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    app_log.log('Home', 'lifecycle: $state');
    if (state == AppLifecycleState.resumed) {
      _checkPendingUnlockIntent(from: 'resumed');
    }
  }

  Future<void> _checkPendingUnlockIntent({required String from}) async {
    if (!mounted) return;
    app_log.log('Home', 'checkPendingUnlockIntent(from: $from)');
    final pending = await ZenPlatform.getPendingUnlockIntent();
    app_log.log('Home', 'getPendingUnlockIntent() => ${pending != null ? "data for ${pending["packageName"]}" : "null"}');
    if (!mounted) return;
    if (pending != null) {
      final packageName = pending['packageName'] as String? ?? '';
      final appLabel = pending['appLabel'] as String? ?? packageName;
      final remainingSeconds = pending['remainingSeconds'] is int
          ? pending['remainingSeconds'] as int
          : (pending['remainingSeconds'] is num
              ? (pending['remainingSeconds'] as num).toInt()
              : 0);
      final rewardMinutes = pending['rewardMinutes'] is int
          ? pending['rewardMinutes'] as int
          : (pending['rewardMinutes'] is num
              ? (pending['rewardMinutes'] as num).toInt()
              : ref.read(settingsProvider).rewardDurationMinutes);
      final timesUp = pending['timesUp'] == true;

      app_log.log('Home', 'navigating to /intervention (timesUp=$timesUp)');
      context.go(
        '/intervention',
        extra: InterventionScreenArgs(
          packageName: packageName,
          appLabel: appLabel,
          remainingSeconds: remainingSeconds,
          rewardMinutes: rewardMinutes,
          timesUp: timesUp,
        ),
      );
      return;
    }
    // No pending unlock: if not authenticated, send to login
    final user = ref.read(authStateProvider).valueOrNull;
    final skipped = ref.read(authSkippedProvider);
    if (user == null && !skipped && mounted) {
      app_log.log('Home', 'no pending intent, not auth -> /login');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    app_log.log('Home', 'build: zenOn=${ref.read(zenSessionProvider).isZenOn}');
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'EARN YOUR SCREEN',
          style: GoogleFonts.spaceMono(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.offWhite,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.offWhite),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined, color: AppColors.offWhite),
            onPressed: () => context.push('/stats'),
          ),
        ],
      ),
      body: zen.isZenOn ? _buildZenOnContent(zen, settings) : _buildZenOffContent(zen, settings),
    );
  }

  Widget _buildZenOnContent(ZenSessionState zen, SettingsState settings) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _ZenOnCard(
          sessionEndMillis: zen.sessionEndMillis!,
          blockedCount: zen.blockedPackages.length,
          onTurnOff: () async {
            app_log.log('Home', 'Turn off Zen tapped');
            try {
              await ZenPlatform.stopZenMonitoring();
              await ref.read(zenSessionProvider.notifier).stopZen();
              app_log.log('Home', 'Zen turned off OK');
              if (mounted) setState(() {});
            } catch (e, st) {
              app_log.logError('Home', 'Turn off Zen failed', e, st);
            }
          },
        ),
        const SizedBox(height: 24),
        _BlockedAppsList(packageNames: zen.blockedPackages),
      ],
    );
  }

  bool _canStartLockdown(ZenSessionState zen, SettingsState settings, int hours, int minutes) {
    final hasDuration = hours > 0 || minutes > 0;
    final fullLock = settings.lockMode == LockMode.full;
    final hasApps = zen.blockedPackages.isNotEmpty;
    return hasDuration && (fullLock || hasApps);
  }

  Widget _buildZenOffContent(ZenSessionState zen, SettingsState settings) {
    final totalMinutes = settings.sessionDurationMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Text(
          'LOCK DURATION',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.offWhite,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _DurationColumn(
              value: hours,
              label: 'HOURS',
              min: 0,
              max: 23,
              step: 1,
              onChanged: (v) {
                final m = (v * 60) + (totalMinutes % 60);
                ref.read(settingsProvider.notifier).setSessionDurationMinutes(m.clamp(0, 24 * 60 - 1));
              },
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Text(
                ':',
                style: GoogleFonts.spaceMono(
                  fontSize: 72,
                  color: AppColors.neonPink,
                ),
              ),
            ),
            _DurationColumn(
              value: minutes,
              label: 'MINUTES',
              min: 0,
              max: 59,
              step: 5,
              onChanged: (v) {
                final m = (totalMinutes ~/ 60) * 60 + v;
                ref.read(settingsProvider.notifier).setSessionDurationMinutes(m);
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'LOCK MODE',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.offWhite,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _LockModeChip(
              label: 'Block selected apps',
              selected: settings.lockMode == LockMode.apps,
              onTap: () => ref.read(settingsProvider.notifier).setLockMode(LockMode.apps),
            ),
            const SizedBox(width: 12),
            _LockModeChip(
              label: 'Lock entire phone',
              selected: settings.lockMode == LockMode.full,
              onTap: () => ref.read(settingsProvider.notifier).setLockMode(LockMode.full),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'THE ENEMY (Apps to Block)',
          style: GoogleFonts.spaceMono(
            fontSize: 14,
            color: AppColors.offWhite,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.push('/app-picker'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.offWhite, width: 4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  zen.blockedPackages.isEmpty
                      ? 'Select apps to block'
                      : '${zen.blockedPackages.length} app(s) selected',
                  style: GoogleFonts.inter(color: AppColors.offWhite),
                ),
                const Icon(Icons.chevron_right, color: AppColors.offWhite),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _canStartLockdown(zen, settings, hours, minutes) ? () async {
                    final sessionMinutes = (hours * 60) + minutes;
                    if (sessionMinutes <= 0) return;
                    final allowed = await _ensurePermissions(context, settings);
                    if (!allowed || !mounted) return;
                    await ref.read(settingsProvider.notifier).setSessionDurationMinutes(sessionMinutes);
                    await ref.read(zenSessionProvider.notifier).startZen(
                          sessionDurationMinutes: sessionMinutes,
                          blockedPackageNames: zen.blockedPackages,
                        );
                    final sessionEnd = ref.read(zenSessionProvider).sessionEndMillis;
                    if (sessionEnd != null) {
                      await ZenPlatform.startZenMonitoring(
                        blockedPackageNames: zen.blockedPackages,
                        sessionEndMillis: sessionEnd,
                        allowReopenWithinWindow: settings.allowReopenWithinWindow,
                        fullLock: settings.lockMode == LockMode.full,
                      );
                    }
                    if (mounted) setState(() {});
                  } : null,
            style: FilledButton.styleFrom(
              backgroundColor: !_canStartLockdown(zen, settings, hours, minutes)
                  ? AppColors.muted
                  : AppColors.neonPink,
              foregroundColor: AppColors.offWhite,
              padding: const EdgeInsets.symmetric(vertical: 24),
              side: BorderSide(
                color: !_canStartLockdown(zen, settings, hours, minutes)
                    ? AppColors.disabled
                    : AppColors.offWhite,
                width: 4,
              ),
            ),
            child: Text(
              'INITIATE LOCKDOWN',
              style: GoogleFonts.spaceMono(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _SelectedAppsPreview(packageNames: zen.blockedPackages),
      ],
    );
  }

  /// Checks all required permissions at once. Shows a single dialog listing every
  /// missing permission, then opens the first one's settings page.
  Future<bool> _ensurePermissions(BuildContext context, SettingsState settings) async {
    final usage = await ZenPlatform.hasUsageStatsPermission();
    final overlay = await ZenPlatform.hasOverlayPermission();
    final needsNotif = settings.lockMode == LockMode.apps;
    final notification = needsNotif ? await ZenPlatform.hasNotificationListenerPermission() : true;

    if (usage && overlay && notification) return true;

    final missing = <_PermItem>[];
    if (!usage) {
      missing.add(_PermItem(
        icon: Icons.query_stats_outlined,
        title: 'Usage Access',
        description: 'Detects when you open a blocked app.',
        onGrant: ZenPlatform.openUsageAccessSettings,
      ));
    }
    if (!overlay) {
      missing.add(_PermItem(
        icon: Icons.layers_outlined,
        title: 'Display Over Other Apps',
        description: 'Shows the focus screen on top of blocked apps.',
        onGrant: ZenPlatform.openOverlaySettings,
      ));
    }
    if (!notification) {
      missing.add(_PermItem(
        icon: Icons.notifications_off_outlined,
        title: 'Notification Access',
        description: 'Hides notifications from blocked apps during focus.',
        onGrant: ZenPlatform.openNotificationListenerSettings,
      ));
    }

    if (!context.mounted) return false;
    final granted = missing.length;
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          '$granted permission${granted > 1 ? 's' : ''} needed',
          style: GoogleFonts.spaceMono(color: AppColors.offWhite, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < missing.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.neonPink.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.neonPink, width: 1),
                    ),
                    child: Icon(missing[i].icon, color: AppColors.neonPink, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          missing[i].title,
                          style: GoogleFonts.spaceMono(
                            color: AppColors.offWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          missing[i].description,
                          style: GoogleFonts.inter(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (missing.length > 1) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  border: Border.all(color: AppColors.disabled, width: 1),
                ),
                child: Text(
                  'You\'ll be guided to grant each permission one at a time.',
                  style: GoogleFonts.inter(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Later', style: GoogleFonts.inter(color: AppColors.mutedForeground)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.neonPink,
              side: const BorderSide(color: AppColors.offWhite, width: 2),
            ),
            child: Text(
              missing.length > 1 ? 'Grant (1 of $granted)' : 'Open Settings',
              style: GoogleFonts.inter(color: AppColors.offWhite),
            ),
          ),
        ],
      ),
    );

    if (open == true) await missing.first.onGrant();
    return false;
  }
}

class _PermItem {
  const _PermItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onGrant,
  });

  final IconData icon;
  final String title;
  final String description;
  final Future<void> Function() onGrant;
}

class _BlockedAppsList extends StatelessWidget {
  const _BlockedAppsList({required this.packageNames});

  final List<String> packageNames;

  @override
  Widget build(BuildContext context) {
    if (packageNames.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Blocked apps (${packageNames.length})',
          style: GoogleFonts.spaceMono(
            fontSize: 14,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<AppInfo>>(
          future: ZenPlatform.getInstalledApps(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: AppColors.neonPink)),
              );
            }
            final apps = snapshot.data!;
            final byPackage = {for (final a in apps) a.packageName: a};
            return Column(
              children: packageNames.map((pkg) {
                final app = byPackage[pkg];
                final label = app?.label ?? pkg;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.offWhite, width: 4),
                  ),
                  child: Row(
                    children: [
                      if (app?.iconBytes != null)
                        Image.memory(
                          app!.iconBytes!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        )
                      else
                        const Icon(Icons.apps, color: AppColors.offWhite, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: GoogleFonts.inter(color: AppColors.offWhite),
                        ),
                      ),
                      const Icon(Icons.block, color: AppColors.neonPink, size: 24),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SelectedAppsPreview extends StatelessWidget {
  const _SelectedAppsPreview({required this.packageNames});

  final List<String> packageNames;

  @override
  Widget build(BuildContext context) {
    if (packageNames.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<AppInfo>>(
      future: ZenPlatform.getInstalledApps(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final apps = snapshot.data!;
        final byPackage = {for (final a in apps) a.packageName: a};
        final selectedApps = packageNames
            .map((p) => byPackage[p])
            .whereType<AppInfo>()
            .toList();
        if (selectedApps.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedApps.map((app) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.offWhite, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (app.iconBytes != null)
                        Image.memory(
                          app.iconBytes!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        )
                      else
                        const Icon(Icons.apps, color: AppColors.offWhite, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        app.label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.offWhite,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _LockModeChip extends StatelessWidget {
  const _LockModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.neonPink : AppColors.surface,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? AppColors.neonPink : AppColors.offWhite,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.offWhite,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DurationColumn extends StatelessWidget {
  const _DurationColumn({
    required this.value,
    required this.label,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final int value;
  final String label;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DurationButton(
          icon: Icons.keyboard_arrow_up,
          onPressed: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
        ),
        const SizedBox(height: 16),
        Text(
          value.toString().padLeft(2, '0'),
          style: GoogleFonts.spaceMono(
            fontSize: 72,
            color: AppColors.offWhite,
          ),
        ),
        const SizedBox(height: 16),
        _DurationButton(
          icon: Icons.keyboard_arrow_down,
          onPressed: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.offWhite,
          ),
        ),
      ],
    );
  }
}

class _DurationButton extends StatelessWidget {
  const _DurationButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(
              color: onPressed != null ? AppColors.offWhite : AppColors.disabled,
              width: 4,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.offWhite,
            size: 32,
          ),
        ),
      ),
    );
  }
}

class _ZenOnCard extends StatelessWidget {
  const _ZenOnCard({
    required this.sessionEndMillis,
    required this.blockedCount,
    required this.onTurnOff,
  });

  final int sessionEndMillis;
  final int blockedCount;
  final VoidCallback onTurnOff;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.offWhite, width: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neonPink.withValues(alpha: 0.3),
                  border: Border.all(color: AppColors.offWhite, width: 2),
                ),
                child: const Icon(
                  Icons.self_improvement,
                  color: AppColors.neonPink,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Focus mode is on',
                      style: GoogleFonts.spaceMono(
                        fontSize: 20,
                        color: AppColors.offWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Until ${_formatTime(sessionEndMillis)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTurnOff,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.neonPink,
                foregroundColor: AppColors.offWhite,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.offWhite, width: 4),
              ),
              child: const Text('Turn off focus mode'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    final h = d.hour;
    final m = d.minute;
    return '${h > 12 ? h - 12 : (h == 0 ? 12 : h)}:${m.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}';
  }
}
