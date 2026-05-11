import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../models.dart';
import '../ui/report_copy.dart';
import '../ui/ui_kit.dart';
import 'product_card_widgets.dart';

Future<void> showScanResultSheet(
  BuildContext context, {
  required List<Map<String, dynamic>> results,
}) async {
  if (results.isEmpty) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ScanResultSheet(results: results),
  );
}

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key, this.results});

  final List<Map<String, dynamic>>? results;

  @override
  Widget build(BuildContext context) {
    final items = results ?? const <Map<String, dynamic>>[];
    return Scaffold(
      body: Container(
        decoration: buildPageBackground(),
        child: SafeArea(
          child: items.isEmpty
              ? const Center(
                  child: EmptyStateCard(
                    title: 'No results yet',
                    message: 'The scan did not return usable data.',
                  ),
                )
              : _ScanResultSheet(results: items, embedded: true),
        ),
      ),
    );
  }
}

class _ScanResultSheet extends StatelessWidget {
  const _ScanResultSheet({required this.results, this.embedded = false});

  final List<Map<String, dynamic>> results;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: embedded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (!embedded)
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: SectionTitle(
            title: ReportCopy.aiSafetyOverviewLabel(),
            subtitle: '${results.length} product(s) analyzed',
            trailing: embedded
                ? IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  )
                : null,
          ),
        ),
        Expanded(
          child: ListView.separated(
            shrinkWrap: embedded,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _ResultCard(result: results[index]),
          ),
        ),
      ],
    );

    if (embedded) return child;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.58,
      maxChildSize: 0.94,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFDF9F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(top: 10, bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: SectionTitle(
                  title: ReportCopy.aiSafetyOverviewLabel(),
                  subtitle: '${results.length} product(s) analyzed',
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _ResultCard(result: results[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final productName =
        result['name']?.toString() ??
        result['product_name']?.toString() ??
        'Analyzed product';
    final brand = result['brand']?.toString() ?? '';
    final imageUrl = result['source_image_path']?.toString();
    final analysis = result['analysis'] is Map
        ? Map<String, dynamic>.from(result['analysis'] as Map)
        : const <String, dynamic>{};
    final ingredients = (result['ingredients'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    final riskLevel = deriveRiskLevelFromPayload(result);
    final recommendations =
        (result['recommendations'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.trim().isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 1.65,
                child: resolveProductImageProvider(imageUrl) == null
                    ? Container(
                        color: AppColors.softBlue.withValues(alpha: 0.28),
                        alignment: Alignment.center,
                        child: const Icon(Icons.science_outlined, size: 44),
                      )
                    : Image(
                        image: resolveProductImageProvider(imageUrl)!,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            brand.trim().isEmpty ? productName : '$brand • $productName',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _PulsingRiskChip(level: riskLevel),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _recommendationFromRisk(riskLevel),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if ((analysis['summary'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.softBlue.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                analysis['summary'].toString(),
                style: const TextStyle(height: 1.45),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              ReportCopy.minimalSummary(subject: 'this scan result'),
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
          ],
          const SizedBox(height: 12),
          Text(_shortExplanation(riskLevel, ingredients.length)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _saveWithDecision(context, result, 'approved');
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Keep'),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _saveWithDecision(context, result, 'saved');
                },
                icon: const Icon(Icons.bookmark_border),
                label: const Text('Save'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(Icons.close),
                label: const Text('Dismiss'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Analysis details'),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            children: [
              if (recommendations.isNotEmpty && riskLevel != 'LOW') ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Alternatives and suggestions',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                ...recommendations
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '• ${(item['product'] ?? 'Alternative').toString()}: ${(item['reason'] ?? '').toString()}',
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
              ],
              if (ingredients.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('No ingredients were extracted.'),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ingredients
                        .take(20)
                        .map((i) => Chip(label: Text(i)))
                        .toList(),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveWithDecision(
    BuildContext context,
    Map<String, dynamic> result,
    String decision,
  ) async {
    final controller = context.read<AppController>();
    try {
      final savedProduct = await controller.saveAnalyzedProduct(result);
      await controller.setProductDecision(
        productId: savedProduct.id,
        decision: decision,
      );

      if (!context.mounted) return;
      controller.clearLastScanPayload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved and dashboard updated.')),
      );
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save: $error')));
    }
  }
}

String _recommendationFromRisk(String risk) {
  return switch (risk) {
    'CRITICAL' => 'Avoid this product for now',
    'HIGH' => 'Not recommended, seek alternatives',
    'MODERATE' => 'Use with caution and monitor',
    'LOW' => 'Generally acceptable based on current data',
    _ => 'Insufficient data, review details for context',
  };
}

String _shortExplanation(String risk, int ingredientCount) {
  return switch (risk) {
    'CRITICAL' =>
      'Strong risk signals were detected. A prompt decision is recommended.',
    'HIGH' => 'High-risk ingredients were detected in the available data.',
    'MODERATE' => 'Some elements should be monitored based on your profile.',
    'LOW' =>
      'No major signals detected with the extracted data ($ingredientCount ingredients).',
    _ => 'The system needs more verified data to conclude precisely.',
  };
}

/// RiskChip with pulsing animation for CRITICAL and HIGH levels.
class _PulsingRiskChip extends StatefulWidget {
  const _PulsingRiskChip({required this.level});
  final String level;

  @override
  State<_PulsingRiskChip> createState() => _PulsingRiskChipState();
}

class _PulsingRiskChipState extends State<_PulsingRiskChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  bool get _shouldPulse {
    final lvl = widget.level.toUpperCase();
    return lvl == 'CRITICAL' || lvl == 'HIGH';
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (_shouldPulse) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldPulse) return RiskChip(level: widget.level);
    return ScaleTransition(
      scale: _scale,
      child: RiskChip(level: widget.level),
    );
  }
}
