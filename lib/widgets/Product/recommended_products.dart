import 'package:flutter/material.dart';
import 'package:danentang/models/product.dart';

class RecommendedProducts extends StatelessWidget {
  final List<Product> recommendedProducts;
  const RecommendedProducts({super.key, required this.recommendedProducts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sản phẩm đề xuất",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: recommendedProducts.isEmpty
                ? const Center(child: Text("Không có sản phẩm đề xuất."))
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recommendedProducts.length,
              itemBuilder: (context, index) {
                final product = recommendedProducts[index];

                // 1. Tìm biến thể rẻ nhất
                final cheapestVariant = product.variants.isNotEmpty
                    ? product.variants.reduce((a, b) =>
                a.additionalPrice < b.additionalPrice ? a : b)
                    : null;
                final basePrice = cheapestVariant?.additionalPrice ?? 0.0;

                // 2. Áp discount
                final discountedPrice = basePrice *
                    (1 - product.discountPercentage / 100);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Card(
                    clipBehavior: Clip.hardEdge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hình ảnh
                          product.images.isNotEmpty
                              ? Image.network(
                            product.images[0].url,
                            height: 80,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                Container(
                                  height: 80,
                                  color: Colors.grey[300],
                                  child:
                                  const Icon(Icons.broken_image),
                                ),
                          )
                              : Container(
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          ),
                          const SizedBox(height: 4),
                          // Tên
                          Text(
                            product.name,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // Giá
                          Row(
                            children: [
                              Text(
                                "₫${discountedPrice.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (product.discountPercentage > 0)
                                const SizedBox(width: 4),
                              if (product.discountPercentage > 0)
                                Text(
                                  "₫${basePrice.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    decoration:
                                    TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
