import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../models/product.dart';
import '../../../models/Review.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final String imageUrl;
  final double averageRating;
  final int reviewCount;
  final double width;
  final double height;

  const ProductCard({
    super.key,
    required this.product,
    required this.imageUrl,
    required this.averageRating,
    required this.reviewCount,
    required this.width,
    required this.height,
  });

  Widget _smartImage(String imageUrl, {BoxFit fit = BoxFit.cover}) {
    if (imageUrl.isEmpty) {
      return const Icon(Icons.image_not_supported, size: 30);
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 30),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    try {
      final bytes = base64Decode(imageUrl);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 30),
      );
    } catch (_) {
      return const Icon(Icons.image_not_supported, size: 30);
    }
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 10);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 10);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 10);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final basePrice = product.minPrice;
    final discountPercentage = product.discountPercentage ?? 0.0;
    final discountedPrice = basePrice * (1 - discountPercentage / 100);

    return SizedBox(
      width: 130,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with discount badge
            Stack(
              children: [
                _smartImage(imageUrl, fit: BoxFit.cover),
                if (discountPercentage > 0)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${discountPercentage.round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Content (Footer)
            Padding(
              padding: const EdgeInsets.all(4.0), // Reduced from 6.0 to 4.0
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1), // Reduced from 2 to 1
                  Text(
                    '\$${discountedPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (discountPercentage > 0)
                    Text(
                      '\$${basePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  const SizedBox(height: 1), // Reduced from 2 to 1
                  Row(
                    children: [
                      _buildRatingStars(averageRating),
                      const SizedBox(width: 2),
                      Text(
                        '($reviewCount)',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}