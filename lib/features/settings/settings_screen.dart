import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../auth/auth_state.dart';
import '../auth/auth_service.dart';
import '../problems/topic_registry.dart';
import 'settings_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

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
          'SETTINGS',
          style: GoogleFonts.spaceMono(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.offWhite,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _sectionLabel('QUESTION TOPIC'),
          const SizedBox(height: 12),
          _topicGrid(settings.questionTopic, (topic) => notifier.setQuestionTopic(topic)),
          const SizedBox(height: 24),
          _sectionLabel('DIFFICULTY LEVEL'),
          const SizedBox(height: 12),
          _difficultyRow(settings.problemDifficulty, (d) => notifier.setProblemDifficulty(d)),
          const SizedBox(height: 24),
          _sectionLabel('PROBLEM TYPE'),
          const SizedBox(height: 12),
          _problemTypeRow(settings.problemType, (t) => notifier.setProblemType(t)),
          const SizedBox(height: 24),
          _sectionLabel('LOCK MODE'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _selectChip(
                  label: 'Block apps',
                  selected: settings.lockMode == LockMode.apps,
                  onTap: () => notifier.setLockMode(LockMode.apps),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _selectChip(
                  label: 'Lock phone',
                  selected: settings.lockMode == LockMode.full,
                  onTap: () => notifier.setLockMode(LockMode.full),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionLabel('PENALTY (Minutes added for wrong answer)'),
          const SizedBox(height: 12),
          _stepper(
            value: settings.penaltyMinutes,
            min: 1,
            max: 30,
            onDecrement: () => notifier.setPenaltyMinutes((settings.penaltyMinutes - 1).clamp(1, 30)),
            onIncrement: () => notifier.setPenaltyMinutes((settings.penaltyMinutes + 1).clamp(1, 30)),
            valueColor: AppColors.neonPink,
          ),
          const SizedBox(height: 24),
          _sectionLabel('REWARD (Minutes of access for correct answer)'),
          const SizedBox(height: 12),
          _stepper(
            value: settings.rewardDurationMinutes,
            min: 1,
            max: 60,
            onDecrement: () => notifier.setRewardDurationMinutes((settings.rewardDurationMinutes - 1).clamp(1, 60)),
            onIncrement: () => notifier.setRewardDurationMinutes((settings.rewardDurationMinutes + 1).clamp(1, 60)),
            valueColor: AppColors.neonPurple,
          ),
          const SizedBox(height: 24),
          _sectionLabel('ZEN SESSION DURATION (minutes)'),
          const SizedBox(height: 12),
          _stepper(
            value: settings.sessionDurationMinutes,
            min: 15,
            max: 480,
            step: 15,
            onDecrement: () {
              final v = ((settings.sessionDurationMinutes - 15).clamp(0, 480) ~/ 15) * 15;
              notifier.setSessionDurationMinutes(v < 15 ? 15 : v);
            },
            onIncrement: () {
              final v = ((settings.sessionDurationMinutes + 15).clamp(15, 480) ~/ 15) * 15;
              notifier.setSessionDurationMinutes(v > 480 ? 480 : v);
            },
            valueColor: AppColors.neonCyan,
          ),
          const SizedBox(height: 24),
          _sectionLabel('ACCENT COLOR'),
          const SizedBox(height: 12),
          _accentColorRow(settings.accentColorKey, notifier.setAccentColorKey),
          const SizedBox(height: 24),
          _sectionLabel('FEEDBACK'),
          const SizedBox(height: 12),
          _toggleRow(
            'Enable Sounds',
            settings.enableSounds,
            (v) => notifier.setEnableSounds(v),
          ),
          const SizedBox(height: 8),
          _toggleRow(
            'Enable Vibration',
            settings.enableVibration,
            (v) => notifier.setEnableVibration(v),
          ),
          const SizedBox(height: 24),
          _sectionLabel('UNLOCK BEHAVIOR'),
          const SizedBox(height: 12),
          _toggleRow(
            'Allow reopen during unlock window',
            settings.allowReopenWithinWindow,
            (v) => notifier.setAllowReopenWithinWindow(v),
          ),
          const SizedBox(height: 24),
          _sectionLabel('ACCOUNT'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await ref.read(authSkippedProvider.notifier).setSkipped(false);
                await AuthService.signOut();
                if (context.mounted) context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.mutedForeground,
                side: const BorderSide(color: AppColors.mutedForeground),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Sign out',
                style: GoogleFonts.inter(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.save, size: 24),
              label: Text(
                'SAVE SETTINGS',
                style: GoogleFonts.spaceMono(fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 24),
                side: const BorderSide(color: AppColors.offWhite, width: 4),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceMono(
        fontSize: 14,
        color: AppColors.offWhite,
        letterSpacing: 1,
      ),
    );
  }

  Widget _topicGrid(String current, ValueChanged<String> onSelected) {
    final topics = TopicRegistry.topicIds;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: topics.map((topic) {
        final selected = current == topic;
        return Material(
          color: selected ? AppColors.neonPink : AppColors.surface,
          child: InkWell(
            onTap: () => onSelected(topic),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? AppColors.neonPink : AppColors.offWhite,
                  width: 4,
                ),
              ),
              child: Center(
                child: Text(
                  TopicRegistry.label(topic).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.offWhite,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _difficultyRow(ProblemDifficulty current, ValueChanged<ProblemDifficulty> onSelected) {
    return Row(
      children: [
        _selectChip(
          label: 'EASY',
          selected: current == ProblemDifficulty.easy,
          onTap: () => onSelected(ProblemDifficulty.easy),
        ),
        const SizedBox(width: 8),
        _selectChip(
          label: 'MEDIUM',
          selected: current == ProblemDifficulty.medium,
          accentColor: AppColors.neonCyan,
          onTap: () => onSelected(ProblemDifficulty.medium),
        ),
      ],
    );
  }

  Widget _problemTypeRow(ProblemType current, ValueChanged<ProblemType> onSelected) {
    return Row(
      children: [
        _selectChip(
          label: 'LINEAR',
          selected: current == ProblemType.linear,
          onTap: () => onSelected(ProblemType.linear),
        ),
        const SizedBox(width: 8),
        _selectChip(
          label: 'INTEGRATION',
          selected: current == ProblemType.integration,
          onTap: () => onSelected(ProblemType.integration),
        ),
      ],
    );
  }

  Widget _selectChip({
    required String label,
    required bool selected,
    Color? accentColor,
    required VoidCallback onTap,
  }) {
    final color = accentColor ?? AppColors.neonPink;
    return Expanded(
      child: Material(
        color: selected ? color : AppColors.surface,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? color : AppColors.offWhite,
                width: 4,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: selected ? (color == AppColors.neonCyan ? AppColors.background : AppColors.offWhite) : AppColors.offWhite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepper({
    required int value,
    required int min,
    required int max,
    int step = 1,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required Color valueColor,
  }) {
    return Row(
      children: [
        _stepperButton('-', onDecrement),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.offWhite, width: 4),
            ),
            child: Center(
              child: Text(
                '$value',
                style: GoogleFonts.spaceMono(
                  fontSize: 32,
                  color: valueColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _stepperButton('+', onIncrement),
      ],
    );
  }

  Widget _stepperButton(String label, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.offWhite, width: 4),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 24,
                color: AppColors.offWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _accentColorRow(String currentKey, ValueChanged<String> onSelected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: AppColors.accentColors.entries.map((e) {
        final selected = currentKey == e.key;
        return GestureDetector(
          onTap: () => onSelected(e.key),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: e.value,
              border: Border.all(
                color: AppColors.offWhite,
                width: selected ? 4 : 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.offWhite, width: 4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(color: AppColors.offWhite),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 56,
              height: 32,
              decoration: BoxDecoration(
                color: value ? AppColors.neonYellow : AppColors.switchBg,
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
          ),
        ],
      ),
    );
  }
}
