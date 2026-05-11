import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../app_config.dart';
import '../models.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<AppSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _postJson(
      '/api/users/auth/login/',
      body: {'email': email, 'password': password},
    );
    return AppSession.fromJson(response);
  }

  Future<AppSession> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String gender,
    DateTime? dateOfBirth,
  }) async {
    final response = await _postJson(
      '/api/users/auth/register/',
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'gender': gender,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      },
    );
    return AppSession.fromJson(response);
  }

  Future<AppUser> fetchProfile(String token) async {
    final response = await _getJson('/api/users/me/', token: token);
    return AppUser.fromJson(response);
  }

  Future<AppUser> updateProfile({
    required String token,
    required AppUser user,
  }) async {
    final response = await _patchJson(
      '/api/users/me/',
      token: token,
      body: user.toJson(),
    );
    return AppUser.fromJson(response);
  }

  Future<List<AllergyItem>> fetchAllergies(String token) async {
    final response = await _getJson('/api/users/allergies/', token: token);
    final dynamic rawItems =
        response['results'] ?? response['items'] ?? response;
    final items = rawItems is List ? rawItems : const <dynamic>[];
    return items
        .map(
          (item) =>
              AllergyItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<int>> fetchCurrentUserAllergyIds(String token) async {
    final response = await _getJson('/api/users/me/allergies/', token: token);
    return (response['selected_ids'] as List<dynamic>? ?? const [])
        .map((item) => (item as num).toInt())
        .toList();
  }

  Future<void> updateCurrentUserAllergies({
    required String token,
    required List<int> allergyIds,
  }) async {
    await _patchJson(
      '/api/users/me/allergies/',
      token: token,
      body: {'allergy_ids': allergyIds},
    );
  }

  Future<AppUser> updateUserType({
    required String token,
    required String userType,
  }) async {
    final response = await _patchJson(
      '/api/users/me/user-type/',
      token: token,
      body: {'user_type': userType},
    );
    final rawUser = response['user'];
    if (rawUser is Map) {
      return AppUser.fromJson(Map<String, dynamic>.from(rawUser));
    }
    return fetchProfile(token);
  }

  Future<AllergyItem> createAllergy({
    required String token,
    required String name,
  }) async {
    final response = await _postJson(
      '/api/users/allergies/',
      token: token,
      body: {'name': name},
    );
    return AllergyItem.fromJson(response);
  }

  Future<List<ProductItem>> fetchProducts(String token) async {
    final response = await _getJson('/api/products/', token: token);
    final dynamic rawItems = response['results'] ?? response['items'];
    final items = rawItems is List ? rawItems : const <dynamic>[];
    return items
        .map(
          (item) =>
              ProductItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<MyProductsResponse> fetchMyProducts(
    String token, {
    String? status,
  }) async {
    final path = status == null || status.isEmpty
        ? '/api/products/my-products/'
        : '/api/products/my-products/?status=$status';
    final response = await _getJson(path, token: token);
    return MyProductsResponse.fromJson(response);
  }

  Future<void> patchProductDecision({
    required String token,
    required int productId,
    required String decision,
    String notes = '',
  }) async {
    await _patchJson(
      '/api/products/$productId/decision/',
      token: token,
      body: {'decision': decision, 'notes': notes},
    );
  }

  Future<CumulativeSummary?> fetchCumulativeSummary(String token) async {
    final response = await _getJson(
      '/api/users/cumulative-summary/',
      token: token,
    );
    return CumulativeSummary.fromJson(response);
  }

  Future<ProductItem> createProduct({
    required String token,
    required String name,
    required String brand,
    required ProductCategory category,
    required List<String> ingredients,
    required String barcode,
    required String extractionMethod,
  }) async {
    final response = await _postJson(
      '/api/products/',
      token: token,
      body: {
        'name': name,
        'brand': brand,
        'category': category.name,
        'ingredients': ingredients,
        'barcode': barcode,
        'extraction_method': extractionMethod,
      },
    );
    return ProductItem.fromJson(response);
  }

  Future<ProductItem> saveAnalyzedProduct({
    required String token,
    required Map<String, dynamic> source,
  }) async {
    final analysis = source['analysis'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(source['analysis'] as Map)
        : <String, dynamic>{};
    final ingredients = (source['ingredients'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
    final rawCategory = (analysis['category'] ?? source['category'] ?? '')
        .toString()
        .toLowerCase();
    final category = switch (rawCategory) {
      'food' => ProductCategory.food,
      'cosmetic' => ProductCategory.cosmetic,
      _ => ProductCategory.unknown,
    };
    final name = (analysis['name'] ?? source['name'] ?? 'Analyzed product')
        .toString();
    final brand = (analysis['brand'] ?? source['brand'] ?? '').toString();
    final barcode = (analysis['barcode'] ?? source['barcode'] ?? '').toString();
    final extractionMethod =
        (analysis['source'] ?? source['extraction_method'] ?? 'unknown')
            .toString()
            .toLowerCase();
    final normalizedExtractionMethod = switch (extractionMethod) {
      'lens' => 'lens',
      'barcode' => 'barcode',
      _ => 'unknown',
    };

    return createProduct(
      token: token,
      name: name,
      brand: brand,
      category: category,
      ingredients: ingredients,
      barcode: barcode,
      extractionMethod: normalizedExtractionMethod,
    );
  }

  /// Segmentation — utilise [XFile] pour la compatibilité Web + mobile.
  Future<SegmentationBatch> segmentImage({
    required String token,
    required XFile image,
  }) async {
    final response = await _postMultipart(
      '/api/scan/segment/',
      token: token,
      fields: const {'segmentation_mode': 'auto'},
      fileFieldName: 'image',
      file: image,
    );
    return SegmentationBatch.fromJson(response);
  }

  Future<List<Map<String, dynamic>>> analyzeSelected({
    required String token,
    required String sessionId,
    required List<String> productIds,
  }) async {
    final response = await _postJson(
      '/api/scan/selected/',
      token: token,
      body: {'session_id': sessionId, 'product_ids': productIds},
    );
    final results = response['results'] as List<dynamic>;
    return results
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// Scan rapide — utilise [XFile] pour la compatibilité Web + mobile.
  Future<QuickScanResponse> quickScanImage({
    required String token,
    required XFile image,
  }) async {
    final response = await _postMultipart(
      '/api/scan/',
      token: token,
      fields: const {},
      fileFieldName: 'image',
      file: image,
    );
    return QuickScanResponse.fromJson(response);
  }

  Future<SearchAlternativesResponse> searchAlternatives({
    required String token,
    required String productName,
    required String productType,
    int topK = 3,
  }) async {
    final response = await _postJson(
      '/api/recommend/search/alternatives',
      token: token,
      body: {
        'product_name': productName,
        'product_type': productType,
        'top_k': topK,
      },
    );
    return SearchAlternativesResponse.fromJson(response);
  }

  Future<Map<String, dynamic>> _getJson(String path, {String? token}) async {
    final response = await _client.get(
      AppConfig.uri(path),
      headers: _headers(token),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _postJson(
    String path, {
    String? token,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.post(
      AppConfig.uri(path),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _patchJson(
    String path, {
    String? token,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.patch(
      AppConfig.uri(path),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  /// Upload multipart compatible Web — utilise [XFile.readAsBytes()] au lieu de [File.path].
  /// Déclare explicitement le Content-Type pour que Django accepte le fichier.
  Future<Map<String, dynamic>> _postMultipart(
    String path, {
    required String token,
    required Map<String, String> fields,
    required String fileFieldName,
    required XFile file,
  }) async {
    final request = http.MultipartRequest('POST', AppConfig.uri(path));
    request.headers.addAll(_headers(token, contentType: false));
    request.fields.addAll(fields);
    final bytes = await file.readAsBytes();
    // Détecter le type MIME depuis xfile.mimeType ou depuis l'extension du nom
    final mime = _resolveMimeType(file);
    request.files.add(
      http.MultipartFile.fromBytes(
        fileFieldName,
        bytes,
        filename: file.name,
        contentType: mime,
      ),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  /// Résout le [MediaType] à partir de [XFile.mimeType] ou de l'extension du fichier.
  static MediaType _resolveMimeType(XFile file) {
    final raw = file.mimeType;
    if (raw != null && raw.isNotEmpty) {
      final parts = raw.split('/');
      if (parts.length == 2) {
        return MediaType(parts[0], parts[1]);
      }
    }
    // Détecter depuis l'extension du nom de fichier
    final ext = file.name.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'bmp':
        return MediaType('image', 'bmp');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  Map<String, String> _headers(String? token, {bool contentType = true}) => {
    if (contentType) 'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
    'Accept': 'application/json',
  };

  Map<String, dynamic> _decode(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'results': decoded};
    }
    String message = 'Unknown server error';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail =
            decoded['detail'] ?? decoded['error'] ?? decoded['message'];
        message = detail != null
            ? detail.toString()
            : _formatValidationErrors(decoded);
      } else if (decoded is List) {
        message = decoded.map((item) => item.toString()).join(', ');
      }
    } catch (_) {
      if (body.isNotEmpty) message = body;
    }
    throw ApiException(message, response.statusCode);
  }

  String _formatValidationErrors(Map<String, dynamic> decoded) {
    final parts = <String>[];
    decoded.forEach((key, value) {
      if (value == null) return;
      if (value is List) {
        final text = value.map((item) => item.toString()).join(', ');
        if (text.isNotEmpty) parts.add('$key: $text');
        return;
      }
      if (value is Map<String, dynamic>) {
        parts.add('$key: ${_formatValidationErrors(value)}');
        return;
      }
      final text = value.toString();
      if (text.isNotEmpty) parts.add('$key: $text');
    });
    return parts.isEmpty ? 'Unknown server error' : parts.join(' | ');
  }
}

class AppSession {
  const AppSession({required this.token, required this.user});
  final String token;
  final AppUser user;
  factory AppSession.fromJson(Map<String, dynamic> json) => AppSession(
    token: (json['token'] ?? '') as String,
    user: AppUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
  );
}

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() =>
      statusCode == null ? message : 'HTTP $statusCode: $message';
}
