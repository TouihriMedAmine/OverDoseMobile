import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../models.dart';
import '../ui/animated_widgets.dart';
import '../ui/transitions.dart';
import '../ui/ui_kit.dart';
import 'product_card_widgets.dart';
import 'product_details_screen.dart';
import 'recommendations_list_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _decisionFilter = 'all';
  String _riskFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final filtered = controller.products.where((product) {
      final decisionMatches = switch (_decisionFilter) {
        'all' => true,
        'active' =>
          product.userDecision == 'approved' || product.userDecision == 'saved',
        _ => product.userDecision == _decisionFilter,
      };
      final riskMatches = switch (_riskFilter) {
        'all' => true,
        'high' =>
          product.riskLevel == 'HIGH' || product.riskLevel == 'CRITICAL',
        'moderate' => product.riskLevel == 'MODERATE',
        'low' => product.riskLevel == 'LOW',
        _ => true,
      };
      return decisionMatches && riskMatches;
    }).toList();

    return RefreshIndicator(
      onRefresh: controller.refreshProducts,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          HighlightBanner(
            title: 'My products',
            subtitle:
                'Your active product memory with decisions, risk levels, and quick access to safer alternatives.',
            icon: Icons.inventory_2_outlined,
            colors: const [AppColors.softBlue, AppColors.softPeach],
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  title: '${controller.products.length} products',
                  subtitle: 'Filter by decision and risk level.',
                  trailing: IconButton(
                    onPressed: controller.isBusy
                        ? null
                        : controller.refreshProducts,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Decision'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterPill(
                      label: 'All',
                      active: _decisionFilter == 'all',
                      onTap: () => setState(() => _decisionFilter = 'all'),
                    ),
                    _FilterPill(
                      label: 'Active',
                      active: _decisionFilter == 'active',
                      onTap: () => setState(() => _decisionFilter = 'active'),
                    ),
                    _FilterPill(
                      label: 'Approved',
                      active: _decisionFilter == 'approved',
                      onTap: () => setState(() => _decisionFilter = 'approved'),
                    ),
                    _FilterPill(
                      label: 'Saved',
                      active: _decisionFilter == 'saved',
                      onTap: () => setState(() => _decisionFilter = 'saved'),
                    ),
                    _FilterPill(
                      label: 'Review',
                      active: _decisionFilter == 'pending',
                      onTap: () => setState(() => _decisionFilter = 'pending'),
                    ),
                    _FilterPill(
                      label: 'Rejected',
                      active: _decisionFilter == 'rejected',
                      onTap: () => setState(() => _decisionFilter = 'rejected'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Risk level'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterPill(
                      label: 'All',
                      active: _riskFilter == 'all',
                      onTap: () => setState(() => _riskFilter = 'all'),
                    ),
                    _FilterPill(
                      label: 'High',
                      active: _riskFilter == 'high',
                      onTap: () => setState(() => _riskFilter = 'high'),
                    ),
                    _FilterPill(
                      label: 'Moderate',
                      active: _riskFilter == 'moderate',
                      onTap: () => setState(() => _riskFilter = 'moderate'),
                    ),
                    _FilterPill(
                      label: 'Low',
                      active: _riskFilter == 'low',
                      onTap: () => setState(() => _riskFilter = 'low'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const EmptyStateCard(
              title: 'No products match',
              message:
                  'Try a different filter or scan new products to add them here.',
              icon: Icons.filter_alt_off_outlined,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width < 420
                    ? 1
                    : width < 900
                    ? 2
                    : 3;
                final cardHeight = crossAxisCount == 1 ? 360.0 : 390.0;
                final imageRatio = crossAxisCount == 1 ? 1.7 : 1.2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: cardHeight,
                  ),
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return _ProductCard(
                      product: product,
                      imageAspectRatio: imageRatio,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.imageAspectRatio});

  final ProductItem product;
  final double imageAspectRatio;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: ProductInsightCard(
        title: product.displayTitle,
        subtitle: '${product.category.label} • ${product.extractionLabel}',
        imageUrl: product.imageUrl,
        imageAspectRatio: imageAspectRatio,
        status: RiskChip(level: product.riskLevel),
        previewAlternatives: product.previewAlternatives,
        leadingIcon: product.category == ProductCategory.food
            ? Icons.restaurant_outlined
            : Icons.spa_outlined,
        onTap: () {
          Navigator.of(context).push(
            SlideRightRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        },
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DecisionChip(label: product.decisionLabel, active: true),
                if (product.updatedAt != null)
                  Chip(
                    label: Text(
                      'Updated ${DateFormat('dd MMM').format(product.updatedAt!)}',
                    ),
                  ),
              ],
            ),
            if (product.userDecisionNotes.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                product.userDecisionNotes,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => _openDecisionSheet(context),
                    child: const Text('Decision'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: product.isHighRisk
                        ? () {
                            Navigator.of(context).push(
                              SlideRightRoute(
                                builder: (_) =>
                                    RecommendationsListScreen(product: product),
                              ),
                            );
                          }
                        : null,
                    child: const Text('Alternatives'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDecisionSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: GlassCard(
            radius: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.displayTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                  const Text('Choose the decision you want to save.'),
                  const SizedBox(height: 16),
                  ...[
                  ('approved', 'Adopt'),
                  ('saved', 'Save'),
                  ('rejected', 'Reject'),
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton.tonal(
                      onPressed: () async {
                        await context.read<AppController>().setProductDecision(
                          productId: product.id,
                          decision: item.$1,
                        );
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(item.$2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecisionChip(label: label, active: active),
    );
  }
}
