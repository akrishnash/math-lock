import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/app_info.dart';
import '../../core/platform/zen_platform.dart';
import '../../core/utils/app_log.dart' as app_log;
import '../auth/auth_state.dart';
import '../settings/settings_state.dart';
import 'intervention_screen.dart';
import 'zen_state.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────

const _black = Color(0xFF000000);
const _card = Color(0xFF1C1C1E);
const _cardAlt = Color(0xFF2C2C2E);
const _white = Colors.white;
const _white70 = Color(0xB3FFFFFF);
const _muted = Color(0xFF8E8E93);
const _green = Color(0xFF30D158);
const _red = Color(0xFFFF3B30);
const _separator = Color(0xFF38383A);
const _gradA = Color(0xFFB3FF6E); // lime
const _gradB = Color(0xFF00C9A7); // teal

// ── HomeScreen ─────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int _selectedTab = 0;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  late final AnimationController _orbCtrl;
  late final Animation<double> _orbAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _orbAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      await _checkPendingUnlockIntent(from: 'initState');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _orbCtrl.dispose();
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
      context.go('/intervention', extra: InterventionScreenArgs(
        packageName: packageName,
        appLabel: appLabel,
        remainingSeconds: remainingSeconds,
        rewardMinutes: rewardMinutes,
        timesUp: timesUp,
      ));
      return;
    }
    final user = ref.read(authStateProvider).valueOrNull;
    final skipped = ref.read(authSkippedProvider);
    if (user == null && !skipped && mounted) {
      app_log.log('Home', 'no pending intent, not auth -> /login');
      context.go('/login');
    }
  }

  void _startCountdown(int endMillis) {
    _countdownTimer?.cancel();
    _updateRemaining(endMillis);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateRemaining(endMillis);
    });
  }

  void _updateRemaining(int endMillis) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = ((endMillis - now) / 1000).ceil();
    setState(() => _remainingSeconds = diff.clamp(0, 999999));
  }

  Future<bool> _ensurePermissions(SettingsState settings) async {
    final usage = await ZenPlatform.hasUsageStatsPermission();
    final overlay = await ZenPlatform.hasOverlayPermission();
    final needsNotif = settings.lockMode == LockMode.apps;
    final notification = needsNotif
        ? await ZenPlatform.hasNotificationListenerPermission()
        : true;
    if (usage && overlay && notification) return true;

    final missing = <String>[];
    if (!usage) missing.add('Usage Access');
    if (!overlay) missing.add('Display Over Other Apps');
    if (!notification) missing.add('Notification Access');

    if (!mounted) return false;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Permissions needed',
          style: GoogleFonts.inter(color: _white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          '${missing.join(', ')} ${missing.length > 1 ? 'are' : 'is'} required to block apps.',
          style: GoogleFonts.inter(color: _muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Later', style: GoogleFonts.inter(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Open Settings',
              style: GoogleFonts.inter(color: _gradB, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (go == true) {
      if (!usage) {
        await ZenPlatform.openUsageAccessSettings();
      } else if (!overlay) {
        await ZenPlatform.openOverlaySettings();
      } else {
        await ZenPlatform.openNotificationListenerSettings();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final zen = ref.watch(zenSessionProvider);
    final settings = ref.watch(settingsProvider);

    // Auto-stop expired session
    if (zen.sessionEndMillis != null &&
        zen.sessionEndMillis! < DateTime.now().millisecondsSinceEpoch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ZenPlatform.stopZenMonitoring();
        ref.read(zenSessionProvider.notifier).stopZen();
      });
    }

    // Manage countdown timer
    if (zen.isZenOn && zen.sessionEndMillis != null) {
      if (_countdownTimer == null || !_countdownTimer!.isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startCountdown(zen.sessionEndMillis!);
        });
      }
    } else if (!zen.isZenOn && _countdownTimer != null) {
      _countdownTimer?.cancel();
    }

    // Full-screen active session view
    if (zen.isZenOn) {
      return _ActiveSessionScreen(
        zen: zen,
        settings: settings,
        remainingSeconds: _remainingSeconds,
        onStopZen: () async {
          await ZenPlatform.stopZenMonitoring();
          await ref.read(zenSessionProvider.notifier).stopZen();
          _countdownTimer?.cancel();
          if (mounted) setState(() {});
        },
      );
    }

    return Scaffold(
      backgroundColor: _black,
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _TodayTab(
            orbAnim: _orbAnim,
            onGoToBlocks: () => setState(() => _selectedTab = 1),
          ),
          _BlocksTab(
            zen: zen,
            settings: settings,
            onStartZen: (sessionMinutes, packages) async {
              final allowed = await _ensurePermissions(settings);
              if (!allowed || !mounted) return;
              await ref
                  .read(settingsProvider.notifier)
                  .setSessionDurationMinutes(sessionMinutes);
              await ref.read(zenSessionProvider.notifier).startZen(
                    sessionDurationMinutes: sessionMinutes,
                    blockedPackageNames: packages,
                  );
              final sessionEnd = ref.read(zenSessionProvider).sessionEndMillis;
              if (sessionEnd != null) {
                await ZenPlatform.startZenMonitoring(
                  blockedPackageNames: packages,
                  sessionEndMillis: sessionEnd,
                  allowReopenWithinWindow: settings.allowReopenWithinWindow,
                  fullLock: settings.lockMode == LockMode.full,
                );
              }
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selected: _selectedTab,
        onTap: (i) {
          if (i == 2) {
            context.push('/stats');
            return;
          }
          setState(() => _selectedTab = i);
        },
      ),
    );
  }
}

// ── Active session (full screen, zen ON) ───────────────────────────────────────

class _ActiveSessionScreen extends StatelessWidget {
  const _ActiveSessionScreen({
    required this.zen,
    required this.settings,
    required this.remainingSeconds,
    required this.onStopZen,
  });
  final ZenSessionState zen;
  final SettingsState settings;
  final int remainingSeconds;
  final VoidCallback onStopZen;

  String get _timeStr {
    final h = remainingSeconds ~/ 3600;
    final m = (remainingSeconds % 3600) ~/ 60;
    final s = remainingSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (zen.sessionEndMillis == null) return 0;
    final totalSec = settings.sessionDurationMinutes * 60;
    if (totalSec <= 0) return 0;
    return (1 - (remainingSeconds / totalSec)).clamp(0.0, 1.0);
  }

  String _fmt(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    final h = d.hour;
    final m = d.minute;
    return '${h > 12 ? h - 12 : (h == 0 ? 12 : h)}:${m.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final endMillis = zen.sessionEndMillis ?? DateTime.now().millisecondsSinceEpoch;
    final startMillis = endMillis - (settings.sessionDurationMinutes * 60 * 1000);
    final appCount = zen.blockedPackages.length;

    return Scaffold(
      backgroundColor: _black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF071A2E), Color(0xFF0D2A1A), Color(0xFF000000)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: _white70, size: 30),
                      onPressed: () {},
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Edit Session',
                        style: GoogleFonts.inter(color: _white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Focus Session',
                      style: GoogleFonts.inter(
                        color: _white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Remaining time ',
                          style: GoogleFonts.inter(color: _muted, fontSize: 14),
                        ),
                        Text(
                          _timeStr,
                          style: GoogleFonts.inter(
                            color: _green,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: _white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(_green),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmt(startMillis),
                            style: GoogleFonts.inter(color: _muted, fontSize: 11)),
                        Text(_fmt(endMillis),
                            style: GoogleFonts.inter(color: _muted, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.block_rounded,
                            label: 'BLOCK LIST',
                            value: appCount == 0
                                ? 'Full phone'
                                : '$appCount app${appCount != 1 ? 's' : ''}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.psychology_outlined,
                            label: 'DIFFICULTY',
                            value: settings.problemDifficulty ==
                                    ProblemDifficulty.easy
                                ? 'Easy'
                                : 'Medium',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: _GradientButton(label: 'Snooze', onTap: onStopZen),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Center(
                  child: TextButton(
                    onPressed: onStopZen,
                    child: Text(
                      'Leave Early',
                      style: GoogleFonts.inter(
                        color: _red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: _muted, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        color: _muted, fontSize: 9, letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.inter(
                        color: _white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Today Tab ──────────────────────────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  const _TodayTab({required this.orbAnim, required this.onGoToBlocks});
  final Animation<double> orbAnim;
  final VoidCallback onGoToBlocks;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: _black,
          elevation: 0,
          title: Row(
            children: [
              Text(
                'Math Lock',
                style: GoogleFonts.inter(
                    color: _white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Text('Today',
                  style: GoogleFonts.inter(color: _muted, fontSize: 14)),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: _muted, size: 18),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.ios_share_outlined, color: _muted, size: 22),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: _muted, size: 22),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Glowing orb
              _GlowOrb(animation: orbAnim),
              const SizedBox(height: 8),
              // Metric
              Text(
                '0 sessions',
                style: GoogleFonts.inter(
                  color: _gradA,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'FOCUS TODAY',
                style: GoogleFonts.inter(
                    color: _muted, fontSize: 11, letterSpacing: 1.5),
              ),
              const SizedBox(height: 24),
              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                          child: _StatItem(label: 'SESSIONS\nTODAY', value: '0')),
                      _StatDivider(),
                      Expanded(
                          child:
                              _StatItem(label: 'PROBLEMS\nSOLVED', value: '0')),
                      _StatDivider(),
                      Expanded(
                          child: _StatItem(label: 'DAY\nSTREAK', value: '0')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Block now CTA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _GradientButton(
                  label: '▶  Block Now',
                  onTap: onGoToBlocks,
                ),
              ),
              const SizedBox(height: 20),
              // Tip card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _TipCard(),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  color: _gradA, size: 16),
              const SizedBox(width: 8),
              Text('DID YOU KNOW',
                  style: GoogleFonts.inter(
                      color: _muted, fontSize: 10, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Solving a math problem before opening an app creates a 3–5 second pause that breaks the automatic habit loop.',
            style: GoogleFonts.inter(
                color: _white70, fontSize: 14, height: 1.55),
          ),
        ],
      ),
    );
  }
}

// ── Blocks Tab ─────────────────────────────────────────────────────────────────

class _BlocksTab extends ConsumerStatefulWidget {
  const _BlocksTab({
    required this.zen,
    required this.settings,
    required this.onStartZen,
  });
  final ZenSessionState zen;
  final SettingsState settings;
  final Future<void> Function(int sessionMinutes, List<String> packages)
      onStartZen;

  @override
  ConsumerState<_BlocksTab> createState() => _BlocksTabState();
}

class _BlocksTabState extends ConsumerState<_BlocksTab> {
  bool _starting = false;

  bool get _canStart {
    final totalMinutes = widget.settings.sessionDurationMinutes;
    final fullLock = widget.settings.lockMode == LockMode.full;
    return totalMinutes > 0 &&
        (fullLock || widget.zen.blockedPackages.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final zen = widget.zen;
    final totalMinutes = settings.sessionDurationMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final durationLabel =
        hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: _black,
          elevation: 0,
          title: Text(
            'Blocks',
            style: GoogleFonts.inter(
                color: _white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Session config card
                Container(
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _SessionRow(
                        icon: Icons.timer_outlined,
                        label: 'Duration',
                        value: totalMinutes == 0 ? 'Set duration' : durationLabel,
                        onTap: () => _showDurationSheet(context),
                      ),
                      _RowDivider(),
                      _SessionRow(
                        icon: Icons.apps_rounded,
                        label: 'Apps Blocked',
                        value: zen.blockedPackages.isEmpty
                            ? 'None selected'
                            : '${zen.blockedPackages.length} app${zen.blockedPackages.length != 1 ? 's' : ''}',
                        trailing: zen.blockedPackages.isNotEmpty
                            ? Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                    color: _red, shape: BoxShape.circle),
                              )
                            : null,
                        onTap: () => context.push('/app-picker'),
                      ),
                      _RowDivider(),
                      _SessionRow(
                        icon: Icons.psychology_outlined,
                        label: 'Difficulty',
                        value: settings.problemDifficulty ==
                                ProblemDifficulty.easy
                            ? 'Easy'
                            : 'Medium',
                        onTap: () => _showDifficultySheet(context),
                      ),
                      _RowDivider(),
                      _SessionRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'Lock Mode',
                        value: settings.lockMode == LockMode.full
                            ? 'Full Phone'
                            : 'Selected Apps',
                        onTap: _toggleLockMode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!_canStart)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      settings.lockMode == LockMode.apps &&
                              zen.blockedPackages.isEmpty
                          ? 'Select apps to block, or switch to Full Phone mode.'
                          : 'Set a duration to start.',
                      style: GoogleFonts.inter(color: _muted, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                _GradientButton(
                  label: _starting ? 'Starting…' : '▶  Start Session',
                  onTap: _canStart && !_starting
                      ? () async {
                          setState(() => _starting = true);
                          await widget.onStartZen(
                              totalMinutes, zen.blockedPackages);
                          if (mounted) setState(() => _starting = false);
                        }
                      : null,
                ),
                if (zen.blockedPackages.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    'BLOCKED APPS',
                    style: GoogleFonts.inter(
                        color: _muted, fontSize: 10, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  _AppsPreview(packages: zen.blockedPackages),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _toggleLockMode() {
    final current = widget.settings.lockMode;
    ref.read(settingsProvider.notifier).setLockMode(
        current == LockMode.full ? LockMode.apps : LockMode.full);
  }

  void _showDurationSheet(BuildContext context) {
    final settings = ref.read(settingsProvider);
    int selHours = settings.sessionDurationMinutes ~/ 60;
    int selMinutes = ((settings.sessionDurationMinutes % 60) / 5).round() * 5;
    if (selMinutes >= 60) {
      selHours++;
      selMinutes = 0;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _muted,
                      borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 20),
              Text('Duration',
                  style: GoogleFonts.inter(
                      color: _white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Select how long this session should last.',
                  style: GoogleFonts.inter(color: _muted, fontSize: 13)),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DrumPicker(
                      itemCount: 24,
                      selected: selHours,
                      label: 'hours',
                      onChanged: (v) => setS(() => selHours = v),
                    ),
                    const SizedBox(width: 40),
                    _DrumPicker(
                      itemCount: 12,
                      selected: selMinutes ~/ 5,
                      label: 'minutes',
                      multiplier: 5,
                      onChanged: (v) => setS(() => selMinutes = v * 5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _OutlineButton(
                      label: 'Always On',
                      onTap: () {
                        ref
                            .read(settingsProvider.notifier)
                            .setSessionDurationMinutes(23 * 60 + 59);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GradientButton(
                      label: 'Confirm',
                      onTap: () {
                        final total = selHours * 60 + selMinutes;
                        if (total > 0) {
                          ref
                              .read(settingsProvider.notifier)
                              .setSessionDurationMinutes(total);
                        }
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showDifficultySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: _muted, borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 20),
            Text('Difficulty',
                style: GoogleFonts.inter(
                    color: _white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Harder problems = more friction = less mindless opening.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _DifficultyOption(
              title: 'Easy',
              subtitle: 'Quick unlocks, light friction',
              selected: widget.settings.problemDifficulty ==
                  ProblemDifficulty.easy,
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setProblemDifficulty(ProblemDifficulty.easy);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 10),
            _DifficultyOption(
              title: 'Medium',
              subtitle: 'Longer problems, real pause before opening',
              selected: widget.settings.problemDifficulty ==
                  ProblemDifficulty.medium,
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setProblemDifficulty(ProblemDifficulty.medium);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyOption extends StatelessWidget {
  const _DifficultyOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _green.withValues(alpha: 0.12) : _cardAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? _green : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          color: _white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(color: _muted, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            selected
                ? const Icon(Icons.check_circle_rounded,
                    color: _green, size: 22)
                : Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _muted, width: 1.5)),
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Drum picker ────────────────────────────────────────────────────────────────

class _DrumPicker extends StatefulWidget {
  const _DrumPicker({
    required this.itemCount,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.multiplier = 1,
  });
  final int itemCount;
  final int selected;
  final String label;
  final ValueChanged<int> onChanged;
  final int multiplier;

  @override
  State<_DrumPicker> createState() => _DrumPickerState();
}

class _DrumPickerState extends State<_DrumPicker> {
  late final FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = FixedExtentScrollController(initialItem: widget.selected);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Selection highlight
            Container(
              width: 88,
              height: 48,
              decoration: BoxDecoration(
                color: _white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(
              width: 88,
              height: 156,
              child: ListWheelScrollView.useDelegate(
                controller: _ctrl,
                itemExtent: 48,
                perspective: 0.003,
                diameterRatio: 1.5,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: widget.onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (ctx, i) {
                    if (i < 0 || i >= widget.itemCount) return null;
                    final val = i * widget.multiplier;
                    return Center(
                      child: Text(
                        val.toString().padLeft(2, '0'),
                        style: GoogleFonts.inter(
                          color: _white,
                          fontSize: 30,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    );
                  },
                  childCount: widget.itemCount,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(widget.label,
            style: GoogleFonts.inter(color: _muted, fontSize: 12)),
      ],
    );
  }
}

// ── Session row ────────────────────────────────────────────────────────────────

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: _muted, size: 20),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(color: _white, fontSize: 15))),
            if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
            Text(value,
                style: GoogleFonts.inter(color: _muted, fontSize: 15)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: _muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 50),
      child: Divider(height: 1, thickness: 0.5, color: _separator),
    );
  }
}

// ── Apps preview ───────────────────────────────────────────────────────────────

class _AppsPreview extends StatelessWidget {
  const _AppsPreview({required this.packages});
  final List<String> packages;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppInfo>>(
      future: ZenPlatform.getInstalledApps(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final byPkg = {for (final a in snap.data!) a.packageName: a};
        return Column(
          children: packages.map((pkg) {
            final app = byPkg[pkg];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: _card, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  if (app?.iconBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(app!.iconBytes!,
                          width: 36, height: 36, fit: BoxFit.contain),
                    )
                  else
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: _cardAlt,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.apps, color: _muted, size: 20),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(app?.label ?? pkg,
                        style: GoogleFonts.inter(color: _white, fontSize: 14)),
                  ),
                  const Icon(Icons.block_rounded, color: _red, size: 18),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Bottom nav ─────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selected, required this.onTap});
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _black,
        border: Border(top: BorderSide(color: _separator, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Today',
                selected: selected == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.block_outlined,
                activeIcon: Icons.block_rounded,
                label: 'Blocks',
                selected: selected == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Stats',
                selected: selected == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? activeIcon : icon,
                color: selected ? _white : _muted, size: 26),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? _white : _muted,
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Glow orb ───────────────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (ctx, _) => SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ambient glow
            Container(
              width: 200 * animation.value,
              height: 200 * animation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gradB.withValues(alpha: 0.12 * animation.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Mid glow
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gradB.withValues(alpha: 0.22),
                    _gradA.withValues(alpha: 0.06),
                  ],
                ),
              ),
            ),
            // Core orb
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2ECC8A), Color(0xFF00B4D8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _gradB.withValues(alpha: 0.55 * animation.value),
                    blurRadius: 32,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: Colors.white, size: 34),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared button widgets ──────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(colors: [_gradA, _gradB])
                : null,
            color: enabled ? null : _card,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: enabled ? const Color(0xFF061A0F) : _muted,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: _separator, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
                color: _white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

// ── Stat widgets ───────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
              color: _white, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
              color: _muted, fontSize: 9, letterSpacing: 0.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: _separator);
  }
}
