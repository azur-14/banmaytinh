import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:danentang/models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int index;

  const ProductCard({
    super.key,
    required this.product,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final originalPrice = product.variants.isNotEmpty ? product.variants[0].additionalPrice : 0;
    final discountedPrice = originalPrice * (1 - product.discountPercentage / 100);

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Flexible(
            child: AspectRatio(
              aspectRatio: 1, // Square image to prevent overflow
              child: _safeBase64Image(
                product.images.isNotEmpty ? product.images[0].url : '',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          // Content section
          Padding(
            padding: const EdgeInsets.all(6), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12, // Smaller font
                  ),
                  maxLines: 1, // Reduced to 1 line
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.variants.isNotEmpty)
                  Text(
                    product.variants[0].variantName,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]), // Smaller font
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  product.description ?? '',
                  style: const TextStyle(fontSize: 10), // Smaller font
                  maxLines: 1, // Reduced to 1 line
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2), // Reduced spacing
                Text(
                  'đ${discountedPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12, // Smaller font
                  ),
                ),
                if (product.discountPercentage > 0)
                  Text(
                    'đ${originalPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey[600],
                      fontSize: 10, // Smaller font
                    ),
                  ),
                const SizedBox(height: 2), // Reduced spacing
                Row(
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.blue[300]), // Smaller icon
                    Text(
                      '${(index % 5) + 1}.0',
                      style: const TextStyle(fontSize: 10), // Smaller font
                    ),
                  ],
                ),
                const SizedBox(height: 2), // Reduced spacing
                const Text(
                  'Last updated: 11:26 AM +07 on Sunday, May 18, 2025',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4), // Reduced spacing
                ElevatedButton(
                  onPressed: () {
                    debugPrint('Add to Cart clicked for ${product.name}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 28), // Smaller button
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 10), // Smaller text
                  ),
                  child: const Text('Add to Cart'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _safeBase64Image(
      String base64String, {
        double? width,
        double? height,
        BoxFit? fit,
      }) {
    try {
      if (base64String.isEmpty || !base64String.startsWith('data:image')) {
        return _fallbackImage(width, height);
      }
      final base64Data = base64String.split(',').last; // Extract Base64 part
      final bytes = base64Decode(base64Data);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image error: $error');
          return _fallbackImage(width, height);
        },
      );
    } catch (e) {
      debugPrint('Image decode error: $e');
      return _fallbackImage(width, height);
    }
  }

  Widget _fallbackImage(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported,
        size: 40,
        color: Colors.grey,
      ),
    );
  }
}