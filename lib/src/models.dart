import 'package:flutter/foundation.dart';

enum ProductCategory { food, cosmetic, unknown }

extension ProductCategoryX on ProductCategory {
  String get label => switch (this) {
    ProductCategory.food => 'Food',
    ProductCategory.cosmetic => 'Cosmetics',
    ProductCategory.unknown => 'Other',
  };

  String get recommendationType => switch (this) {
    ProductCategory.food => 'food',
    ProductCategory.cosmetic => 'cosmetics',
    ProductCategory.unknown => 'cosmetics',
  };

  static ProductCategory fromApi(String? value) {
    final normalized = (value ?? '').toLowerCase();
    return switch (normalized) {
      'food' => ProductCategory.food,
      'cosmetic' => ProductCategory.cosmetic,
      _ => ProductCategory.unknown,
    };
  }
}

extension StringCasingX on String {
  String get sentenceCase {
    if (trim().isEmpty) return this;
    final value = trim().toLowerCase();
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.age,
    required this.userType,
    required this.gender,
    required this.dateOfBirth,
    required this.notes,
    required this.aiReport,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final int? age;
  final String userType;
  final String gender;
  final DateTime? dateOfBirth;
  final String notes;
  final Map<String, dynamic> aiReport;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName {
    final combined = [
      firstName,
      lastName,
    ].where((value) => value.trim().isNotEmpty).join(' ').trim();
    return combined.isEmpty ? email : combined;
  }

  String get userTypeLabel => userType.trim().isEmpty
      ? 'Not set'
      : userType.replaceAll('_', ' ').sentenceCase;

  bool get hasOnboardingData =>
      userType.trim().isNotEmpty ||
      aiReport.isNotEmpty ||
      notes.trim().isNotEmpty;

  String? get personalizedSummary => _firstNonEmpty([
    aiReport['personalized_summary'],
    aiReport['user_summary'],
    aiReport['profile_summary'],
    aiReport['summary'],
    aiReport['overall_assessment'],
  ]);

  List<String> get personalizedHighlights => _extractStringList([
    aiReport['key_warnings'],
    aiReport['key_findings'],
    aiReport['highlights'],
    aiReport['recommendations'],
  ]);

  AppUser copyWith({
    String? firstName,
    String? lastName,
    String? email,
    int? age,
    String? userType,
    String? gender,
    DateTime? dateOfBirth,
    String? notes,
    Map<String, dynamic>? aiReport,
  }) {
    return AppUser(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      age: age ?? this.age,
      userType: userType ?? this.userType,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      notes: notes ?? this.notes,
      aiReport: aiReport ?? this.aiReport,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      firstName: (json['first_name'] ?? '') as String,
      lastName: (json['last_name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      age: (json['age'] as num?)?.toInt(),
      userType: (json['user_type'] ?? '') as String,
      gender: (json['gender'] ?? '') as String,
      dateOfBirth: _tryParseDate(json['date_of_birth']?.toString()),
      notes: (json['notes'] ?? '') as String,
      aiReport: json['ai_report'] is Map
          ? Map<String, dynamic>.from(json['ai_report'] as Map)
          : const <String, dynamic>{},
      createdAt: _tryParseDate(json['created_at']?.toString()),
      updatedAt: _tryParseDate(json['updated_at']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'age': age,
    'user_type': userType,
    'gender': gender,
    'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
    'notes': notes,
  };
}

@immutable
class AllergyItem {
  const AllergyItem({required this.id, required this.name});

  final int id;
  final String name;

  factory AllergyItem.fromJson(Map<String, dynamic> json) {
    return AllergyItem(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
    );
  }
}

@immutable
class ProductItem {
  const ProductItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.ingredients,
    required this.barcode,
    required this.extractionMethod,
    this.userDecision,
    this.userDecisionNotes = '',
    this.investigationReport = const <String, dynamic>{},
    this.filteringReport = const <String, dynamic>{},
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String brand;
  final ProductCategory category;
  final List<String> ingredients;
  final String barcode;
  final String extractionMethod;
  final String? userDecision;
  final String userDecisionNotes;
  final Map<String, dynamic> investigationReport;
  final Map<String, dynamic> filteringReport;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayTitle => brand.trim().isEmpty ? name : '$brand • $name';

  String get riskLevel => deriveRiskLevelFromPayload({
    'investigation_report': investigationReport,
    'filtering_report': filteringReport,
  });

  String get decisionLabel {
    return switch (userDecision) {
      'approved' => 'Adopted',
      'saved' => 'Saved',
      'pending' => 'Review',
      'rejected' => 'Rejected',
      _ => 'No decision',
    };
  }

  String get extractionLabel {
    return switch (extractionMethod) {
      'barcode' => 'Barcode',
      'lens' => 'Vision',
      'unknown' => 'Mixed',
      _ => extractionMethod.trim().isEmpty ? 'Not specified' : extractionMethod,
    };
  }

  bool get isHighRisk => riskLevel == 'CRITICAL' || riskLevel == 'HIGH';

  String? get imageUrl => _firstNonEmpty([
    investigationReport['image_url']?.toString(),
    investigationReport['image']?.toString(),
    filteringReport['image_url']?.toString(),
    filteringReport['image']?.toString(),
    filteringReport['source_image']?.toString(),
    investigationReport['source_image']?.toString(),
  ]);

  List<String> get previewAlternatives => _extractStringList([
    investigationReport['recommendations'],
    investigationReport['alternatives'],
    filteringReport['recommendations'],
    filteringReport['alternatives'],
  ]);

  List<String> get safeSkipIngredients {
    // Backend returns safe_skipped as a list
    return _extractStringList([
      filteringReport['safe_skipped'],
      filteringReport['safe_to_skip'],
      filteringReport['safe_ingredients'],
      filteringReport['safe'],
    ]);
  }

  List<String> get investigationChemicals {
    // Backend returns chemicals as the risky/investigate list in filteringReport
    return _extractStringList([
      filteringReport['chemicals'],
      filteringReport['investigate'],
      filteringReport['unverified_chemicals'],
      filteringReport['chemicals_to_investigate'],
      filteringReport['risky_ingredients'],
      investigationReport['chemicals'],
      investigationReport['investigate'],
    ]);
  }

  String get aiSummary =>
      _firstNonEmpty([
        investigationReport['summary']?.toString(),
        investigationReport['ai_summary']?.toString(),
        investigationReport['overview']?.toString(),
        filteringReport['summary']?.toString(),
        filteringReport['overview']?.toString(),
      ]) ??
      'No explicit AI summary has been provided for this product yet.';

  double? get confidenceScore => _extractConfidence([
    investigationReport['confidence'],
    investigationReport['confidence_score'],
    investigationReport['certainty'],
    filteringReport['confidence'],
    filteringReport['confidence_score'],
  ]);

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      brand: (json['brand'] ?? '') as String,
      category: ProductCategoryX.fromApi(json['category']?.toString()),
      ingredients: (json['ingredients'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      barcode: (json['barcode'] ?? '') as String,
      extractionMethod: (json['extraction_method'] ?? '') as String,
      userDecision: json['user_decision']?.toString(),
      userDecisionNotes: (json['user_decision_notes'] ?? '') as String,
      investigationReport: json['investigation_report'] is Map
          ? Map<String, dynamic>.from(json['investigation_report'] as Map)
          : const <String, dynamic>{},
      filteringReport: json['filtering_report'] is Map
          ? Map<String, dynamic>.from(json['filtering_report'] as Map)
          : const <String, dynamic>{},
      createdAt: _tryParseDate(json['created_at']?.toString()),
      updatedAt: _tryParseDate(json['updated_at']?.toString()),
    );
  }
}

@immutable
class MyProductsResponse {
  const MyProductsResponse({required this.products, required this.counts});

  final List<ProductItem> products;
  final Map<String, int> counts;

  factory MyProductsResponse.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'] as List<dynamic>? ?? const [];
    final rawCounts = json['counts'] as Map<String, dynamic>? ?? const {};
    return MyProductsResponse(
      products: rawProducts
          .map(
            (item) =>
                ProductItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      counts: rawCounts.map(
        (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
      ),
    );
  }
}

@immutable
class CumulativeSummary {
  const CumulativeSummary({required this.raw});

  final Map<String, dynamic> raw;

  factory CumulativeSummary.fromJson(Map<String, dynamic> json) {
    return CumulativeSummary(raw: json);
  }

  // ─── Global summary sub-object ─────────────────────────────────────────────
  Map<String, dynamic> get globalSummary {
    final value = raw['global_summary'];
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  Map<String, dynamic> get scoringAnalysis {
    final value = raw['scoring_analysis'];
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  // ─── Product verdicts ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> get productVerdicts {
    final value = raw['product_verdicts'];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> get productRiskResults {
    final results = scoringAnalysis['product_risk_results'];
    if (results is! List) return const [];
    return results
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> get recurrenceRisks {
    final results = scoringAnalysis['recurrence_risks'];
    if (results is! List) return const [];
    return results
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> get rankedProducts {
    final results = scoringAnalysis['ranked_products'];
    if (results is! List) return const [];
    return results
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ─── Organs & chemicals (from global_summary) ──────────────────────────────
  List<String> get organsUnderPressure {
    final val = globalSummary['organs_under_pressure'];
    if (val is List) return val.map((e) => e.toString()).toList();
    return const [];
  }

  List<String> get criticalChemicals {
    final val = globalSummary['critical_chemicals'];
    if (val is List) return val.map((e) => e.toString()).toList();
    return const [];
  }

  List<String> get highChemicals {
    final val = globalSummary['high_chemicals'];
    if (val is List) return val.map((e) => e.toString()).toList();
    return const [];
  }

  Map<String, dynamic> get organGlobalAnalysis {
    final val = globalSummary['organ_global_analysis'];
    return val is Map ? Map<String, dynamic>.from(val) : const {};
  }

  List<Map<String, dynamic>> get combinationRisks {
    final val = raw['combination_risks'];
    if (val is List) {
      return val
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (val is Map) {
      return [Map<String, dynamic>.from(val)];
    }
    return const [];
  }

  int get productsSafe =>
      (globalSummary['products_safe'] as num?)?.toInt() ?? 0;

  List<String> get recommendationHighlights => _extractStringList([
    raw['recommendations_from_api'],
    raw['recommendations'],
    raw['action_plan'],
  ]);

  // ─── Safe & unverified ingredients ────────────────────────────────────────
  List<String> get safeIngredients {
    final val = raw['safe_ingredients'];
    if (val is List) return val.map((e) => e.toString()).toList();
    return const [];
  }

  List<String> get unverifiedChemicals {
    final val = raw['unverified_chemicals'];
    if (val is List) return val.map((e) => e.toString()).toList();
    return const [];
  }

  // ─── Verdict recommendations (product_verdicts enriched) ──────────────────
  /// Returns verdicts sorted by risk: eliminate first, then reduce, then keep.
  List<Map<String, dynamic>> get sortedVerdicts {
    final order = {'eliminate': 0, 'reduce': 1, 'keep': 2};
    final sorted = [...productVerdicts];
    sorted.sort((a, b) {
      final aRec = order[a['recommendation']?.toString()] ?? 3;
      final bRec = order[b['recommendation']?.toString()] ?? 3;
      return aRec.compareTo(bRec);
    });
    return sorted;
  }

  // ─── Key warnings (for dashboard highlight) ────────────────────────────────
  List<String> get keyWarnings {
    final warnings = <String>{};
    final overall = raw['overall_assessment'];
    if (overall is String && overall.trim().isNotEmpty) {
      warnings.add(overall.trim());
    }

    for (final verdict in productVerdicts.take(3)) {
      final productName = verdict['product_name']?.toString();
      final risk = verdict['risk_level']?.toString();
      final recommendation = verdict['recommendation']?.toString();
      if ((productName ?? '').isNotEmpty &&
          (risk ?? '').isNotEmpty &&
          (recommendation ?? '').isNotEmpty) {
        warnings.add(
          '$productName: ${risk!.sentenceCase}, ${recommendation!.toLowerCase()}',
        );
      }
    }

    return warnings.take(4).toList();
  }

  String get overallAssessment {
    final value = raw['overall_assessment'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (productsToAvoid > 0) {
      return 'Several products should be avoided based on your profile.';
    }
    if (productsToReduce > 0) {
      return 'Some products should be reduced to limit cumulative risk.';
    }
    return 'Your cumulative view is currently stable overall.';
  }

  int get productsToReduce =>
      (globalSummary['products_to_reduce'] as num?)?.toInt() ?? 0;

  int get productsToAvoid =>
      (globalSummary['products_to_avoid'] as num?)?.toInt() ?? 0;

  int get productCount {
    if (productVerdicts.isNotEmpty) return productVerdicts.length;
    return productRiskResults.length;
  }

  int get flaggedProducts => productVerdicts.where((item) {
    final risk = item['risk_level']?.toString().toUpperCase();
    return risk == 'HIGH' || risk == 'CRITICAL';
  }).length;

  bool get hasData => raw.isNotEmpty;

  /// Overall health score 0–100 derived from available signals.
  int get healthScore {
    if (!hasData) return 50;
    final total = productCount;
    if (total == 0) return 50;
    final safe = productsSafe.clamp(0, total);
    final avoid = productsToAvoid.clamp(0, total);
    final reduce = productsToReduce.clamp(0, total);
    // Base: safe/total weighted, penalized by avoid and reduce
    final raw =
        ((safe / total) * 100) -
        ((avoid / total) * 40) -
        ((reduce / total) * 20);
    return raw.round().clamp(5, 98);
  }
}

@immutable
class SearchAlternativesResponse {
  const SearchAlternativesResponse({
    required this.status,
    required this.productName,
    required this.productType,
    required this.rawResults,
    required this.errors,
  });

  final String status;
  final String productName;
  final String productType;
  final dynamic rawResults;
  final List<String> errors;

  List<AlternativeSuggestion> get suggestions {
    final items = <AlternativeSuggestion>[];

    if (rawResults is List) {
      for (final item in rawResults as List<dynamic>) {
        final suggestion = AlternativeSuggestion.fromUnknown(item);
        if (suggestion != null) items.add(suggestion);
      }
    } else if (rawResults is Map) {
      final map = Map<String, dynamic>.from(rawResults as Map);
      final nested = map['results'] ?? map['items'] ?? map['alternatives'];
      if (nested is List) {
        for (final item in nested) {
          final suggestion = AlternativeSuggestion.fromUnknown(item);
          if (suggestion != null) items.add(suggestion);
        }
      } else {
        final suggestion = AlternativeSuggestion.fromUnknown(map);
        if (suggestion != null) items.add(suggestion);
      }
    }

    return items;
  }

  factory SearchAlternativesResponse.fromJson(Map<String, dynamic> json) {
    return SearchAlternativesResponse(
      status: (json['status'] ?? '') as String,
      productName: (json['product_name'] ?? '') as String,
      productType: (json['product_type'] ?? '') as String,
      rawResults: json['results'],
      errors: (json['errors'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

@immutable
class AlternativeSuggestion {
  const AlternativeSuggestion({
    required this.title,
    required this.subtitle,
    required this.reason,
    this.price,
    this.imageUrl,
    this.shopUrl,
  });

  final String title;
  final String subtitle;
  final String reason;
  final String? price;
  final String? imageUrl;
  final String? shopUrl;

  factory AlternativeSuggestion.fromMap(Map<String, dynamic> json) {
    return AlternativeSuggestion(
      title:
          (json['title'] ??
                  json['name'] ??
                  json['product'] ??
                  json['product_name'] ??
                  'Alternative')
              .toString(),
      subtitle:
          (json['brand'] ??
                  json['source'] ??
                  json['merchant'] ??
                  json['category'] ??
                  '')
              .toString(),
      reason:
          (json['reason'] ??
                  json['why'] ??
                  json['summary'] ??
                  json['description'] ??
                  'Alternative suggested by the search engine.')
              .toString(),
      price: json['price']?.toString(),
      imageUrl: json['image']?.toString() ?? json['image_url']?.toString(),
      shopUrl: json['url']?.toString() ?? json['link']?.toString(),
    );
  }

  static AlternativeSuggestion? fromUnknown(dynamic value) {
    if (value is Map) {
      return AlternativeSuggestion.fromMap(Map<String, dynamic>.from(value));
    }
    if (value is String && value.trim().isNotEmpty) {
      return AlternativeSuggestion(
        title: value.trim(),
        subtitle: '',
        reason: 'Suggestion returned by the backend.',
      );
    }
    return null;
  }
}

@immutable
class BBox {
  const BBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  factory BBox.fromJson(Map<String, dynamic> json) {
    return BBox(
      x: (json['x'] ?? 0) as int,
      y: (json['y'] ?? 0) as int,
      width: (json['width'] ?? 0) as int,
      height: (json['height'] ?? 0) as int,
    );
  }
}

@immutable
class SegmentedProduct {
  const SegmentedProduct({
    required this.productId,
    required this.label,
    required this.confidence,
    required this.bbox,
    required this.cropUrl,
  });

  final String productId;
  final String label;
  final double confidence;
  final BBox bbox;
  final String cropUrl;

  factory SegmentedProduct.fromJson(Map<String, dynamic> json) {
    return SegmentedProduct(
      productId: (json['product_id'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      bbox: BBox.fromJson(Map<String, dynamic>.from(json['bbox'] as Map)),
      cropUrl: (json['crop_url'] ?? '') as String,
    );
  }
}

@immutable
class SegmentationBatch {
  const SegmentationBatch({
    required this.sessionId,
    required this.products,
    required this.totalProducts,
    required this.segmentationMode,
  });

  final String sessionId;
  final List<SegmentedProduct> products;
  final int totalProducts;
  final String segmentationMode;

  factory SegmentationBatch.fromJson(Map<String, dynamic> json) {
    return SegmentationBatch(
      sessionId: (json['session_id'] ?? '') as String,
      segmentationMode: (json['segmentation_mode'] ?? 'auto') as String,
      totalProducts: (json['total_products'] ?? 0) as int,
      products: (json['products'] as List<dynamic>? ?? const [])
          .map(
            (item) => SegmentedProduct.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

@immutable
class AnalyzedProduct {
  const AnalyzedProduct({
    required this.productId,
    required this.name,
    required this.brand,
    required this.category,
    required this.ingredients,
  });

  final String productId;
  final String name;
  final String brand;
  final String category;
  final List<String> ingredients;

  factory AnalyzedProduct.fromJson(Map<String, dynamic> json) {
    return AnalyzedProduct(
      productId: (json['product_id'] ?? '') as String,
      name: (json['name'] ?? json['label'] ?? 'Product') as String,
      brand: (json['brand'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      ingredients: (json['ingredients'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

@immutable
class QuickScanResponse {
  const QuickScanResponse({
    required this.scanId,
    required this.ingredients,
    this.analysis,
    this.risks = const [],
    this.recommendations = const [],
    this.userDecision,
    this.cumulativeReport,
  });

  final int scanId;
  final List<String> ingredients;
  final Map<String, dynamic>? analysis;
  final List<Map<String, dynamic>> risks;
  final List<Map<String, dynamic>> recommendations;
  final String? userDecision;
  final Map<String, dynamic>? cumulativeReport;

  factory QuickScanResponse.fromJson(Map<String, dynamic> json) {
    return QuickScanResponse(
      scanId: (json['scan_id'] ?? 0) as int,
      ingredients: (json['ingredients'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      analysis: json['analysis'] is Map
          ? Map<String, dynamic>.from(json['analysis'] as Map)
          : null,
      risks: (json['risks'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      userDecision: json['user_decision']?.toString(),
      cumulativeReport: json['cumulative_report'] is Map
          ? Map<String, dynamic>.from(json['cumulative_report'] as Map)
          : null,
    );
  }
}

@immutable
class ScanReportRecord {
  const ScanReportRecord({
    required this.id,
    required this.title,
    required this.results,
    required this.createdAt,
    this.sourceImagePath,
  });

  final String id;
  final String title;
  final List<Map<String, dynamic>> results;
  final DateTime createdAt;
  final String? sourceImagePath;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'results': results,
    'created_at': createdAt.toIso8601String(),
    'source_image_path': sourceImagePath,
  };

  factory ScanReportRecord.fromJson(Map<String, dynamic> json) {
    return ScanReportRecord(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? 'Scan report') as String,
      results: (json['results'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      sourceImagePath: json['source_image_path']?.toString(),
    );
  }
}

String deriveRiskLevelFromPayload(Map<String, dynamic> result) {
  final risks = result['risks'];
  if (risks is List && risks.isNotEmpty) {
    final levels = risks
        .map(
          (e) => (e is Map ? e['level']?.toString().toLowerCase() : null) ?? '',
        )
        .toList();
    if (levels.contains('critical')) return 'CRITICAL';
    if (levels.contains('high')) return 'HIGH';
    if (levels.contains('medium') || levels.contains('moderate')) {
      return 'MODERATE';
    }
    if (levels.contains('low')) return 'LOW';
  }

  final filtering = result['filtering_report'];
  if (filtering is Map && filtering['recommendation'] != null) {
    final recommendation = filtering['recommendation'].toString().toLowerCase();
    if (recommendation.contains('critical')) return 'CRITICAL';
    if (recommendation.contains('avoid')) return 'HIGH';
    if (recommendation.contains('reduce')) return 'MODERATE';
  }

  final investigation = result['investigation_report'];
  if (investigation is Map) {
    final summary = investigation['summary'];
    if (summary is Map) {
      final critical = (summary['critical'] as num?)?.toInt() ?? 0;
      final high = (summary['high'] as num?)?.toInt() ?? 0;
      final moderate = (summary['moderate'] as num?)?.toInt() ?? 0;
      if (critical > 0) return 'CRITICAL';
      if (high > 0) return 'HIGH';
      if (moderate > 0) return 'MODERATE';
      return 'LOW';
    }
  }

  return 'UNKNOWN';
}

DateTime? _tryParseDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

String? _firstNonEmpty(Iterable<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
  }
  return null;
}

List<String> _extractStringList(Iterable<dynamic> values) {
  final items = <String>[];

  void addValue(dynamic value) {
    if (value == null) return;
    if (value is String) {
      final text = value.trim();
      if (text.isNotEmpty) items.add(text);
      return;
    }
    if (value is List) {
      for (final entry in value) {
        addValue(entry);
      }
      return;
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      // First, try to extract from common key names
      for (final key in const [
        'name',
        'label',
        'title',
        'product',
        'chemical',
        'ingredient',
        'value',
        'text',
        'description',
        'note',
      ]) {
        final text = map[key]?.toString().trim();
        if (text != null && text.isNotEmpty) {
          items.add(text);
          return;
        }
      }

      // If no standard keys found, try to extract first non-empty value
      for (final entry in map.entries) {
        final text = entry.value?.toString().trim();
        if (text != null && text.isNotEmpty && text.length > 2) {
          items.add(text);
          return;
        }
      }

      // Last resort: join all values
      final joined = map.values
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty && entry.length > 2)
          .join(' ')
          .trim();
      if (joined.isNotEmpty) items.add(joined);
      return;
    }

    final text = value.toString().trim();
    if (text.isNotEmpty && text.length > 2) items.add(text);
  }

  for (final value in values) {
    addValue(value);
  }

  return items.toSet().toList();
}

double? _extractConfidence(Iterable<dynamic> values) {
  for (final value in values) {
    if (value is num) {
      final number = value.toDouble();
      if (number > 1) return (number / 100).clamp(0, 1);
      return number.clamp(0, 1);
    }
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) {
        if (parsed > 1) return (parsed / 100).clamp(0, 1);
        return parsed.clamp(0, 1);
      }
    }
  }
  return null;
}
