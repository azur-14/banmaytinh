// lib/models/ProductRating.dart

class ProductRating {
  final double averageRating;
  final int reviewCount;

  const ProductRating({
    required this.averageRating,
    required this.reviewCount,
  });

  /// Tạo từ JSON trả về từ API
  factory ProductRating.fromJson(Map<String, dynamic> json) {
    return ProductRating(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount:   (json['reviewCount']   as num?)?.toInt()    ?? 0,
    );
  }

  /// Chuyển ngược lại thành JSON (nếu cần gửi lên server)
  Map<String, dynamic> toJson() => {
    'averageRating': averageRating,
    'reviewCount':   reviewCount,
  };
}
