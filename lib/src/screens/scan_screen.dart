import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../models.dart';
import '../ui/animated_widgets.dart';
import '../ui/transitions.dart';
import '../ui/ui_kit.dart';
import '../ui/report_copy.dart';
import 'product_card_widgets.dart';
import 'scan_result_screen.dart';
import 'segmentation_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  XFile? _selectedImage;
  final List<XFile> _queue = [];
  bool _isPicking = false;
  bool _isRunningScan = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final history = controller.scanHistory;

    return RefreshIndicator(
      onRefresh: () async {
        await controller.refreshProducts(silent: true);
        await controller.refreshCumulativeSummary(silent: true);
      },
      color: AppColors.ink,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          HighlightBanner(
            title: 'AI Scan Studio',
            subtitle:
                'Capture one or more products, then get a single safety review without exposing the internal scan flow.',
            icon: Icons.center_focus_strong_outlined,
            colors: const [Color(0xFFDCE9FF), Color(0xFFF7C8A6)],
          ),
          const SizedBox(height: 16),
          _ScanStudioHero(
            queueCount: _queue.length,
            isPicking: _isPicking || controller.isBusy || _isRunningScan,
            isRunningScan: _isRunningScan,
            onCamera: () => _addToQueue(ImageSource.camera),
            onGallery: () =>
                _addToQueue(ImageSource.gallery, allowMultiple: true),
            onAnalyze: _queue.isEmpty || _isRunningScan
                ? null
                : _runQueueAnalysis,
            onClear: _queue.isEmpty || _isRunningScan ? null : _clearQueue,
          ),
          const SizedBox(height: 16),
          _QueuePanel(
            items: _queue,
            onRemove: _isRunningScan ? null : _removeFromQueue,
          ),
          const SizedBox(height: 16),
          if (history.isNotEmpty) ...[
            _RecentReportsPanel(
              history: history,
              onOpen: _openHistoryReport,
              onDelete: _isRunningScan
                  ? null
                  : (record) => controller.removeScanReport(record.id),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    // Camera not available on Flutter Web
    if (kIsWeb && source == ImageSource.camera) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Camera is not available in the browser. Use Gallery instead.',
            ),
            backgroundColor: Color(0xFF8B6914),
          ),
        );
      }
      return;
    }

    setState(() => _isPicking = true);

    try {
      final file = await _picker.pickImage(source: source, imageQuality: 92);
      if (file != null && mounted) {
        setState(() => _selectedImage = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to access media: ${e.toString()}'),
            backgroundColor: const Color(0xFFB53F2F),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _addToQueue(
    ImageSource source, {
    bool allowMultiple = false,
  }) async {
    if (allowMultiple && source == ImageSource.gallery) {
      await _addMultipleFromGallery();
      return;
    }

    await _pickImage(source);
    final image = _selectedImage;
    if (image == null) return;
    setState(() {
      _queue.add(image);
      _selectedImage = null;
    });
  }

  Future<void> _addMultipleFromGallery() async {
    setState(() => _isPicking = true);
    try {
      final files = await _picker.pickMultiImage(imageQuality: 92);
      if (files.isNotEmpty && mounted) {
        setState(() {
          _queue.addAll(files);
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to access media: ${error.toString()}'),
            backgroundColor: const Color(0xFFB53F2F),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  void _removeFromQueue(int index) {
    setState(() {
      _queue.removeAt(index);
    });
  }

  void _clearQueue() {
    setState(() {
      _queue.clear();
    });
  }

  void _openHistoryReport(ScanReportRecord record) {
    Navigator.of(context).push(
      SlideRightRoute(
        builder: (_) => ScanResultScreen(results: record.results),
      ),
    );
  }

  Future<void> _runQueueAnalysis() async {
    if (_queue.isEmpty || _isRunningScan) return;

    setState(() => _isRunningScan = true);
    final controller = context.read<AppController>();
    final results = <Map<String, dynamic>>[];

    try {
      for (final image in _queue) {
        final response = await controller.quickScanImage(image);

        final payload = {
          ...(response.analysis ?? <String, dynamic>{}),
          'product_id': response.scanId.toString(),
          'ingredients': response.ingredients,
          'risks': response.risks,
          'recommendations': response.recommendations,
          'cumulative_report': response.cumulativeReport,
          'source_image_path': image.path,
        };
        results.add(payload);
      }

      if (!mounted) return;

      controller.setLastScanPayload(results);
      await controller.recordScanReport(
        results: results,
        sourceImagePath: _queue.first.path,
        title: results.isNotEmpty
            ? (results.first['name']?.toString() ??
                  results.first['product_name']?.toString())
            : null,
      );

      await showScanResultSheet(context, results: results);

      if (!mounted) return;
      setState(() => _queue.clear());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: ${error.toString()}'),
            backgroundColor: const Color(0xFFB53F2F),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRunningScan = false);
      }
    }
  }

  Future<void> _openSegmentationFlow() async {
    final image = _selectedImage;
    if (image == null) return;

    List<dynamic>? result;
    try {
      result = await Navigator.of(context).push<List<dynamic>>(
        SlideUpRoute(builder: (_) => SegmentationScreen(imageFile: image)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selection failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFB53F2F),
          ),
        );
      }
      return;
    }

    if (!mounted || result == null || result.isEmpty) return;

    final payload = result.cast<Map<String, dynamic>>();
    context.read<AppController>().setLastScanPayload(payload);
    await showScanResultSheet(context, results: payload);
  }

  Future<void> _runQuickScan() async {
    final image = _selectedImage;
    if (image == null) return;

    final controller = context.read<AppController>();
    try {
      final response = await controller.quickScanImage(image);
      if (!mounted) return;

      final payload = [
        {
          ...(response.analysis ?? <String, dynamic>{}),
          'product_id': response.scanId.toString(),
          'ingredients': response.ingredients,
          'risks': response.risks,
          'recommendations': response.recommendations,
          'cumulative_report': response.cumulativeReport,
        },
      ];

      controller.setLastScanPayload(payload);
      await showScanResultSheet(context, results: payload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFB53F2F),
          ),
        );
      }
    }
  }
}

