import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../app_shell.dart';
import '../models.dart';
import '../ui/animated_widgets.dart';
import '../ui/report_copy.dart';
import '../ui/ui_kit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _refreshing = false;

  Future<void> _onRefresh(AppController ctrl) async {
    setState(() => _refreshing = true);
    await ctrl.refreshProducts(silent: true);
    await ctrl.refreshCumulativeSummary();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AppController>();
    final summary = ctrl.cumulativeSummary;
    final user = ctrl.currentUser;
    final featuredProduct = ctrl.products.isNotEmpty
        ? ctrl.products.first
        : null;
    final showLoading = ctrl.isBusy && summary == null && ctrl.products.isEmpty;
    final errorMessage = ctrl.errorMessage?.trim();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    final firstName = user?.firstName.trim().isNotEmpty == true
        ? user!.firstName
        : 'there';

    return RefreshIndicator(
      onRefresh: () => _onRefresh(ctrl),
      color: AppColors.ink,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          // ─── Header ───────────────────────────────────────────────────────
          StaggeredFadeIn(
            delay: const Duration(milliseconds: 0),
            child: _DashboardHeader(
              greeting: greeting,
              firstName: firstName,
              summary: summary,
            ),
          ),
          const SizedBox(height: 20),

          // ─── Metric cards ─────────────────────────────────────────────────
          StaggeredFadeIn(
            delay: const Duration(milliseconds: 80),
            child: _MetricRow(ctrl: ctrl, summary: summary),
          ),
          const SizedBox(height: 18),

          if (errorMessage != null && errorMessage.isNotEmpty) ...[
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 100),
              child: _StatusBanner(
                title: 'Sync issue',
                message: errorMessage,
                icon: Icons.error_outline,
                tint: AppColors.danger,
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (showLoading) ...[
            const StaggeredFadeIn(
              delay: Duration(milliseconds: 110),
              child: _DashboardLoading(),
            ),
            const SizedBox(height: 16),
          ],

          if (summary != null ||
              featuredProduct != null ||
              (user?.aiReport.isNotEmpty ?? false)) ...[
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 120),
              child: _AiReportsCard(
                summary: summary,
                user: user,
                featuredProduct: featuredProduct,
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (summary != null) ...[
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 120),
              child: _InsightBoard(ctrl: ctrl, summary: summary),
            ),
            const SizedBox(height: 16),
          ],

          // ─── Overall assessment ───────────────────────────────────────────
          if (summary != null) ...[
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 160),
              child: _OverallAssessmentCard(summary: summary),
            ),
            const SizedBox(height: 16),
          ],

          // ─── Organs under pressure ────────────────────────────────────────
          if (summary != null && summary.organsUnderPressure.isNotEmpty) ...[
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 200),
              child: _OrgansCard(summary: summary),
            ),
            const SizedBox(height: 16),
          ],

          // ─── Product verdicts ─────────────────────────────────────────────
          if (summary != null && summary.productVerdicts.isNotEmpty) ...[
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 240),
              child: _ProductVerdictsCard(
                summary: summary,
                onViewAll: () => context.switchHomeTab(2),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ─── Critical chemicals ───────────────────────────────────────────
          if (summary != null &&
              (summary.criticalChemicals.isNotEmpty ||
                  summary.highChemicals.isNotEmpty ||
                  summary.recurrenceRisks.isNotEmpty)) ...[
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 280),
              child: _ChemicalsAlertCard(summary: summary),
            ),
            const SizedBox(height: 16),
          ],

          if (summary != null || featuredProduct != null) ...[
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 300),
              child: _RecommendationsCard(
                summary: summary,
                featuredProduct: featuredProduct,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ─── Safe ingredients ─────────────────────────────────────────────
          if (summary != null && summary.safeIngredients.isNotEmpty) ...[
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 320),
              child: _SafeIngredientsCard(summary: summary),
            ),
            const SizedBox(height: 16),
          ],

          // ─── Decision summary ─────────────────────────────────────────────
          StaggeredFadeIn(
            delay: const Duration(milliseconds: 360),
            child: _DecisionSummaryCard(ctrl: ctrl),
          ),
          const SizedBox(height: 16),

          // ─── High risk products ───────────────────────────────────────────
          StaggeredFadeIn(
            delay: const Duration(milliseconds: 400),
            child: _HighRiskProductsCard(ctrl: ctrl),
          ),
          const SizedBox(height: 16),

          // ─── Empty state ──────────────────────────────────────────────────
          if (summary == null && ctrl.products.isEmpty) ...[
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 160),
              child: EmptyStateCard(
                title: 'Your dashboard is getting ready',
                message:
                    'Add at least two products to unlock cumulative trends, alerts, and personalized insights.',
                icon: Icons.insights_outlined,
                action: FilledButton.icon(
                  onPressed: () => context.switchHomeTab(1),
                  icon: const Icon(Icons.center_focus_strong_outlined),
                  label: const Text('Scan now'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ─── Quick actions ────────────────────────────────────────────────
          StaggeredFadeIn(
            delay: const Duration(milliseconds: 440),
            child: _QuickActionsCard(),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.greeting,
    required this.firstName,
    required this.summary,
  });

  final String greeting;
  final String firstName;
  final CumulativeSummary? summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                if (summary != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    summary!.overallAssessment.length > 80
                        ? '${summary!.overallAssessment.substring(0, 77)}…'
                        : summary!.overallAssessment,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (summary != null) ...[
            const SizedBox(width: 16),
            HealthScoreRing(score: summary!.healthScore, size: 72),
          ],
        ],
      ),
    );
  }
}

