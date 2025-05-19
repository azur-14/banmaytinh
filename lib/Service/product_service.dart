// lib/services/product_service.dart

import 'dart:convert';
import 'package:bson/bson.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/Category.dart';
import '../models/tag.dart';
import '../models/ProductRating.dart';
import '../models/Review.dart';

class ProductService {

  static const String _baseUrl         = 'https://productservice-production.up.railway.app/api';
  static const String _productsPath    = '$_baseUrl/products';
  static const String _categoriesPath  = '$_baseUrl/categories';
  static const String _tagsPath        = '$_baseUrl/Tag';
  static const String _productTagsPath = '$_baseUrl/product-tags';
  static Future<void> createProduct(Product product) async {
    // Bổ sung ID trước khi gửi
    final enrichedProduct = product.copyWith(
      images: product.images.map((img) {
        final id = (img.id == null || img.id.isEmpty) ? ObjectId().toHexString() : img.id;
        return ProductImage(
          id: id,
          url: img.url,
          sortOrder: img.sortOrder,
        );
      }).toList(),
      variants: product.variants.map((v) {
        final id = (v.id == null || v.id.isEmpty) ? ObjectId().toHexString() : v.id;
        return ProductVariant(
          id: id,
          variantName: v.variantName,
          originalPrice: v.originalPrice, // ✅ thêm dòng này
          additionalPrice: v.additionalPrice,
          inventory: v.inventory,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

      }).toList(),
    );

    final response = await http.post(
      Uri.parse('$_productsPath'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(enrichedProduct.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("Product created!");
    } else {
      throw Exception('Failed to create product (${response.statusCode}): ${response.body}');
    }
  }


  static Future<Product> updateProduct(Product p) async {
    // Tạo danh sách mới với id đảm bảo hợp lệ
    final newVariants = p.variants.map((v) {
      final id = (v.id == null || v.id!.isEmpty) ? ObjectId().toHexString() : v.id!;
      return ProductVariant(
        id: id,
        variantName: v.variantName,
        originalPrice: v.originalPrice, // ✅ thêm dòng này
        additionalPrice: v.additionalPrice,
        inventory: v.inventory,
        createdAt: v.createdAt,
        updatedAt: v.updatedAt,
      );

    }).toList();

    final updatedProduct = p.copyWith(variants: newVariants);

    final uri = Uri.parse('$_productsPath/${p.id}');
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedProduct.toJson()),
    );

    if (resp.statusCode == 200) {
      return Product.fromJson(json.decode(resp.body) as Map<String, dynamic>);
    }

    if (resp.statusCode == 204) {
      return updatedProduct;
    }

    throw Exception('Failed to update product (${resp.statusCode}): ${resp.body}');
  }
  /// DELETE /api/products/{id}
  static Future<void> deleteProduct(String id) async {
    final uri = Uri.parse('$_productsPath/$id');
    final resp = await http.delete(uri);
    if (resp.statusCode != 204) {
      throw Exception('Failed to delete product (${resp.statusCode})');
    }
  }
  /// GET /api/products
  static Future<List<Product>> fetchAllProducts() async {
    final uri = Uri.parse(_productsPath);
    debugPrint('→ GET $uri');
    try {
      final resp = await http.get(uri);
      debugPrint('← ${resp.statusCode} ${resp.body}');
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List<dynamic>;
        return data
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('‼️ fetchAllProducts API error ${resp.statusCode}');
      }
    } catch (e, st) {
      debugPrint('❌ fetchAllProducts exception: $e\n$st');
    }
    return [];
  }
  /// GET /api/categories/{id}
  static Future<Category?> getCategoryById(String id) async {
    final uri = Uri.parse('$_categoriesPath/$id');
    debugPrint('→ GET $uri');
    try {
      final resp = await http.get(uri);
      debugPrint('← ${resp.statusCode} ${resp.body}');
      if (resp.statusCode == 200) {
        return Category.fromJson(json.decode(resp.body));
      } else if (resp.statusCode == 404) {
        return null;
      }
      debugPrint('‼️ getCategoryById API error ${resp.statusCode}');
    } catch (e, st) {
      debugPrint('❌ getCategoryById exception: $e\n$st');
    }
    return null;
  }