/// Retourne un [ImageProvider] compatible Web et mobile pour un [XFile].
ImageProvider _xFileImageProvider(XFile file) {
  if (kIsWeb) {
    // Sur Web, le path est une blob URL directement utilisable par le navigateur
    return NetworkImage(file.path);
  }
  // Sur mobile/desktop, c'est un chemin système de fichiers
  return FileImage(File(file.path));
}

class _ScanHero extends StatelessWidget {
  const _ScanHero({
    required this.selectedImage,
    required this.isPicking,
    required this.onCamera,
    required this.onGallery,
    required this.onAnalyze,
    required this.onQuickScan,
  });

  final XFile? selectedImage;
  final bool isPicking;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onAnalyze;
  final VoidCallback? onQuickScan;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(0xFFF5EEE8),
              image: selectedImage == null
                  ? null
                  : DecorationImage(
                      image: _xFileImageProvider(selectedImage!),
                      fit: BoxFit.cover,
                    ),
            ),
            child: selectedImage == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PulsingDot(
                          color: AppColors.ink.withValues(alpha: 0.35),
                          size: 14,
                        ),
                        const SizedBox(height: 16),
                        const Icon(
                          Icons.camera_enhance_outlined,
                          size: 42,
                          color: AppColors.ink,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Capture a product photo or import one',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (isPicking || kIsWeb) ? null : onCamera,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(kIsWeb ? 'Camera unavailable' : 'Camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPicking ? null : onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAnalyze,
            icon: const Icon(Icons.grid_view_rounded),
            label: const Text('Select products'),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: onQuickScan,
            icon: const Icon(Icons.flash_on_outlined),
            label: const Text('Quick scan'),
          ),
        ],
      ),
    );
  }
}

class _ScanStudioHero extends StatelessWidget {
  const _ScanStudioHero({
    required this.queueCount,
    required this.isPicking,
    required this.isRunningScan,
    required this.onCamera,
    required this.onGallery,
    required this.onAnalyze,
    required this.onClear,
  });

