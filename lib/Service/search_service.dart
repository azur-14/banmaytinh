import '../models/product.dart';
import '../models/review.dart';
import 'product_service.dart';  // ← gọi HTTP từ đây
import 'package:flutter/foundation.dart';

class SearchService {
  final List<String> _searchHistory = [];
  double? averageRating;

  /// Chuẩn hóa tiếng Việt
  String _normalizeString(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáảãạăắằẳẵặâấầẩẫậ]'), 'a')
        .replaceAll(RegExp(r'[èéẻẽẹêếềểễệ]'), 'e')
        .replaceAll(RegExp(r'[ìíỉĩị]'), 'i')
        .replaceAll(RegExp(r'[òóỏõọôốồổỗộơớờởỡợ]'), 'o')
        .replaceAll(RegExp(r'[ùúủũụưứừửữự]'), 'u')
        .replaceAll(RegExp(r'[ỳýỷỹỵ]'), 'y')
        .replaceAll(RegExp(r'[đ]'), 'd');
  }

  List<String> getSearchHistory() => _searchHistory;
  void clearSearchHistory() => _searchHistory.clear();
  void removeFromSearchHistory(String query) => _searchHistory.remove(query);

  /// Tìm kiếm sản phẩm động qua ProductService
  Future<List<Product>> searchProducts(
      String query, {
        List<String> brands = const [],
        double? minPrice,
        double? maxPrice,
        String? category,
        double? minRating,
      }) async {
    try {
      // Lấy toàn bộ sản phẩm từ API
      List<Product> results = await ProductService.fetchAllProducts();

      if (query.isNotEmpty && !_searchHistory.contains(query)) {
        _searchHistory.add(query);
      }

      // Normalize query
      final normalizedQuery = _normalizeString(query);

      // Lọc theo tên hoặc mô tả
      results = results.where((product) {
        final name = _normalizeString(product.name);
        final desc = _normalizeString(product.description ?? '');
        return name.contains(normalizedQuery) || desc.contains(normalizedQuery);
      }).toList();

      // Lọc theo brand
      if (brands.isNotEmpty) {
        results = results.where((p) => brands.contains(p.brand)).toList();
      }

      // Lọc theo min-max price
      if (minPrice != null) {
        results = results.where((p) => p.minPrice >= minPrice).toList();
      }
      if (maxPrice != null) {
        results = results.where((p) => p.minPrice <= maxPrice).toList();
      }

      // Lọc theo danh mục
      if (category != null && category.isNotEmpty) {
        results = results.where((p) => p.categoryId == category).toList();
      }

      // Lọc theo rating (nếu cần)
      if (minRating != null) {
        results = (await Future.wait(results.map((p) async {
          final rating = await ProductService.getRating(p.id);
          return rating.averageRating >= minRating ? p : null;
        }))).whereType<Product>().toList();
      }

      debugPrint('[search] Found ${results.length} sản phẩm');
      return results;
    } catch (e) {
      debugPrint('❌ Lỗi tìm kiếm sản phẩm: $e');
      throw Exception('Không thể tìm kiếm sản phẩm');
    }
  }

  /// Gợi ý tên sản phẩm
  Future<List<String>> autocomplete(String query) async {
    try {
      final normalizedQuery = _normalizeString(query);
      final all = await ProductService.fetchAllProducts();
      return all
          .where((p) => _normalizeString(p.name).contains(normalizedQuery))
          .map((p) => p.name)
          .toSet()
          .take(5)
          .toList();
    } catch (e) {
      debugPrint('❌ Lỗi autocomplete: $e');
      return [];
    }
  }

  /// Lấy danh sách brand từ API
  Future<List<String?>> getBrands() async {
    final all = await ProductService.fetchAllProducts();
    return all.map((p) => p.brand).toSet().toList();
  }

  Future<List<String>> getCategories() async {
    final all = await ProductService.fetchAllCategories();
    return all.map((cat) => cat.id).whereType<String>().toList(); // ⬅️ ép kiểu bỏ null
  }


  /// Lấy tên danh mục theo ID
  Future<String> getCategoryName(String id) async {
    final category = await ProductService.getCategoryById(id);
    return category?.name ?? 'Không xác định';
  }Future<List<Product>> getHighRatedProducts({required double minRating}) async {
    try {
      final products = await ProductService.fetchAllProducts();

      final enrichedProducts = await Future.wait(products.map((product) async {
        final rating = await ProductService.getRating(product.id);
        return {
          'product': product,
          'averageRating': rating.averageRating,
          'reviewCount': rating.reviewCount,
        };
      }));

      final filtered = enrichedProducts
          .where((entry) =>
      (entry['averageRating'] is double ? entry['averageRating'] as double : 0.0) >= minRating)
          .map((entry) => entry['product'] as Product)
          .toList();

      debugPrint('→ Lọc sản phẩm rating >= $minRating: ${filtered.length} sản phẩm');
      return filtered;
    } catch (e, st) {
      debugPrint('❌ getHighRatedProducts error: $e\n$st');
      return [];
    }
  }
}
