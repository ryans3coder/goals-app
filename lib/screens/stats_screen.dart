import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/stats/routine_stats_calculator.dart';
import '../domain/stats/routine_stats_summary.dart';
import '../domain/stats/xp_policy.dart';
import '../services/data_provider.dart';
import '../theme/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state_widget.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<RoutineStatsSummary> _statsFuture;
  late final DataProvider _dataProvider;

  @override
  void initState() {
    super.initState();
    _dataProvider = context.read<DataProvider>();
    _dataProvider.addListener(_handleDataChange);
    _statsFuture = _loadStats();
  }

  @override
  void dispose() {
    _dataProvider.removeListener(_handleDataChange);
    super.dispose();
  }

  void _handleDataChange() {
    if (!mounted) {
      return;
    }
    setState(() {
      _statsFuture = _loadStats();
    });
  }

  Future<RoutineStatsSummary> _loadStats() async {
    final events = await _dataProvider.fetchRoutineEvents();
    const calculator = RoutineStatsCalculator(xpPolicy: XpPolicy());
    return calculator.summarize(events);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.statsTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
      body: FutureBuilder<RoutineStatsSummary>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return EmptyStateWidget(
              icon: Icons.query_stats,
              title: AppStrings.statsLoadErrorTitle,
              description: AppStrings.statsLoadErrorMessage,
              actionLabel: AppStrings.back,
              onAction: () => Navigator.of(context).pop(),
            );
          }

          final stats = snapshot.data;
          if (stats == null || !stats.hasEvents) {
            return EmptyStateWidget(
              icon: Icons.query_stats,
              title: AppStrings.statsEmptyTitle,
              description: AppStrings.statsEmptyMessage,
              actionLabel: AppStrings.back,
              onAction: () => Navigator.of(context).pop(),
            );
          }

          return _StatsContent(summary: stats);
        },
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.summary});

  final RoutineStatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayFormatter = DateFormat('EEE');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.statsStreakTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.statsStreakRule,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _MetricPill(
                    label: AppStrings.statsStreakLabel,
                    value: '${summary.streakDays}',
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _MetricPill(
                    label: AppStrings.statsTotalXpLabel,
                    value: '${summary.totalXp}',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.statsSuccessTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _SuccessRateCard(
                      label: AppStrings.statsLast7Days,
                      summary: summary.last7DaysSuccess,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _SuccessRateCard(
                      label: AppStrings.statsLast30Days,
                      summary: summary.last30DaysSuccess,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.statsLast7DaysSummaryTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...summary.last7DaysXp.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dayFormatter.format(entry.day),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${entry.xp} ${AppStrings.statsXpUnit}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessRateCard extends StatelessWidget {
  const _SuccessRateCard({required this.label, required this.summary});

  final String label;
  final SuccessRateSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (summary.rate * 100).round();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$percentage%',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${summary.completed}/${summary.started} ${AppStrings.statsSuccessUnit}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
