import 'package:flutter/material.dart';
import '../models.dart';
import '../ui/ui_kit.dart';
import '../ui/report_copy.dart';
import 'product_card_widgets.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final ProductItem product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: buildPageBackground(),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Product report',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ProductInsightCard(
                title: product.displayTitle,
                subtitle:
                    '${product.category.label} • ${product.extractionLabel} • ${product.decisionLabel}',
                imageUrl: product.imageUrl,
                imageAspectRatio: 1.6,
                status: RiskChip(level: product.riskLevel),
                previewAlternatives: product.previewAlternatives,
                leadingIcon: product.category == ProductCategory.food
                    ? Icons.restaurant_outlined
                    : Icons.spa_outlined,
                footer: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DecisionChip(label: product.decisionLabel, active: true),
                    if (product.confidenceScore != null)
                      _ConfidenceChip(value: product.confidenceScore!),
                    if (product.updatedAt != null)
                      _MetaChip(
                        label:
                            'Updated ${product.updatedAt!.day.toString().padLeft(2, '0')}/${product.updatedAt!.month.toString().padLeft(2, '0')}',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ProductSummaryCard(product: product),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 920;
                  final filterSection = _FilterReportCard(product: product);
                  final investigationSection = _InvestigationReportCard(
                    product: product,
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: filterSection),
                        const SizedBox(width: 16),
                        Expanded(child: investigationSection),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      filterSection,
                      const SizedBox(height: 16),
                      investigationSection,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _ProductInformationCard(product: product),
              const SizedBox(height: 16),
              _AnalysisReportCard(product: product),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisReportCard extends StatelessWidget {
  const _AnalysisReportCard({required this.product});

  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    final report = product.investigationReport;
    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                title: 'AI risk analysis',
                subtitle:
                    'A trusted synthesis of the risk signals found in the report.',
              ),
              const SizedBox(height: 12),
              _RiskAnalysisPanel(report: report),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _OrganImpactSection(product: product),
      ],
    );
  }
}

class _RiskAnalysisPanel extends StatelessWidget {
  const _RiskAnalysisPanel({required this.report});

  final Map<String, dynamic> report;

  @override
  Widget build(BuildContext context) {
    final summary = report['summary'] as Map?;
    if (summary == null || (summary as Map).isEmpty) {
      return Text(
        ReportCopy.riskTableFallback(),
        style: const TextStyle(color: AppColors.muted, height: 1.45),
      );
    }

    final entries = (summary as Map).entries.toList();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final key = entry.key.toString();
        final value = entry.value?.toString() ?? '-';
        final label = _humanizeRiskKey(key);

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterReportCard extends StatelessWidget {
  const _FilterReportCard({required this.product});

  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    final sections = _riskRows(product.filteringReport);
    final grouped = _groupRiskRows(sections);
    final topConcerns = grouped['critical']!.isNotEmpty
        ? [
            ...grouped['critical']!,
            ...grouped['high']!,
          ].map((r) => r.name).toList()
        : product.investigationChemicals;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Ingredient synthesis',
            subtitle: 'Clear priorities for a fast, reliable reading.',
          ),
          const SizedBox(height: 14),
          _ChipBlock(
            title: 'Verified as safe',
            values: product.safeSkipIngredients,
            color: AppColors.success,
            fallback:
                'No ingredients have been explicitly verified as safe yet.',
            isClickable: false,
          ),
          const SizedBox(height: 14),
          _ChipBlock(
            title: 'Needs monitoring',
            values: product.investigationChemicals,
            color: AppColors.warning,
            fallback:
                'No critical ingredients are highlighted in the available data.',
            isClickable: true,
            report: product.investigationReport,
          ),
          const SizedBox(height: 14),
          _ChipBlock(
            title: 'Priority watchlist',
            values: topConcerns,
            color: AppColors.danger,
            fallback:
                'No critical signals are identified for this product right now.',
            isClickable: false,
          ),
          const SizedBox(height: 14),
          Text(
            'Risk categorization',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (sections.isEmpty)
            Text(
              ReportCopy.riskTableFallback(),
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            )
          else
            _RiskCategorySummary(groups: grouped),
        ],
      ),
    );
  }
}