  /// POST /api/categories
  static Future<Category?> createCategory(Category category) async {
    final uri = Uri.parse(_categoriesPath);
    final body = jsonEncode(category.toJson());
    debugPrint('→ POST $uri\n$body');
    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      debugPrint('← ${resp.statusCode} ${resp.body}');
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return Category.fromJson(json.decode(resp.body));
      } else {
        debugPrint('‼️ createCategory failed: ${resp.statusCode}');
      }
    } catch (e, st) {
      debugPrint('❌ createCategory exception: $e\n$st');
    }
    return null;
  }

  /// DELETE /api/categories/{id}
  static Future<bool> deleteCategory(String id) async {
    final uri = Uri.parse('$_categoriesPath/$id');
    debugPrint('→ DELETE $uri');
    try {
      final resp = await http.delete(uri);
      debugPrint('← ${resp.statusCode}');
      if (resp.statusCode == 204) return true;
      if (resp.statusCode == 400) {
        debugPrint('‼️ Cannot delete category in use.');
      }
    } catch (e, st) {
      debugPrint('❌ deleteCategory exception: $e\n$st');
    }
    return false;
  }
  static Future<bool> updateCategory(String id, Category updated) async {
    final uri = Uri.parse('$_categoriesPath/$id');
    final body = jsonEncode(updated.toJson());

    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    debugPrint('← PUT $uri: ${resp.statusCode}');
    return resp.statusCode == 204;
  }

  /// GET /api/categories
  static Future<List<Category>> fetchAllCategories() async {
    final uri = Uri.parse(_categoriesPath);
    debugPrint('→ GET $uri');
    try {
      final resp = await http.get(uri);
      debugPrint('← ${resp.statusCode} ${resp.body}');
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List<dynamic>;
        return data
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('‼️ fetchAllCategories API error ${resp.statusCode}');
      }
    } catch (e, st) {
      debugPrint('❌ fetchAllCategories exception: $e\n$st');
    }
    return [];
  }

  /// GET /api/Tag
  static Future<List<Tag>> fetchAllTags() async {
    final uri = Uri.parse(_tagsPath);
    debugPrint('→ GET $uri');
    try {
      final resp = await http.get(uri);
      debugPrint('← ${resp.statusCode} ${resp.body}');
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List<dynamic>;
        return data
            .map((e) => Tag.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('‼️ fetchAllTags API error ${resp.statusCode}');
      }
    } catch (e, st) {
      debugPrint('❌ fetchAllTags exception: $e\n$st');
    }
    return [];
  }
  /// GET /api/product-tags/by-tag/{tagId}
  static Future<List<Product>> fetchProductsByTag(String tagId) async {
    // 1) Trim whitespace (đảm bảo đúng 24 ký tự hex)
    final trimmedId = tagId.trim();

    // 2) Build URI
    final uri = Uri.parse('$_productTagsPath/by-tag/$trimmedId');
    debugPrint('→ GET $uri');

    // 3) Thực hiện request
    final resp = await http.get(uri);
    debugPrint('← ${resp.statusCode} ${resp.body}');

    // 4) Xử lý response
    if (resp.statusCode == 200) {
      final List<dynamic> data = json.decode(resp.body) as List<dynamic>;
      return data
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('fetchProductsByTag failed: ${resp.statusCode}');
    }
  }

  /// GET /api/product-tags/by-product/{productId}
  static Future<List<Tag>> fetchTagsOfProduct(String productId) async {
    final uri = Uri.parse('$_productTagsPath/by-product/$productId');
    debugPrint('→ GET $uri');
    final resp = await http.get(uri);
    debugPrint('← ${resp.statusCode} ${resp.body}');
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as List<dynamic>;
      return data.map((e) => Tag.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('fetchTagsOfProduct failed: ${resp.statusCode}');
  }
  /// GET /api/product-tags/tags-with-products
  static Future<List<Tag>> fetchTagsWithProducts() async {
    final uri = Uri.parse('$_productTagsPath/tags-with-products');
    debugPrint('→ GET $uri');
    final resp = await http.get(uri);
    debugPrint('← ${resp.statusCode} ${resp.body}');

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as List<dynamic>;
      return data
          .map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('fetchTagsWithProducts failed: ${resp.statusCode}');
  }

  /// POST /api/product-tags
  static Future<void> assignTagToProduct(String productId, String tagId) async {
    // client phải tự sinh Id cho ProductTag nếu controller không generate
    final body = jsonEncode({
      'id': ObjectId().toHexString(),
      'productId': productId,
      'tagId': tagId,
    });
    final resp = await http.post(
      Uri.parse('$_productTagsPath'),
      headers: {'Content-Type':'application/json'},
      body: body,
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('assignTagToProduct failed: ${resp.statusCode}');
    }
  }

  /// DELETE /api/product-tags?productId=...&tagId=...
  static Future<void> removeTagFromProduct(String productId, String tagId) async {
    final uri = Uri.parse(
        '$_productTagsPath?productId=$productId&tagId=$tagId'
    );
    final resp = await http.delete(uri);
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('removeTagFromProduct failed: ${resp.statusCode}');
    }
  }

  /// PUT /api/product-tags/by-product/{productId}
  /// Bulk-update: xóa hết và chèn lại những tagIds cho product
  static Future<void> upsertTagsForProduct(
      String productId, List<String> tagIds) async {
    final uri = Uri.parse('$_productTagsPath/by-product/$productId');
    final resp = await http.put(
      uri,
      headers: {'Content-Type':'application/json'},
      body: jsonEncode({'tagIds': tagIds}),
    );
    if (resp.statusCode != 204 && resp.statusCode != 200) {
      throw Exception('upsertTagsForProduct failed: ${resp.statusCode}');
    }
  }

  /// GET /api/products/category/{categoryId}
  static Future<List<Product>> fetchProductsByCategory(String categoryId) async {
    final uri = Uri.parse('$_productsPath/category/$categoryId');
    debugPrint('→ GET $uri');
    try {
      final resp = await http.get(uri);
      debugPrint('← ${resp.statusCode} ${resp.body}');
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List<dynamic>;
        return data
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('‼️ fetchProductsByCategory API error ${resp.statusCode}');
      }
    } catch (e, st) {
      debugPrint('❌ fetchProductsByCategory exception: $e\n$st');
    }
    return [];
  }

  /// GET /api/products/{id}
  static Future<Product> getById(String id) async {
    final uri = Uri.parse('$_productsPath/$id');
    debugPrint('→ GET $uri');
    final resp = await http.get(uri);
    debugPrint('← ${resp.statusCode} ${resp.body}');
    if (resp.statusCode == 200) {
      return Product.fromJson(json.decode(resp.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load product $id (status ${resp.statusCode})');
  }

  /// GET /api/products/{id}/rating
  static Future<ProductRating> getRating(String productId) async {
    final uri  = Uri.parse('$_productsPath/$productId/rating');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      return ProductRating.fromJson(
          json.decode(resp.body) as Map<String, dynamic>
      );
    }
    return const ProductRating(averageRating: 0, reviewCount: 0);
  }

  /// GET /api/products/{id}/reviews
  static Future<List<Review>> getReviews(String productId) async {
    final uri  = Uri.parse('$_productsPath/$productId/reviews');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as List<dynamic>;
      return data
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('getReviews failed (${resp.statusCode})');
  }

  /// POST /api/products/{id}/reviews
  /// guestName: tên khách nếu chưa login
  static Future<void> submitReview({
    required String productId,
    String? guestName,
    int? rating,
    required String comment,
    String? sentiment, // ✅ Thêm vào đây
  }) async {
    final uri = Uri.parse('$_productsPath/$productId/reviews');
    final body = {
      'comment': comment,
      if (rating != null) 'rating': rating,
      if (guestName != null) 'guestName': guestName,
      if (sentiment != null) 'sentiment': sentiment, // ✅ Gửi sentiment nếu có
    };
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('submitReview failed (${resp.statusCode})');
    }
  }

  /// GET /api/products/{id}
  Future<Product> getProductById(String id) async {
    final uri = Uri.parse('$_productsPath/$id');
    debugPrint('→ GET $uri');
    final resp = await http.get(uri);
    debugPrint('← ${resp.statusCode} ${resp.body}');
    if (resp.statusCode == 200) {
      return Product.fromJson(json.decode(resp.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load product $id: ${resp.statusCode}');
  }

  /// GET /api/products/{productId}/variants
  static Future<List<ProductVariant>> fetchVariants(String productId) async {
    final uri = Uri.parse('$_productsPath/$productId/variants');
    debugPrint('→ GET $uri');
    final resp = await http.get(uri);
    debugPrint('← ${resp.statusCode} ${resp.body}');
    if (resp.statusCode == 200) {
      final List<dynamic> data = json.decode(resp.body) as List<dynamic>;
      return data
          .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load variants for product $productId: ${resp.statusCode}');
  }

  /// GET /api/products/{productId}/variants/{variantId}
  Future<ProductVariant> getVariantById(String productId, String variantId) async {
    final variants = await fetchVariants(productId);
    try {
      return variants.firstWhere((v) => v.id == variantId);
    } catch (_) {
      throw Exception('Variant $variantId not found for product $productId');
    }
  }
  /// GET  /api/products/{productId}/images
  static Future<List<ProductImage>> fetchImages(String productId) async {
    final uri = Uri.parse('$_productsPath/$productId/images');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as List;
      return data.map((e) => ProductImage.fromJson(e)).toList();
    }
    throw Exception('fetchImages failed: ${resp.statusCode}');
  }

  /// POST /api/products/{productId}/images
  static Future<ProductImage> addImage(String productId, ProductImage img) async {
    final uri = Uri.parse('$_productsPath/$productId/images');
    final resp = await http.post(
      uri,
      headers: {'Content-Type':'application/json'},
      body: jsonEncode(img.toJson()),
    );
    if (resp.statusCode == 200) {
      return ProductImage.fromJson(json.decode(resp.body));
    }
    throw Exception('addImage failed: ${resp.statusCode}');
  }

  /// PUT  /api/products/{productId}/images/{imageId}
  static Future<void> updateImage(String productId, ProductImage img) async {
    final uri = Uri.parse('$_productsPath/$productId/images/${img.id}');
    final resp = await http.put(
      uri,
      headers: {'Content-Type':'application/json'},
      body: jsonEncode(img.toJson()),
    );
    if (resp.statusCode != 204) {
      throw Exception('updateImage failed: ${resp.statusCode}');
    }
  }

  /// DELETE /api/products/{productId}/images/{imageId}
  static Future<void> deleteImage(String productId, String imageId) async {
    final uri = Uri.parse('$_productsPath/$productId/images/$imageId');
    final resp = await http.delete(uri);
    if (resp.statusCode != 204) {
      throw Exception('deleteImage failed: ${resp.statusCode}');
    }
  }
  // —— Variant CRUD —— //

  static Future<ProductVariant> addVariant(String productId, ProductVariant v) async {
    final uri = Uri.parse('$_productsPath/$productId/variants');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(v.toJson()),
    );
    if (resp.statusCode == 200) {
      final variant = ProductVariant.fromJson(json.decode(resp.body));

      return variant;
    }
    throw Exception('addVariant failed: ${resp.statusCode})');
  }

  /// PUT  /api/products/{productId}/variants/{variantId}
  static Future<void> updateVariant(String productId, ProductVariant v) async {
    // Lấy số lượng hiện có trên server
    final oldVariants = await fetchVariants(productId);
    final old = oldVariants.firstWhere((e) => e.id == v.id, orElse: () => v);
    final int oldInventory = old.inventory;

    // Gửi cập nhật variant lên server
    final uri = Uri.parse('$_productsPath/$productId/variants/${v.id}');
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(v.toJson()),
    );

    if (resp.statusCode != 204) {
      throw Exception('updateVariant failed: ${resp.statusCode}');
    }
  }


  /// DELETE /api/products/{productId}/variants/{variantId}
  static Future<void> deleteVariant(String productId, String variantId) async {
    final uri = Uri.parse('$_productsPath/$productId/variants/$variantId');
    final resp = await http.delete(uri);
    if (resp.statusCode != 204) {
      throw Exception('deleteVariant failed: ${resp.statusCode}');
    }
  }
}