// ─── Metric Row ───────────────────────────────────────────────────────────────
class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.ctrl, required this.summary});

  final AppController ctrl;
  final CumulativeSummary? summary;

  @override
  Widget build(BuildContext context) {
    final totalProducts = ctrl.productCounts['total'] ?? ctrl.products.length;
    final safeProducts = summary?.productsSafe ?? 0;
    final avoidProducts = summary?.productsToAvoid ?? 0;
    final reduceProducts = summary?.productsToReduce ?? 0;
    final analyzedProducts = summary?.productCount ?? totalProducts;
    final highChemicals = summary == null
        ? 0
        : summary!.criticalChemicals.length + summary!.highChemicals.length;
    final totalChemicals = ctrl.products.fold<int>(
      0,
      (acc, item) => acc + item.ingredients.length,
    );
    final organOverlap = summary?.organsUnderPressure.length ?? 0;
    final investigateCount = summary?.unverifiedChemicals.length ?? 0;
    final riskyProducts = (avoidProducts + reduceProducts).clamp(0, 9999);
    final ratioText = riskyProducts == 0
        ? 'Balanced'
        : '$safeProducts:$riskyProducts';

    final metrics = [
      (
        'Analyzed products',
        analyzedProducts,
        Icons.inventory_2_outlined,
        AppColors.softBlue,
      ),
      (
        'Total chemicals',
        totalChemicals,
        Icons.science_outlined,
        const Color(0xFFD4F5E2),
      ),
      (
        'High-risk chemicals',
        highChemicals,
        Icons.warning_amber_rounded,
        const Color(0xFFFFD8E0),
      ),
      (
        'Investigation items',
        investigateCount,
        Icons.travel_explore_outlined,
        const Color(0xFFFFE7D6),
      ),
      (
        'Organ overlap',
        organOverlap,
        Icons.monitor_heart_outlined,
        const Color(0xFFE5EDFC),
      ),
      (
        'Most affected organs',
        organOverlap,
        Icons.air_outlined,
        const Color(0xFFECE1FF),
      ),
      (
        'Safe vs risky',
        riskyProducts,
        Icons.balance_outlined,
        const Color(0xFFDDF4EA),
      ),
      (
        'Risk score',
        summary?.healthScore ?? 50,
        Icons.ssid_chart_rounded,
        const Color(0xFFFFE9D8),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final cardWidth = wide
            ? (constraints.maxWidth - 30) / 4
            : (constraints.maxWidth - 10) / 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: metrics
                  .map(
                    (metric) => SizedBox(
                      width: cardWidth,
                      child: _AnimatedMetricCard(
                        label: metric.$1,
                        value: metric.$2,
                        icon: metric.$3,
                        tint: metric.$4,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            Text(
              'Safe vs risky ratio: $ratioText',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        );
      },
    );
  }
}

class _InsightBoard extends StatelessWidget {
  const _InsightBoard({required this.ctrl, required this.summary});

  final AppController ctrl;
  final CumulativeSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = (summary.productCount).clamp(1, 9999);
    final safe = summary.productsSafe.clamp(0, total);
    final avoid = summary.productsToAvoid.clamp(0, total);
    final reduce = summary.productsToReduce.clamp(0, total);
    final risky = (avoid + reduce).clamp(0, total);
    final organList = summary.organsUnderPressure.take(5).toList();
    final warnings = summary.keyWarnings.take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final riskCard = _ChartCard(
          title: 'Risk distribution',
          subtitle:
              'Safe, reduce, and avoid signals from the AI Safety Overview.',
          child: Column(
            children: [
              _BarLine(
                label: 'Safe products',
                value: safe / total,
                color: AppColors.success,
              ),
              _BarLine(
                label: 'Reduce products',
                value: reduce / total,
                color: AppColors.warning,
              ),
              _BarLine(
                label: 'Avoid products',
                value: avoid / total,
                color: AppColors.danger,
              ),
              _BarLine(
                label: 'Risky share',
                value: risky / total,
                color: const Color(0xFFE36C58),
              ),
            ],
          ),
        );

        final organCard = _ChartCard(
          title: 'Organ impact',
          subtitle: 'Organs receiving the strongest verified signals.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: organList.isEmpty
                ? [
                    const _TrendPill(
                      label: 'No verified organ signal yet',
                      tint: AppColors.muted,
                    ),
                  ]
                : organList
                      .map(
                        (organ) =>
                            _TrendPill(label: organ, tint: AppColors.danger),
                      )
                      .toList(),
          ),
        );

        final trendCard = _ChartCard(
          title: 'AI trend insights',
          subtitle: 'What the cumulative report is emphasizing right now.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: warnings.isEmpty
                ? const [
                    Text(
                      'No trend signal is available yet.',
                      style: TextStyle(color: AppColors.muted, height: 1.45),
                    ),
                  ]
                : warnings
                      .map(
                        (warning) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '• $warning',
                            style: const TextStyle(height: 1.45),
                          ),
                        ),
                      )
                      .toList(),
          ),
        );

        if (!wide) {
          return Column(
            children: [
              riskCard,
              const SizedBox(height: 16),
              organCard,
              const SizedBox(height: 16),
              trendCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: riskCard),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [organCard, const SizedBox(height: 16), trendCard],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title, subtitle: subtitle),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BarLine extends StatelessWidget {
  const _BarLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tint,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AnimatedMetricCard extends StatelessWidget {
  const _AnimatedMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.ink, size: 18),
          ),
          const SizedBox(height: 12),
          AnimatedCounter(
            value: value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.title,
    required this.message,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        ShimmerCard(height: 120),
        SizedBox(height: 12),
        ShimmerCard(height: 180),
      ],
    );
  }
}

