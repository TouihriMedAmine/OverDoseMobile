import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../models.dart';
import '../ui/ui_kit.dart';

class RecommendationsListScreen extends StatefulWidget {
  const RecommendationsListScreen({
    super.key,
    required this.product,
  });

  final ProductItem product;

  @override
  State<RecommendationsListScreen> createState() =>
      _RecommendationsListScreenState();
}

class _RecommendationsListScreenState extends State<RecommendationsListScreen> {
  late Future<SearchAlternativesResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppController>().searchAlternatives(widget.product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: buildPageBackground(),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Alternatives',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<SearchAlternativesResponse>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: EmptyStateCard(
                            title: 'Search unavailable',
                            message: snapshot.error.toString(),
                            icon: Icons.travel_explore_outlined,
                            action: FilledButton.tonal(
                              onPressed: () => setState(() {
                                _future = context
                                    .read<AppController>()
                                    .searchAlternatives(widget.product);
                              }),
                              child: const Text('Retry'),
                            ),
                          ),
                        ),
                      );
                    }

                    final response = snapshot.data!;
                    final suggestions = response.suggestions;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                          HighlightBanner(
                            title: widget.product.name,
                            subtitle:
                                'Alternatives that may reduce ${widget.product.riskLevel.toLowerCase()} risk or offer a safer comparison.',
                            icon: Icons.eco_outlined,
                            colors: const [AppColors.softBlue, AppColors.softPeach],
                          ),
                        const SizedBox(height: 16),
                        if (suggestions.isEmpty)
                          EmptyStateCard(
                            title: 'No usable alternatives yet',
                            message: response.errors.isNotEmpty
                                ? response.errors.join(' | ')
                                : 'The analysis service did not return a usable suggestion for this product.',
                            icon: Icons.search_off_rounded,
                          )
                        else
                          ...suggestions.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (item.subtitle.trim().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.subtitle,
                                        style: const TextStyle(color: AppColors.muted),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                      Text(item.reason),
                                      if ((item.price ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          'Price: ${item.price}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.ink,
                                          ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
