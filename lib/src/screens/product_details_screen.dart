import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../models.dart';
import '../ui/ui_kit.dart';
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
                      'Product details',
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
                subtitle: '${product.category.label} • ${product.extractionLabel} • ${product.decisionLabel}',
                imageUrl: product.imageUrl,
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
                      _MetaChip(label: 'Updated ${product.updatedAt!.day.toString().padLeft(2, '0')}/${product.updatedAt!.month.toString().padLeft(2, '0')}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 920;
                  final filterSection = _FilterReportCard(product: product);
                  final investigationSection = _InvestigationReportCard(product: product);

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
    final combination = product.investigationReport['combination_risks'] as Map<String, dynamic>?;
    final organsUnderPressure = _extractOrgansUnderPressure(combination);

    return Column(
      children: [
        // Organs under pressure
        if (organsUnderPressure.isNotEmpty) ...[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  title: 'Organs under pressure',
                  subtitle: 'Potential cumulative health impact.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: organsUnderPressure
                      .map(
                        (organ) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_rounded, size: 16, color: AppColors.danger),
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
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Risk analysis from LLM
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                title: 'AI Risk Analysis',
                subtitle: 'Machine learning assessment based on chemical profile.',
              ),
              const SizedBox(height: 12),
              _RiskAnalysisPanel(report: report),
            ],
          ),
        ),
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
      return const Text(
        'No detailed risk analysis available.',
        style: TextStyle(color: AppColors.muted),
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
        final value = entry.value?.toString() ?? 'N/A';

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
                key.replaceAll('_', ' ').replaceAll(RegExp(r'([A-Z])'), ' \$1').trim(),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterReportCard extends StatefulWidget {
  const _FilterReportCard({required this.product});

  final ProductItem product;

  @override
  State<_FilterReportCard> createState() => _FilterReportCardState();
}

class _FilterReportCardState extends State<_FilterReportCard> {
  String? _expandedChemical;

  @override
  Widget build(BuildContext context) {
    final sections = _riskRows(widget.product.filteringReport);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Filter report',
            subtitle: 'Ingredients to skip, investigate, and classify by risk.',
          ),
          const SizedBox(height: 14),
          _ChipBlock(
            title: 'Safe to skip',
            values: widget.product.safeSkipIngredients,
            color: AppColors.success,
            fallback: 'No ingredient was explicitly marked safe to skip yet.',
            isClickable: false,
          ),
          const SizedBox(height: 14),
          _ChipBlock(
            title: 'Investigate further',
            values: widget.product.investigationChemicals,
            color: AppColors.warning,
            fallback: 'No chemical has been flagged for deeper review yet.',
            isClickable: true,
            report: widget.product.investigationReport,
          ),
          const SizedBox(height: 14),
          Text(
            'Ingredient risk categorization',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (sections.isEmpty)
            const Text(
              'The backend did not provide a structured risk table. The overall product risk score is still shown above.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            )
          else
            ...sections.map(
              (row) => GestureDetector(
                onTap: () => setState(() => _expandedChemical = _expandedChemical == row.name ? null : row.name),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _expandedChemical == row.name 
                          ? AppColors.warning.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _expandedChemical == row.name 
                            ? AppColors.warning.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      row.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _RiskLabel(level: row.level),
                                ],
                              ),
                              if (_expandedChemical == row.name) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Tap again to collapse',
                                  style: TextStyle(fontSize: 12, color: AppColors.muted, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_expandedChemical == row.name)
                          const Icon(Icons.expand_less_rounded, color: AppColors.ink)
                        else
                          const Icon(Icons.expand_more_rounded, color: AppColors.muted, size: 20),
                      ],
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

class _InvestigationReportCard extends StatelessWidget {
  const _InvestigationReportCard({required this.product});

  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    final insights = _chemicalInsights(product.investigationReport);
    final organs = _organImpact(product.investigationReport);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Investigation report',
            subtitle: 'AI analysis, known scientific context, and organ impact.',
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
              product.aiSummary,
              style: const TextStyle(height: 1.45, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 14),
          if (product.confidenceScore != null)
            _ConfidenceStrip(value: product.confidenceScore!),
          if (product.confidenceScore != null) const SizedBox(height: 14),
          Text(
            'Scientific notes by chemical',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (insights.isEmpty)
            const Text(
              'No structured chemical notes were provided by the backend yet.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            )
          else
            ...insights.take(6).map(
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
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (item.riskLevel != null) _RiskLabel(level: item.riskLevel!),
                        ],
                      ),
                      if (item.scientificNote != null) ...[
                        const SizedBox(height: 6),
                        Text(item.scientificNote!, style: const TextStyle(height: 1.4, color: AppColors.muted)),
                      ],
                      if (item.effects != null) ...[
                        const SizedBox(height: 6),
                        Text('Potential effects: ${item.effects!}', style: const TextStyle(height: 1.4)),
                      ],
                      if (item.organImpact != null) ...[
                        const SizedBox(height: 6),
                        Text('Organs: ${item.organImpact!}', style: const TextStyle(height: 1.4)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Organ impact',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (organs.isEmpty)
            const Text(
              'No organ impact signal is available yet.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: organs
                  .map(
                    (organ) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        organ,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
            subtitle: 'All available metadata for the selected product.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: product.category.label),
              _MetaChip(label: product.extractionLabel),
              _MetaChip(label: product.barcode.isEmpty ? 'No barcode' : 'Barcode ${product.barcode}'),
              _MetaChip(label: product.riskLevel),
            ],
          ),
          if (ingredients.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Ingredients',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ingredients.map((ingredient) => Chip(label: Text(ingredient))).toList(),
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (values.isEmpty)
          Text(fallback, style: const TextStyle(color: AppColors.muted, height: 1.45))
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                            Icon(Icons.info_outline, size: 14, color: color.withValues(alpha: 0.7)),
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

  void _showChemicalDetails(BuildContext context, String chemicalName, Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => _ChemicalDetailsSheet(
        chemicalName: chemicalName,
        report: report,
      ),
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
    final details = summary?[chemicalName]?.toString() ?? 'No details available';

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
                        'Chemical Details',
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
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
              const Text('AI confidence', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('${(value * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w700)),
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
  final source = report['chemicals'] ??
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
        (map['name'] ?? map['ingredient'] ?? map['label'] ?? map['chemical'] ?? 'Ingredient').toString(),
        (map['risk'] ?? map['level'] ?? map['category'] ?? map['status'] ?? map['risk_level'] ?? 'High').toString(),
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
  final source = report['chemicals'] ??
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
        name: (map['name'] ?? map['chemical'] ?? map['title'] ?? map['ingredient'] ?? 'Chemical').toString(),
        riskLevel: (map['risk'] ?? map['level'] ?? map['severity'] ?? map['risk_level'])?.toString(),
        scientificNote: (map['scientific_info'] ?? map['scientific_note'] ?? map['evidence'] ?? map['note'] ?? map['description'])?.toString(),
        effects: (map['effects'] ?? map['effects_on_health'] ?? map['potential_effects'] ?? map['health_effects'])?.toString(),
        organImpact: (map['organs'] ?? map['organ_impact'] ?? map['targets'] ?? map['affected_organs'])?.toString(),
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
  final source = report['organ_impact'] ??
      report['organ_impacts'] ??
      report['affected_organs'] ??
      report['organs'] ??
      report['organ_analysis'] ??
      report['organs_under_pressure'];

  if (source is List && source.isNotEmpty) {
    return source.map((entry) => entry.toString()).where((entry) => entry.trim().isNotEmpty).toList();
  }
  if (source is Map && source.isNotEmpty) {
    return source.entries.map((entry) => '${entry.key}: ${entry.value}').toList();
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