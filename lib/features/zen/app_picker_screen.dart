import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/app_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/platform/zen_platform.dart';
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.offWhite),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'CHOOSE APPS TO BLOCK',
            style: GoogleFonts.spaceMono(
              fontSize: 16,
              color: AppColors.offWhite,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.neonPink),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.offWhite),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'CHOOSE APPS TO BLOCK',
            style: GoogleFonts.spaceMono(
              fontSize: 16,
              color: AppColors.offWhite,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppColors.offWhite),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loadApps,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.neonPink,
                    foregroundColor: AppColors.offWhite,
                    side: const BorderSide(color: AppColors.offWhite, width: 4),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.offWhite),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'THE ENEMY (Apps to Block)',
          style: GoogleFonts.spaceMono(
            fontSize: 14,
            color: AppColors.offWhite,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Select apps to lock during focus mode. Grant "Usage access" if the list is empty.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: _apps.isEmpty
                ? Center(
                    child: Text(
                      'No supported social apps found on this device.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppColors.mutedForeground),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: _apps.length,
                    itemBuilder: (context, i) {
                      final app = _apps[i];
                      final selected = _selected.contains(app.packageName);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.offWhite, width: 4),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selected.remove(app.packageName);
                                } else {
                                  _selected.add(app.packageName);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  if (app.iconBytes != null)
                                    Image.memory(
                                      app.iconBytes!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.contain,
                                    )
                                  else
                                    const Icon(Icons.apps, color: AppColors.offWhite, size: 40),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      app.label,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: AppColors.offWhite,
                                      ),
                                    ),
                                  ),
                                  _ToggleSwitch(
                                    value: selected,
                                    onTap: () {
                                      setState(() {
                                        if (selected) {
                                          _selected.remove(app.packageName);
                                        } else {
                                          _selected.add(app.packageName);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () async {
                        await ref
                            .read(zenSessionProvider.notifier)
                            .setBlockedPackages(_selected.toList());
                        if (context.mounted) context.pop();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: _selected.isEmpty ? AppColors.muted : AppColors.neonPink,
                  foregroundColor: AppColors.offWhite,
                  disabledBackgroundColor: AppColors.muted,
                  disabledForegroundColor: AppColors.disabled,
                  minimumSize: const Size(double.infinity, 56),
                  side: BorderSide(
                    color: _selected.isEmpty ? AppColors.disabled : AppColors.offWhite,
                    width: 4,
                  ),
                ),
                child: Text(
                  'Done (${_selected.length} apps selected)',
                  style: GoogleFonts.spaceMono(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  const _ToggleSwitch({required this.value, required this.onTap});

  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 32,
        decoration: BoxDecoration(
          color: value ? AppColors.neonCyan : AppColors.switchBg,
          border: Border.all(color: AppColors.offWhite, width: 4),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.offWhite, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