class _AiReportsCard extends StatelessWidget {
  const _AiReportsCard({
    required this.summary,
    required this.user,
    required this.featuredProduct,
  });

  final CumulativeSummary? summary;
  final AppUser? user;
  final ProductItem? featuredProduct;

  @override
  Widget build(BuildContext context) {
    final riskSummary = summary?.overallAssessment;
    final riskHighlights = summary?.keyWarnings ?? const [];
    final personalSummary =
        user?.personalizedSummary ?? featuredProduct?.aiSummary;
    final personalHighlights =
        user?.personalizedHighlights ??
        featuredProduct?.investigationChemicals ??
        const <String>[];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: ReportCopy.aiSafetyOverviewLabel(),
            subtitle: ReportCopy.aiSafetyOverviewSubtitle(),
          ),
          const SizedBox(height: 14),
          _ReportPanel(
            title: ReportCopy.aiSafetyOverviewLabel(),
            subtitle: 'Cumulative view and priority safety signals.',
            icon: Icons.analytics_outlined,
            tint: const Color(0xFFFFD8E0),
            summary: riskSummary,
            highlights: riskHighlights,
          ),
          const SizedBox(height: 12),
          _ReportPanel(
            title: 'Personalized AI Brief',
            subtitle: 'Insights aligned to your health profile.',
            icon: Icons.person_outline,
            tint: const Color(0xFFDDEBFF),
            summary: personalSummary,
            highlights: personalHighlights,
          ),
        ],
      ),
    );
  }
}