class _InvestigationReportCard extends StatelessWidget {
  const _InvestigationReportCard({required this.product});

  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    final insights = _chemicalInsights(product.investigationReport);
    final hasSummary = product.aiSummary.trim().isNotEmpty;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Investigation report',
            subtitle: 'AI synthesis, evidence notes, and key signals.',
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softBlue.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              hasSummary
                  ? product.aiSummary
                  : ReportCopy.partialSummary(subject: 'product'),
              style: const TextStyle(height: 1.45, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 14),
          if (product.confidenceScore != null)
            _ConfidenceStrip(value: product.confidenceScore!),
          if (product.confidenceScore != null) const SizedBox(height: 14),
          Text(
            'Scientific notes',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (insights.isEmpty)
            Text(
              ReportCopy.scientificNotesFallback(),
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            )
          else
            ...insights
                .take(6)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (item.riskLevel != null)
                                _RiskLabel(level: item.riskLevel!),
                            ],
                          ),
                          if (item.scientificNote != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              item.scientificNote!,
                              style: const TextStyle(
                                height: 1.4,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                          if (item.effects != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Potential effects: ${item.effects!}',
                              style: const TextStyle(height: 1.4),
                            ),
                          ],
                          if (item.organImpact != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Organs: ${item.organImpact!}',
                              style: const TextStyle(height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ProductInformationCard extends StatelessWidget {
  const _ProductInformationCard({required this.product});

  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    final ingredients = product.ingredients;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Product information',
            subtitle: 'Technical sheet and full ingredient list.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: product.category.label),
              _MetaChip(label: product.extractionLabel),
              _MetaChip(
                label: product.barcode.isEmpty
                    ? 'No barcode'
                    : 'Barcode ${product.barcode}',
              ),
              _MetaChip(label: product.riskLevel),
            ],
          ),
          if (ingredients.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Ingredients',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ingredients
                  .map((ingredient) => Chip(label: Text(ingredient)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipBlock extends StatelessWidget {
  const _ChipBlock({
    required this.title,
    required this.values,
    required this.color,
    required this.fallback,
    this.isClickable = false,
    this.report,
  });

  final String title;
  final List<String> values;
  final Color color;
  final String fallback;
  final bool isClickable;
  final Map<String, dynamic>? report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (values.isEmpty)
          Text(
            fallback,
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map(
                  (value) => GestureDetector(
                    onTap: isClickable && report != null
                        ? () => _showChemicalDetails(context, value, report!)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: isClickable && report != null
                            ? Border.all(color: color.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          if (isClickable && report != null) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: color.withValues(alpha: 0.7),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  void _showChemicalDetails(
    BuildContext context,
    String chemicalName,
    Map<String, dynamic> report,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) =>
          _ChemicalDetailsSheet(chemicalName: chemicalName, report: report),
    );
  }
}

class _ChemicalDetailsSheet extends StatelessWidget {
  const _ChemicalDetailsSheet({
    required this.chemicalName,
    required this.report,
  });

  final String chemicalName;
  final Map<String, dynamic> report;

  @override
  Widget build(BuildContext context) {
    final summary = report['summary'] as Map?;
    final details =
        summary?[chemicalName]?.toString() ?? 'No details available';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ingredient details',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chemicalName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                details,
                style: const TextStyle(height: 1.6, color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, List<_RiskRow>> _groupRiskRows(List<_RiskRow> rows) {
  final groups = <String, List<_RiskRow>>{
    'critical': [],
    'high': [],
    'moderate': [],
    'low': [],
    'other': [],
  };
  for (final r in rows) {
    final lvl = r.level.toLowerCase();
    if (lvl.contains('critical') || lvl.contains('cr')) {
      groups['critical']!.add(r);
    } else if (lvl.contains('high') || lvl.contains('h')) {
      groups['high']!.add(r);
    } else if (lvl.contains('moderate') || lvl.contains('mod')) {
      groups['moderate']!.add(r);
    } else if (lvl.contains('low') || lvl.contains('safe')) {
      groups['low']!.add(r);
    } else {
      groups['other']!.add(r);
    }
  }
  return groups;
}

class _RiskCategorySummary extends StatelessWidget {
  const _RiskCategorySummary({required this.groups});

  final Map<String, List<_RiskRow>> groups;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (groups['critical']!.isNotEmpty) ...[
          _RiskGroupCard(
            label: 'Critical',
            rows: groups['critical']!,
            color: AppColors.danger,
          ),
          const SizedBox(height: 12),
        ],
        if (groups['high']!.isNotEmpty) ...[
          _RiskGroupCard(
            label: 'High',
            rows: groups['high']!,
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
        ],
        if (groups['moderate']!.isNotEmpty) ...[
          _RiskGroupCard(
            label: 'Moderate',
            rows: groups['moderate']!,
            color: AppColors.softPeach,
          ),
          const SizedBox(height: 12),
        ],
        if (groups['low']!.isNotEmpty) ...[
          _RiskGroupCard(
            label: 'Low',
            rows: groups['low']!,
            color: AppColors.success,
          ),
        ],
      ],
    );
  }
}

class _OrganImpactSection extends StatelessWidget {
  const _OrganImpactSection({required this.product});

  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    final report = product.investigationReport;
    final organs = _organImpact(report);
    final combination = report['combination_risks'] as Map<String, dynamic>?;
    final overlap = _extractOrgansUnderPressure(combination);

    final merged = {
      ...organs.map((item) => item.toString()),
      ...overlap.map((item) => item.toString()),
    }.where((item) => item.trim().isNotEmpty).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Organ impact',
            subtitle: 'Tap an organ to view the linked safety context.',
          ),
          const SizedBox(height: 12),
          if (merged.isEmpty)
            Text(
              ReportCopy.organImpactFallback(),
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: merged
                  .map(
                    (organ) => GestureDetector(
                      onTap: () => _showOrganDetails(context, organ, report),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.health_and_safety_outlined,
                              size: 16,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              organ,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          if (merged.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              ReportCopy.organImpactHint(),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  void _showOrganDetails(
    BuildContext context,
    String organ,
    Map<String, dynamic> report,
  ) {
    final details = report['organ_analysis'] ?? report['organ_global_analysis'];
    final detailText = details is Map ? details[organ]?.toString() : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: GlassCard(
            radius: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        organ,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  detailText?.trim().isNotEmpty == true
                      ? detailText!
                      : 'No detailed organ signal is available yet. We will enrich this section as verified evidence grows.',
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RiskGroupCard extends StatelessWidget {
  const _RiskGroupCard({
    required this.label,
    required this.rows,
    required this.color,
  });

  final String label;
  final List<_RiskRow> rows;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: rows
                .take(8)
                .map((r) => Chip(label: Text(r.name)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ProductSummaryCard extends StatelessWidget {
  const _ProductSummaryCard({required this.product});

  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    final bullets = <String>[];
    if (product.confidenceScore != null)
      bullets.add(
        'AI confidence: ${(product.confidenceScore! * 100).toStringAsFixed(0)}%',
      );
    if (product.investigationChemicals.isNotEmpty)
      bullets.add(
        '${product.investigationChemicals.length} ingredients flagged for review',
      );
    if (product.safeSkipIngredients.isNotEmpty)
      bullets.add(
        '${product.safeSkipIngredients.length} ingredients marked as safe',
      );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Quick summary',
            subtitle: 'Key signals to support a confident decision.',
          ),
          const SizedBox(height: 12),
          if (bullets.isEmpty)
            Text(
              ReportCopy.partialSummary(subject: 'product'),
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bullets
                  .map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: AppColors.muted),
                          const SizedBox(width: 10),
                          Expanded(child: Text(b)),
                        ],
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

String _humanizeRiskKey(String key) {
  final s = key.replaceAll('_', ' ').trim();
  if (s.isEmpty) return '';
  return s.substring(0, 1).toUpperCase() + s.substring(1);
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RiskLabel extends StatelessWidget {
  const _RiskLabel({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return RiskChip(level: level);
  }
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return _MetaChip(label: 'Confidence ${(value * 100).toStringAsFixed(0)}%');
  }
}

class _ConfidenceStrip extends StatelessWidget {
  const _ConfidenceStrip({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI confidence',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 10,
              backgroundColor: AppColors.softBlue.withValues(alpha: 0.35),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskRow {
  const _RiskRow(this.name, this.level);

  final String name;
  final String level;
}

class _ChemicalInsight {
  const _ChemicalInsight({
    required this.name,
    this.riskLevel,
    this.scientificNote,
    this.effects,
    this.organImpact,
  });

  final String name;
  final String? riskLevel;
  final String? scientificNote;
  final String? effects;
  final String? organImpact;
}

List<_RiskRow> _riskRows(Map<String, dynamic> report) {
  // Backend returns chemicals as a simple list of strings in filteringReport
  // Convert them to risk rows (chemicals are risky by definition in the filtering report)
  final source =
      report['chemicals'] ??
      report['ingredient_risk_categorization'] ??
      report['risk_categories'] ??
      report['risk_breakdown'] ??
      report['risky_ingredients'] ??
      report['ingredients'];

  if (source is List && source.isNotEmpty) {
    // If items are strings, treat them as High risk by default (they're in the chemicals list)
    final stringItems = source.whereType<String>().toList();
    if (stringItems.isNotEmpty) {
      return stringItems.map((chemical) {
        return _RiskRow(chemical, 'High');
      }).toList();
    }

    // If items are maps, extract name and risk level
    return source.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return _RiskRow(
        (map['name'] ??
                map['ingredient'] ??
                map['label'] ??
                map['chemical'] ??
                'Ingredient')
            .toString(),
        (map['risk'] ??
                map['level'] ??
                map['category'] ??
                map['status'] ??
                map['risk_level'] ??
                'High')
            .toString(),
      );
    }).toList();
  }

  if (source is Map && source.isNotEmpty) {
    return source.entries.map((entry) {
      return _RiskRow(entry.key.toString(), entry.value.toString());
    }).toList();
  }

  return const [];
}

List<_ChemicalInsight> _chemicalInsights(Map<String, dynamic> report) {
  // First try structured chemical lists
  final source =
      report['chemicals'] ??
      report['analysis'] ??
      report['findings'] ??
      report['items'] ??
      report['chemical_analysis'] ??
      report['risky_chemicals'] ??
      report['investigated_chemicals'];

  if (source is List && source.isNotEmpty) {
    return source.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return _ChemicalInsight(
        name:
            (map['name'] ??
                    map['chemical'] ??
                    map['title'] ??
                    map['ingredient'] ??
                    'Chemical')
                .toString(),
        riskLevel:
            (map['risk'] ??
                    map['level'] ??
                    map['severity'] ??
                    map['risk_level'])
                ?.toString(),
        scientificNote:
            (map['scientific_info'] ??
                    map['scientific_note'] ??
                    map['evidence'] ??
                    map['note'] ??
                    map['description'])
                ?.toString(),
        effects:
            (map['effects'] ??
                    map['effects_on_health'] ??
                    map['potential_effects'] ??
                    map['health_effects'])
                ?.toString(),
        organImpact:
            (map['organs'] ??
                    map['organ_impact'] ??
                    map['targets'] ??
                    map['affected_organs'])
                ?.toString(),
      );
    }).toList();
  }

  if (source is Map && source.isNotEmpty) {
    return source.entries.map((entry) {
      return _ChemicalInsight(
        name: entry.key.toString(),
        scientificNote: entry.value.toString(),
      );
    }).toList();
  }

  // Fall back to summary map - backend provides this in investigationReport
  final summary = report['summary'];
  if (summary is Map && (summary as Map).isNotEmpty) {
    return (summary as Map).entries.map((entry) {
      return _ChemicalInsight(
        name: entry.key.toString(),
        scientificNote: entry.value.toString(),
      );
    }).toList();
  }

  return const [];
}

List<String> _organImpact(Map<String, dynamic> report) {
  final source =
      report['organ_impact'] ??
      report['organ_impacts'] ??
      report['affected_organs'] ??
      report['organs'] ??
      report['organ_analysis'] ??
      report['organs_under_pressure'];

  if (source is List && source.isNotEmpty) {
    return source
        .map((entry) => entry.toString())
        .where((entry) => entry.trim().isNotEmpty)
        .toList();
  }
  if (source is Map && source.isNotEmpty) {
    return source.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .toList();
  }
  if (source is String && source.trim().isNotEmpty) {
    return [source.trim()];
  }
  return const [];
}

List<String> _extractOrgansUnderPressure(Map<String, dynamic>? combination) {
  if (combination == null) return const [];

  final organOverlap = combination['organ_overlap'] as Map?;
  if (organOverlap == null) return const [];

  final overlappingOrgans = organOverlap['overlapping_organs'];
  if (overlappingOrgans is List) {
    return overlappingOrgans
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  return const [];
}
