// lib/models/product.dart

class Product {
  final String id;
  final String name;
  final String? brand;
  final String? description;
  final int discountPercentage;
  final String categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProductImage> images;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.name,
    this.brand,
    this.description,
    required this.discountPercentage,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
    required this.variants,
  });
  double get minPrice {
    if (variants.isEmpty) return 0;
    return variants.map((v) => v.additionalPrice).reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (variants.isEmpty) return 0;
    return variants.map((v) => v.additionalPrice).reduce((a, b) => a > b ? a : b);
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'description': description,
    'discountPercentage': discountPercentage,
    'categoryId': categoryId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'images': images.map((i) => i.toJson()).toList(),
    'variants': variants.map((v) => v.toJson()).toList(),
  };
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    brand: json['brand'] as String?,
    description: json['description'] as String?,
    discountPercentage: json['discountPercentage'] as int,
    categoryId: json['categoryId'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    images: (json['images'] as List<dynamic>)
        .map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
        .toList(),
    variants: (json['variants'] as List<dynamic>)
        .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  // copyWith ở đây:
  Product copyWith({
    String? name,
    String? brand,
    String? description,
    int? discountPercentage,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ProductImage>? images,
    List<ProductVariant>? variants,
  }) {
    return Product(
      id: this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
      variants: variants ?? this.variants,
    );
  }
}

class ProductImage {
  final String id;      // cho phép null
  final String url;
  final int sortOrder;

  ProductImage({
    required this.id,
    required this.url,
    required this.sortOrder,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'sortOrder': sortOrder,
  };
  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
    id: json['id'] ?? '', // <-- lỗi thường ở đây nếu quên
    url: json['url'],
    sortOrder: json['sortOrder'] ?? 0,
  );
}

class ProductVariant {
  final String id;
  final String variantName;
  final double originalPrice; // ✅ Thêm giá gốc
  final double additionalPrice;
  final int inventory;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductVariant({
    required this.id,
    required this.variantName,
    required this.originalPrice,
    required this.additionalPrice,
    required this.inventory,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'variantName': variantName,
    'originalPrice': originalPrice,        // ✅ serialize giá gốc
    'additionalPrice': additionalPrice,
    'inventory': inventory,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ProductVariant.fromJson(Map<String, dynamic> json) =>
      ProductVariant(
        id: json['id'] as String,
        variantName: json['variantName'] as String,
        originalPrice: (json['originalPrice'] ?? 0).toDouble(),  // ✅ parse giá gốc
        additionalPrice: (json['additionalPrice'] as num).toDouble(),
        inventory: json['inventory'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}