class _ReportPanel extends StatelessWidget {
  const _ReportPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.summary,
    required this.highlights,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final String? summary;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final safeSummary = summary?.trim();
    final hasHighlights = highlights.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tint.withValues(alpha: 0.8)),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 10),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        collapsedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.ink, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          if (safeSummary != null && safeSummary.isNotEmpty)
            Text(safeSummary, style: const TextStyle(height: 1.45))
          else
            Text(
              ReportCopy.minimalSummary(subject: title.toLowerCase()),
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
          if (hasHighlights) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: highlights.take(5).map((item) {
                return _MiniPill(label: item);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _OverlapChip extends StatelessWidget {
  const _OverlapChip({
    required this.label,
    required this.count,
    this.tint = AppColors.danger,
  });

  final String label;
  final int count;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Text(
        count > 0 ? '$label · $count' : label,
        style: TextStyle(
          color: tint,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Overall Assessment Card ─────────────────────────────────────────────────
class _OverallAssessmentCard extends StatelessWidget {
  const _OverallAssessmentCard({required this.summary});

  final CumulativeSummary summary;

  @override
  Widget build(BuildContext context) {
    final hasRisk =
        summary.productsToAvoid > 0 || summary.criticalChemicals.isNotEmpty;
    final gradient = hasRisk
        ? [const Color(0xFFFFE7D6), const Color(0xFFFFD8E0)]
        : [const Color(0xFFD4F5E2), AppColors.softBlue];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              hasRisk ? Icons.warning_amber_rounded : Icons.shield_outlined,
              color: AppColors.ink,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasRisk ? 'Action recommended' : 'Overall stable profile',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.overallAssessment,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Organs Card ──────────────────────────────────────────────────────────────
class _OrgansCard extends StatelessWidget {
  const _OrgansCard({required this.summary});

  final CumulativeSummary summary;

  @override
  Widget build(BuildContext context) {
    final overlapItems =
        summary.organGlobalAnalysis.entries
            .map((entry) {
              final raw = entry.value;
              final count = raw is Map
                  ? (raw['total_unique_count'] as num?)?.toInt() ??
                        (raw['count'] as num?)?.toInt() ??
                        (raw['total'] as num?)?.toInt() ??
                        0
                  : (raw is num ? raw.toInt() : 0);
              return (entry.key, count);
            })
            .where((item) => item.$2 > 0)
            .toList()
          ..sort((a, b) => b.$2.compareTo(a.$2));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PulsingDot(color: AppColors.warning),
              const SizedBox(width: 10),
              const Text(
                'Organs under pressure',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'These organs are receiving the strongest signals from your current products.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: summary.organsUnderPressure
                .map((organ) => OrganChip(organ: organ))
                .toList(),
          ),
          if (overlapItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text(
              'Ingredient ↔ organ overlap',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: overlapItems.take(6).map((item) {
                return _OverlapChip(label: item.$1, count: item.$2);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Product Verdicts Card ────────────────────────────────────────────────────
class _ProductVerdictsCard extends StatelessWidget {
  const _ProductVerdictsCard({required this.summary, required this.onViewAll});

  final CumulativeSummary summary;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final verdicts = summary.sortedVerdicts.take(4).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Product verdicts',
            subtitle: 'Cumulative analysis across your list.',
            trailing: TextButton(
              onPressed: onViewAll,
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: 14),
          ...verdicts.map(
            (verdict) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VerdictRow(verdict: verdict),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerdictRow extends StatelessWidget {
  const _VerdictRow({required this.verdict});

  final Map<String, dynamic> verdict;

  @override
  Widget build(BuildContext context) {
    final name = verdict['product_name']?.toString() ?? 'Product';
    final recommendation = verdict['recommendation']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          VerdictBadge(recommendation: recommendation),
        ],
      ),
    );
  }
}

// ─── Chemicals Alert Card ─────────────────────────────────────────────────────
class _ChemicalsAlertCard extends StatelessWidget {
  const _ChemicalsAlertCard({required this.summary});

  final CumulativeSummary summary;

  @override
  Widget build(BuildContext context) {
    final recurrence = summary.recurrenceRisks
        .map((item) {
          final name =
              item['chemical']?.toString() ??
              item['ingredient']?.toString() ??
              item['name']?.toString();
          final freq =
              (item['frequency'] as num?)?.toInt() ??
              (item['count'] as num?)?.toInt() ??
              0;
          return (name, freq);
        })
        .where((item) => (item.$1 ?? '').trim().isNotEmpty)
        .toList();

    final all = [
      ...summary.criticalChemicals.map((c) => (c, true, 0)),
      ...summary.highChemicals.take(4).map((c) => (c, false, 0)),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PulsingDot(color: AppColors.danger),
              const SizedBox(width: 10),
              const Text(
                'Concerning ingredients',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Detected across multiple products in your list.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (recurrence.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recurrence.take(6).map((item) {
                final label = item.$1 ?? '';
                final count = item.$2;
                return _OverlapChip(
                  label: label,
                  count: count,
                  tint: AppColors.warning,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: all.take(8).map((item) {
              final color = item.$2 ? AppColors.danger : AppColors.warning;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  item.$1,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Safe Ingredients Card ────────────────────────────────────────────────────
class _SafeIngredientsCard extends StatelessWidget {
  const _SafeIngredientsCard({required this.summary});

  final CumulativeSummary summary;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Verified safe ingredients',
            subtitle: 'Ingredients in your products that are considered safe.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: summary.safeIngredients
                .take(10)
                .map(
                  (ing) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      ing,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Recommendations Card ───────────────────────────────────────────────────
class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({
    required this.summary,
    required this.featuredProduct,
  });

  final CumulativeSummary? summary;
  final ProductItem? featuredProduct;

  @override
  Widget build(BuildContext context) {
    final fromApi = summary?.recommendationHighlights ?? const <String>[];
    final fromVerdicts = (summary?.sortedVerdicts ?? const [])
        .where(
          (item) =>
              (item['recommendation'] ?? '').toString().toLowerCase() != 'keep',
        )
        .map((item) {
          final name = item['product_name']?.toString() ?? 'Product';
          final rec = item['recommendation']?.toString() ?? '';
          return '$name: ${rec.replaceAll('_', ' ')}';
        })
        .toList();
    final fromProduct =
        featuredProduct?.previewAlternatives ?? const <String>[];

    final items = fromApi.isNotEmpty
        ? fromApi
        : fromVerdicts.isNotEmpty
        ? fromVerdicts
        : fromProduct;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Priority recommendations',
            subtitle: 'Fast actions suggested by the cumulative analysis.',
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'No priority recommendation yet. Keep scanning to enrich the report.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.take(6).map((item) {
                return _MiniPill(label: item);
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ─── Decision Summary Card ────────────────────────────────────────────────────
class _DecisionSummaryCard extends StatelessWidget {
  const _DecisionSummaryCard({required this.ctrl});

  final AppController ctrl;

  @override
  Widget build(BuildContext context) {
    final counts = ctrl.productCounts;
    final items = [
      (
        'Adopted',
        counts['approved'] ?? 0,
        AppColors.success,
        Icons.check_circle_outline,
      ),
      (
        'Saved',
        counts['saved'] ?? 0,
        AppColors.softBlue,
        Icons.bookmark_outline,
      ),
      (
        'Review',
        counts['pending'] ?? 0,
        AppColors.warning,
        Icons.hourglass_empty_outlined,
      ),
      (
        'Rejected',
        counts['rejected'] ?? 0,
        AppColors.danger,
        Icons.close_outlined,
      ),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'My decisions',
            subtitle: 'A live memory of your product choices.',
          ),
          const SizedBox(height: 16),
          Row(
            children: items.map((item) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.$3 is Color
                            ? (item.$3 as Color).withValues(alpha: 0.12)
                            : AppColors.softBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.$4, color: item.$3 as Color, size: 20),
                    ),
                    const SizedBox(height: 8),
                    AnimatedCounter(
                      value: item.$2,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$1,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── High Risk Products Card ──────────────────────────────────────────────────
class _HighRiskProductsCard extends StatelessWidget {
  const _HighRiskProductsCard({required this.ctrl});

  final AppController ctrl;

  @override
  Widget build(BuildContext context) {
    final flagged = ctrl.highRiskProducts.take(3).toList();

    if (flagged.isEmpty && ctrl.products.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Products to watch',
            subtitle: flagged.isEmpty
                ? 'No high-risk product has been detected.'
                : 'Handle quickly from your product list.',
          ),
          if (flagged.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...flagged.map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      RiskChip(level: product.riskLevel),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.displayTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${product.decisionLabel} · ${product.category.label}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            FilledButton.tonal(
              onPressed: () => context.switchHomeTab(2),
              child: const Text('Open My products'),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Quick Actions Card ───────────────────────────────────────────────────────
class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.center_focus_strong_outlined,
            label: 'Scan',
            onTap: () => context.switchHomeTab(1),
            color: AppColors.softBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.inventory_2_outlined,
            label: 'My products',
            onTap: () => context.switchHomeTab(2),
            color: AppColors.softPink,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.ink, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
