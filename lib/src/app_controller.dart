import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'models.dart';
import 'services/api_client.dart';
import 'services/auth_store.dart';

class AppController extends ChangeNotifier {
  AppController({ApiClient? apiClient, AuthStore? authStore})
    : _apiClient = apiClient ?? ApiClient(),
      _authStore = authStore ?? AuthStore();

  final ApiClient _apiClient;
  final AuthStore _authStore;

  bool isBootstrapping = true;
  bool isBusy = false;
  String? errorMessage;
  String? token;
  AppUser? currentUser;
  List<AllergyItem> allergies = const [];
  List<int> selectedAllergyIds = const [];
  List<ProductItem> products = const [];
  Map<String, int> productCounts = const {};
  CumulativeSummary? cumulativeSummary;
  List<Map<String, dynamic>> lastScanPayload = const [];
  List<ScanReportRecord> scanHistory = const [];
  bool onboardingCompleted = false;
  bool hasSkippedOnboarding = false;

  // Notification preferences (stored locally for now)
  bool notifyHighRisk = true;
  bool notifyControversial = false;

  bool get isAuthenticated => token != null && token!.isNotEmpty;
  bool get needsOnboarding =>
      isAuthenticated &&
      !onboardingCompleted &&
      !hasSkippedOnboarding &&
      ((currentUser?.userType.trim().isEmpty ?? true) ||
          selectedAllergyIds.isEmpty);

  List<ProductItem> get highRiskProducts =>
      products.where((item) => item.isHighRisk).toList();

