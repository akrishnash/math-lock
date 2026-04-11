import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/app_info.dart';
import '../../core/platform/zen_platform.dart';
import 'zen_state.dart';

// ── design tokens ─────────────────────────────────────────────────────────────
const _black = Color(0xFF000000);
const _card = Color(0xFF1C1C1E);
const _cardAlt = Color(0xFF2C2C2E);
const _green = Color(0xFF30D158);
const _gradA = Color(0xFFB3FF6E);
const _gradB = Color(0xFF00C9A7);
const _muted = Color(0xFF8E8E93);
const _separator = Color(0xFF38383A);
const _white = Color(0xFFFFFFFF);
const _white60 = Color(0x99FFFFFF);

class AppPickerScreen extends ConsumerStatefulWidget {
  const AppPickerScreen({super.key});

  @override
  ConsumerState<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends ConsumerState<AppPickerScreen> {
  List<AppInfo> _apps = [];
  List<AppInfo> _filtered = [];
  final Set<String> _selected = {};
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApps();
    final blocked = ref.read(zenSessionProvider).blockedPackages;
    _selected.addAll(blocked);
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _apps
          : _apps.where((a) => a.label.toLowerCase().contains(q)).toList();
    });
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
        _filtered = list;
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
    return Scaffold(
      backgroundColor: _black,
      body: SafeArea(
        child: Column(
          children: [
            // ── header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Choose Apps to Block',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balance
                ],
              ),
            ),

            // ── search bar ────────────────────────────────────────────────
            if (!_loading && _error == null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(fontSize: 15, color: _white),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      hintText: 'Search apps...',
                      hintStyle: GoogleFonts.inter(fontSize: 15, color: _muted),
                      prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 20),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),

              // ── selected count ──────────────────────────────────────────
              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_selected.length} selected',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            // ── body ─────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _gradA,
                        strokeWidth: 2,
                      ),
                    )
                  : _error != null
                      ? _ErrorView(error: _error!, onRetry: _loadApps)
                      : _filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.apps_rounded, color: _muted, size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'No apps match your search'
                                        : 'No apps found\nGrant "Usage access" permission first',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(color: _muted, fontSize: 15),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                              itemCount: _filtered.length,
                              itemBuilder: (context, i) {
                                final app = _filtered[i];
                                final selected = _selected.contains(app.packageName);
                                final isLast = i == _filtered.length - 1;
                                final isFirst = i == 0;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: _card,
                                    borderRadius: BorderRadius.vertical(
                                      top: isFirst ? const Radius.circular(16) : Radius.zero,
                                      bottom: isLast ? const Radius.circular(16) : Radius.zero,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.vertical(
                                          top: isFirst ? const Radius.circular(16) : Radius.zero,
                                          bottom: isLast ? const Radius.circular(16) : Radius.zero,
                                        ),
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: app.iconBytes != null
                                                    ? Image.memory(
                                                        app.iconBytes!,
                                                        width: 42,
                                                        height: 42,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Container(
                                                        width: 42,
                                                        height: 42,
                                                        decoration: BoxDecoration(
                                                          color: _cardAlt,
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: const Icon(
                                                          Icons.apps_rounded,
                                                          color: _muted,
                                                          size: 22,
                                                        ),
                                                      ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Text(
                                                  app.label,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 15,
                                                    color: _white,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ),
                                              Switch(
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
                                                activeColor: _green,
                                                activeTrackColor: _green.withValues(alpha: 0.3),
                                                inactiveThumbColor: _muted,
                                                inactiveTrackColor: _cardAlt,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (!isLast)
                                        Container(
                                          height: 0.5,
                                          margin: const EdgeInsets.only(left: 72),
                                          color: _separator,
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),

            // ── done button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: GestureDetector(
                onTap: _selected.isEmpty
                    ? null
                    : () async {
                        await ref
                            .read(zenSessionProvider.notifier)
                            .setBlockedPackages(_selected.toList());
                        if (context.mounted) context.pop();
                      },
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _selected.isEmpty ? 0.4 : 1.0,
                  child: Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_gradA, _gradB]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _selected.isEmpty
                            ? 'Select apps to block'
                            : 'Done — ${_selected.length} app${_selected.length == 1 ? '' : 's'} selected',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: _muted, size: 48),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: _muted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_gradA, _gradB]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