  final int queueCount;
  final bool isPicking;
  final bool isRunningScan;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onAnalyze;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overdose AI Lab',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Capture products and launch a single trusted AI safety review.',
                      style: TextStyle(color: AppColors.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              _ScanStatusChip(
                label: isRunningScan ? 'Analyzing' : '$queueCount queued',
              ),
            ],
          ),
          if (isRunningScan) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(minHeight: 4),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.softBlue.withValues(alpha: 0.45),
                  AppColors.softPeach.withValues(alpha: 0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.center_focus_strong,
                    size: 30,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready for analysis',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        ReportCopy.scanAnalysisHint(),
                        style: TextStyle(color: AppColors.muted, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPicking ? null : onCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPicking ? null : onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAnalyze,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Analyze queue'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_all_outlined),
                  label: const Text('Clear queue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QueuePanel extends StatelessWidget {
  const _QueuePanel({required this.items, required this.onRemove});

  final List<XFile> items;
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Scan queue',
            subtitle: items.isEmpty
                ? 'Add products to begin.'
                : '${items.length} item(s) ready for analysis.',
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            EmptyStateCard(
              title: 'Queue empty',
              message: ReportCopy.queueEmpty(),
              icon: Icons.queue_outlined,
            )
          else
            ...items.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _QueuedScanItem(
                  file: entry.value,
                  index: entry.key,
                  onRemove: onRemove == null
                      ? null
                      : () => onRemove!(entry.key),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QueuedScanItem extends StatelessWidget {
  const _QueuedScanItem({
    required this.file,
    required this.index,
    this.onRemove,
  });

  final XFile file;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final image = resolveProductImageProvider(file.path);
    final fileName = file.name.trim().isNotEmpty
        ? file.name
        : 'Queued product ${index + 1}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF4F7FF), Color(0xFFFFF1E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: image == null
                    ? null
                    : DecorationImage(image: image, fit: BoxFit.cover),
              ),
              child: image == null
                  ? const Icon(
                      Icons.document_scanner_outlined,
                      color: AppColors.ink,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ready for AI ingredient extraction and safety review.',
                  style: TextStyle(
                    color: AppColors.muted,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

class _RecentReportsPanel extends StatelessWidget {
  const _RecentReportsPanel({
    required this.history,
    required this.onOpen,
    required this.onDelete,
  });

  final List<ScanReportRecord> history;
  final ValueChanged<ScanReportRecord> onOpen;
  final ValueChanged<ScanReportRecord>? onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Recent scan reports',
            subtitle: 'Reopen previous AI safety reviews anytime.',
          ),
          const SizedBox(height: 14),
          ...history
              .take(4)
              .map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.softBlue.withValues(alpha: 0.36),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${record.results.length} result(s) • ${record.createdAt.toLocal().toString().substring(0, 16)}',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => onOpen(record),
                          child: const Text('Open'),
                        ),
                        if (onDelete != null)
                          IconButton(
                            onPressed: () => onDelete!(record),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
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

class _AiProcessingDialog extends StatefulWidget {
  const _AiProcessingDialog({required this.imageFile});

  final XFile imageFile;

  @override
  State<_AiProcessingDialog> createState() => _AiProcessingDialogState();
}

class _AiProcessingDialogState extends State<_AiProcessingDialog> {
  static const _messages = [
    'Analyzing ingredients...',
    'Extracting chemical data...',
    'AI is investigating chemical interactions...',
    'Generating safety report...',
  ];

  int _step = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 850), (timer) {
      if (!mounted) return;
      setState(() {
        if (_step < _messages.length - 1) {
          _step++;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.coronavirus_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'OVERDOSE',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 1.6,
                child:
                    resolveProductImageProvider(widget.imageFile.path) == null
                    ? Container(
                        color: AppColors.softBlue.withValues(alpha: 0.24),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image(
                            image: resolveProductImageProvider(
                              widget.imageFile.path,
                            )!,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            color: Colors.black.withValues(alpha: 0.18),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const PulsingDot(color: AppColors.ink),
            const SizedBox(height: 10),
            Text(
              _messages[_step],
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'We extract ingredients first, then layer in AI safety reasoning.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanStatusChip extends StatelessWidget {
  const _ScanStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.index,
    required this.title,
    required this.subtitle,
  });

  final String index;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.ink,
          child: Text(
            index,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingDialog extends StatefulWidget {
  const _LoadingDialog({required this.title});

  final String title;

  @override
  State<_LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<_LoadingDialog> {
  int _step = 0;
  static const _messages = [
    'Extracting ingredients',
    'Assessing risk signals',
    'Adapting to your profile',
    'Looking for safer options',
  ];

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted || _step >= _messages.length - 1) return false;
      setState(() => _step++);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              _messages[_step],
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
