import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/routine.dart';
import '../services/data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/neuro_button.dart';

class RoutineDetailScreen extends StatefulWidget {
  const RoutineDetailScreen({super.key, required this.routine});

  final Routine routine;

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  int _currentStepIndex = 0;
  bool _isCompleted = false;
  bool _historySaved = false;
  Timer? _timer;
  Duration? _remainingTime;

  List<String> get _steps =>
      widget.routine.steps.isEmpty ? const ['Sem passos definidos'] : widget.routine.steps;

  bool get _hasSteps => widget.routine.steps.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _setupTimerForStep();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration? _parseDurationFromStep(String step) {
    final timeFormatMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(step);
    if (timeFormatMatch != null) {
      final minutes = int.tryParse(timeFormatMatch.group(1) ?? '');
      final seconds = int.tryParse(timeFormatMatch.group(2) ?? '');
      if (minutes != null && seconds != null) {
        return Duration(minutes: minutes, seconds: seconds);
      }
    }

    final match = RegExp(r'(\d+)\s*(min|m|minuto|minutos|seg|s)\b',
            caseSensitive: false)
        .firstMatch(step);
    if (match == null) {
      return null;
    }
    final value = int.tryParse(match.group(1) ?? '');
    if (value == null) {
      return null;
    }
    final unit = match.group(2)?.toLowerCase() ?? '';
    if (unit.startsWith('s') || unit.startsWith('seg')) {
      return Duration(seconds: value);
    }
    return Duration(minutes: value);
  }

  void _setupTimerForStep() {
    _timer?.cancel();
    if (!_hasSteps || _currentStepIndex >= _steps.length) {
      setState(() => _remainingTime = null);
      return;
    }

    final duration = _parseDurationFromStep(_steps[_currentStepIndex]);
    if (duration == null) {
      setState(() => _remainingTime = null);
      return;
    }

    setState(() => _remainingTime = duration);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime == null) {
        timer.cancel();
        return;
      }
      if (_remainingTime!.inSeconds <= 1) {
        setState(() => _remainingTime = Duration.zero);
        timer.cancel();
        return;
      }
      setState(() {
        _remainingTime = _remainingTime! - const Duration(seconds: 1);
      });
    });
  }

  Future<void> _completeRoutine() async {
    if (_isCompleted) {
      return;
    }
    _timer?.cancel();
    setState(() => _isCompleted = true);

    if (_historySaved) {
      return;
    }

    _historySaved = true;
    await context.read<DataProvider>().addRoutineHistory(
          routine: widget.routine,
        );
  }

  void _advanceStep() {
    if (!_hasSteps) {
      return;
    }
    if (_currentStepIndex >= _steps.length - 1) {
      _completeRoutine();
    } else {
      setState(() => _currentStepIndex += 1);
      _setupTimerForStep();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isCompleted) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  'Rotina Concluída',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Excelente! Você finalizou mais uma etapa do seu foco.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                NeuroButton(
                  label: 'Voltar',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentStep = _steps[_currentStepIndex];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.routine.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Passo ${_currentStepIndex + 1} de ${_steps.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                currentStep,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (_remainingTime != null) ...[
                Center(
                  child: Text(
                    _formatDuration(_remainingTime!),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _hasSteps ? _advanceStep : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          side: BorderSide(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        child: const Text('Pular'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: NeuroButton(
                      label: 'Próximo',
                      onPressed: _hasSteps ? _advanceStep : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