  Future<void> bootstrap() async {
    isBootstrapping = true;
    notifyListeners();

    try {
      token = await _authStore.readToken();
      if (token != null && token!.trim().isNotEmpty) {
        await refreshSession(allowLogout: true, silent: true);
        await _loadScanHistory();
      }
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    await _runBusy(() async {
      final session = await _apiClient.login(email: email, password: password);
      token = session.token;
      currentUser = session.user;
      hasSkippedOnboarding = false;
      await _authStore.writeToken(session.token);
      await _loadProfileExtras();
      await refreshProducts(silent: true);
      await refreshCumulativeSummary(silent: true);
      await _loadScanHistory();
      _syncOnboardingState();
    });
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String gender,
    DateTime? dateOfBirth,
  }) async {
    await _runBusy(() async {
      final session = await _apiClient.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        gender: gender,
        dateOfBirth: dateOfBirth,
      );
      token = session.token;
      currentUser = session.user;
      hasSkippedOnboarding = false;
      await _authStore.writeToken(session.token);
      await _loadProfileExtras();
      await refreshProducts(silent: true);
      await refreshCumulativeSummary(silent: true);
      await _loadScanHistory();
      onboardingCompleted = false;
      _syncOnboardingState();
    });
  }

  Future<void> refreshSession({
    bool allowLogout = false,
    bool silent = false,
  }) async {
    if (!isAuthenticated) return;
    if (!silent) {
      isBusy = true;
      errorMessage = null;
      notifyListeners();
    }
    try {
      currentUser = await _apiClient.fetchProfile(token!);
      await _loadProfileExtras();
      await refreshProducts(silent: true);
      await refreshCumulativeSummary(silent: true);
      await _loadScanHistory();
      _syncOnboardingState();
    } on ApiException catch (error) {
      errorMessage = error.message;
      if (allowLogout && (error.statusCode == 401 || error.statusCode == 403)) {
        await logout(quiet: true);
      }
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      if (!silent) {
        isBusy = false;
        notifyListeners();
      }
    }
  }

  Future<void> saveProfile(AppUser updatedUser) async {
    if (!isAuthenticated) throw StateError('User is not authenticated');
    await _runBusy(() async {
      currentUser = await _apiClient.updateProfile(
        token: token!,
        user: updatedUser,
      );
      await _loadProfileExtras();
    });
  }

  Future<void> saveProfilePreferences({
    required AppUser updatedUser,
    required List<int> allergyIds,
  }) async {
    if (!isAuthenticated) throw StateError('User is not authenticated');
    await _runBusy(() async {
      // Update profile on backend
      currentUser = await _apiClient.updateProfile(
        token: token!,
        user: updatedUser,
      );
      // Update allergies on backend
      await _apiClient.updateCurrentUserAllergies(
        token: token!,
        allergyIds: allergyIds,
      );
      // Reload fresh data
      await _loadProfileExtras();
      _syncOnboardingState(
        forceComplete: updatedUser.userType.trim().isNotEmpty,
      );
    });
  }

  Future<void> completeOnboarding({
    required String userType,
    required List<int> allergyIds,
    bool notifyHighRisk = true,
    bool notifyControversial = false,
  }) async {
    if (!isAuthenticated) throw StateError('User is not authenticated');
    await _runBusy(() async {
      // Update user type on backend
      currentUser = await _apiClient.updateUserType(
        token: token!,
        userType: userType,
      );
      // Update allergies on backend
      await _apiClient.updateCurrentUserAllergies(
        token: token!,
        allergyIds: allergyIds,
      );
      // Store notification preferences locally
      this.notifyHighRisk = notifyHighRisk;
      this.notifyControversial = notifyControversial;
      // Reload fresh data
      await _loadProfileExtras();
      selectedAllergyIds = allergyIds;
      onboardingCompleted = true;
    });
  }

  Future<AllergyItem> createAllergy(String name) async {
    if (!isAuthenticated) throw StateError('User is not authenticated');
    return _runBusyResult(() async {
      // Create allergy on backend
      final allergy = await _apiClient.createAllergy(token: token!, name: name);
      allergies = [...allergies, allergy]
        ..sort(
          (left, right) =>
              left.name.toLowerCase().compareTo(right.name.toLowerCase()),
        );
      notifyListeners();
      return allergy;
    });
  }

  Future<void> refreshProducts({bool silent = false}) async {
    if (!isAuthenticated) {
      products = const [];
      productCounts = const {};
      cumulativeSummary = null;
      notifyListeners();
      return;
    }
    if (!silent) {
      isBusy = true;
      notifyListeners();
    }
    try {
      final response = await _apiClient.fetchMyProducts(token!);
      products = response.products;
      productCounts = response.counts;
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      if (!silent) {
        isBusy = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshCumulativeSummary({bool silent = false}) async {
    if (!isAuthenticated) {
      cumulativeSummary = null;
      if (!silent) notifyListeners();
      return;
    }

    if (!silent) {
      isBusy = true;
      notifyListeners();
    }
    try {
      cumulativeSummary = await _apiClient.fetchCumulativeSummary(token!);
      errorMessage = null;
    } on ApiException catch (error) {
      // 404 is a valid empty-state for early users with insufficient products.
      if (error.statusCode == 404) {
        cumulativeSummary = null;
        errorMessage = null;
      } else {
        errorMessage = error.message;
      }
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      if (!silent) {
        isBusy = false;
        notifyListeners();
      }
    }
  }

  Future<void> setProductDecision({
    required int productId,
    required String decision,
    String notes = '',
  }) async {
    if (!isAuthenticated) throw StateError('User is not authenticated');
    await _runBusy(() async {
      await _apiClient.patchProductDecision(
        token: token!,
        productId: productId,
        decision: decision,
        notes: notes,
      );
      await refreshProducts(silent: true);
      await refreshCumulativeSummary(silent: true);
    });
  }

  Future<void> createProduct({
    required String name,
    required String brand,
    required ProductCategory category,
    required List<String> ingredients,
    required String barcode,
    required String extractionMethod,
  }) async {
    if (!isAuthenticated) throw StateError('User is not authenticated');
    await _runBusy(() async {
      await _apiClient.createProduct(
        token: token!,
        name: name,
        brand: brand,
        category: category,
        ingredients: ingredients,
        barcode: barcode,
        extractionMethod: extractionMethod,
      );
      await refreshProducts(silent: true);
    });
  }

  Future<ProductItem> saveAnalyzedProduct(Map<String, dynamic> source) async {
    if (!isAuthenticated) throw StateError('User is not authenticated');
    return _runBusyResult(() async {
      final product = await _apiClient.saveAnalyzedProduct(
        token: token!,
        source: source,
      );
      await refreshProducts(silent: true);
      return product;
    });
  }

  Future<SearchAlternativesResponse> searchAlternatives(ProductItem product) {
    if (!isAuthenticated) throw StateError('User is not authenticated');
    return _runBusyResult(() {
      return _apiClient.searchAlternatives(
        token: token!,
        productName: product.name,
        productType: product.category.recommendationType,
      );
    });
  }

  /// Segmentation — accepte un [XFile] (compatible Web et mobile).
  Future<SegmentationBatch> segmentImage(XFile imageFile) async {
    if (!isAuthenticated) throw StateError('User is not authenticated');
    return _apiClient.segmentImage(token: token!, image: imageFile);
  }

  Future<List<Map<String, dynamic>>> analyzeSelected({
    required String sessionId,
    required List<String> productIds,
  }) {
    if (!isAuthenticated) throw StateError('User is not authenticated');
    return _apiClient.analyzeSelected(
      token: token!,
      sessionId: sessionId,
      productIds: productIds,
    );
  }

  /// Scan rapide — accepte un [XFile] (compatible Web et mobile).
  Future<QuickScanResponse> quickScanImage(XFile imageFile) {
    if (!isAuthenticated) throw StateError('User is not authenticated');
    return _apiClient.quickScanImage(token: token!, image: imageFile);
  }

  void setLastScanPayload(List<Map<String, dynamic>> payload) {
    lastScanPayload = payload;
    notifyListeners();
  }

  Future<void> recordScanReport({
    required List<Map<String, dynamic>> results,
    String? sourceImagePath,
    String? title,
  }) async {
    if (!isAuthenticated) return;

    final normalizedTitle = title?.trim();
    final record = ScanReportRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: normalizedTitle == null || normalizedTitle.isEmpty
          ? 'Scan report'
          : normalizedTitle,
      results: results,
      createdAt: DateTime.now(),
      sourceImagePath: sourceImagePath,
    );

    scanHistory = [record, ...scanHistory].take(24).toList();
    notifyListeners();
    await _persistScanHistory();
  }

  Future<void> removeScanReport(String id) async {
    scanHistory = scanHistory.where((item) => item.id != id).toList();
    notifyListeners();
    await _persistScanHistory();
  }

  void clearLastScanPayload() {
    lastScanPayload = const [];
    notifyListeners();
  }

  void skipOnboarding() {
    onboardingCompleted = true;
    hasSkippedOnboarding = true;
    notifyListeners();
  }

  Future<void> refreshAllergies() async {
    if (!isAuthenticated) return;
    await _runBusy(() async {
      await _loadProfileExtras();
    });
  }

  Future<void> logout({bool quiet = false}) async {
    token = null;
    currentUser = null;
    products = const [];
    productCounts = const {};
    cumulativeSummary = null;
    lastScanPayload = const [];
    scanHistory = const [];
    onboardingCompleted = false;
    hasSkippedOnboarding = false;
    selectedAllergyIds = const [];
    if (!quiet) notifyListeners();
    await _authStore.clear();
    await _authStore.removeValue(_scanHistoryKey);
  }

  Map<ProductCategory, List<ProductItem>> groupedProducts() {
    final grouped = <ProductCategory, List<ProductItem>>{
      ProductCategory.food: [],
      ProductCategory.cosmetic: [],
      ProductCategory.unknown: [],
    };
    for (final product in products) {
      grouped[product.category]!.add(product);
    }
    return grouped;
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on ApiException catch (error) {
      errorMessage = error.message;
      rethrow;
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<T> _runBusyResult<T>(Future<T> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } on ApiException catch (error) {
      errorMessage = error.message;
      rethrow;
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfileExtras() async {
    if (!isAuthenticated) return;

    try {
      final fetchedAllergies = await _apiClient.fetchAllergies(token!);
      allergies = [...fetchedAllergies]
        ..sort(
          (left, right) =>
              left.name.toLowerCase().compareTo(right.name.toLowerCase()),
        );
    } catch (_) {}

    try {
      final fetchedSelectedIds = await _apiClient.fetchCurrentUserAllergyIds(
        token!,
      );
      selectedAllergyIds = fetchedSelectedIds;
    } catch (_) {}
  }

  void _syncOnboardingState({bool forceComplete = false}) {
    if (forceComplete || hasSkippedOnboarding) {
      onboardingCompleted = true;
      return;
    }
    final hasUserType = currentUser?.userType.trim().isNotEmpty ?? false;
    onboardingCompleted = hasUserType && selectedAllergyIds.isNotEmpty;
  }

  String get _scanHistoryKey => 'scan_history_${currentUser?.id ?? 'guest'}';

  Future<void> _loadScanHistory() async {
    if (!isAuthenticated) {
      scanHistory = const [];
      return;
    }

    final rawEntries = await _authStore.readStringList(_scanHistoryKey);
    final records = <ScanReportRecord>[];
    for (final entry in rawEntries) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is Map) {
          records.add(
            ScanReportRecord.fromJson(Map<String, dynamic>.from(decoded)),
          );
        }
      } catch (_) {
        continue;
      }
    }
    scanHistory = records;
  }

  Future<void> _persistScanHistory() async {
    if (!isAuthenticated) return;
    await _authStore.writeStringList(
      _scanHistoryKey,
      scanHistory.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
