import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app_config.dart';
import '../app_controller.dart';
import '../models.dart';

class SegmentationScreen extends StatefulWidget {
  const SegmentationScreen({super.key, required this.imageFile});

  /// Fichier image transmis depuis [ScanScreen].
  /// [XFile] fonctionne sur Web (blob URL) et sur mobile (chemin filesystem).
  final XFile imageFile;

  @override
  State<SegmentationScreen> createState() => _SegmentationScreenState();
}

class _SegmentationScreenState extends State<SegmentationScreen> {
  late Future<SegmentationBatch> _futureBatch;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    final controller = context.read<AppController>();
    _futureBatch = controller.segmentImage(widget.imageFile);
    _futureBatch.then((batch) {
      if (!mounted || _selectedIds.isNotEmpty) return;
      setState(() {
        _selectedIds.addAll(batch.products.map((p) => p.productId));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select products')),
      body: FutureBuilder<SegmentationBatch>(
        future: _futureBatch,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              error: snapshot.error.toString(),
              onRetry: () => setState(() {
                final controller = context.read<AppController>();
                _futureBatch = controller.segmentImage(widget.imageFile);
              }),
            );
          }

          final batch = snapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${batch.totalProducts} product(s) detected',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mode ${batch.segmentationMode}. Select one or more crops to analyze.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _XFileImage(
                            xfile: widget.imageFile,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.84,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: batch.products.length,
                  itemBuilder: (context, index) {
                    final product = batch.products[index];
                    final selected = _selectedIds.contains(product.productId);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _selectedIds.remove(product.productId);
                        } else {
                          _selectedIds.add(product.productId);
                        }
                      }),
                      child: _SegmentCard(product: product, selected: selected),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  child: FilledButton(
                    onPressed:
                        _selectedIds.isEmpty ||
                            context.watch<AppController>().isBusy
                        ? null
                        : () => _submit(batch.sessionId),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Analyze selection'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(String sessionId) async {
    final controller = context.read<AppController>();
    try {
      final results = await controller.analyzeSelected(
        sessionId: sessionId,
        productIds: _selectedIds.toList(),
      );

      if (!mounted) return;

      Navigator.of(context).pop(results);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: ${e.toString()}'),
          backgroundColor: const Color(0xFFB53F2F),
        ),
      );
    }
  }
}

/// Renders an [XFile] in a cross-platform way.
/// On Web: [Image.network] (the path is a blob URL).
/// On mobile/desktop: [Image.file] (the path is a filesystem path).
class _XFileImage extends StatelessWidget {
  const _XFileImage({required this.xfile, this.width, this.height, this.fit});

  final XFile xfile;
  final double? width;
  final double? height;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        xfile.path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image_outlined),
      );
    }
    return Image.file(
      File(xfile.path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image_outlined),
    );
  }
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({required this.product, required this.selected});

  final SegmentedProduct product;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? const Color(0xFF12372A) : const Color(0xFFE2DDD2),
          width: selected ? 2 : 1,
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: product.cropUrl.isNotEmpty
                  ? Image.network(
                      AppConfig.mediaUri(product.cropUrl).toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _FallbackPreview(label: product.label),
                    )
                  : _FallbackPreview(label: product.label),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(product.confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackPreview extends StatelessWidget {
  const _FallbackPreview({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3EFE5),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 42,
                  color: Color(0xFFB53F2F),
                ),
                const SizedBox(height: 12),
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
