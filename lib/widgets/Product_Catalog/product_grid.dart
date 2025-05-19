import 'package:flutter/material.dart';
import 'package:danentang/models/product.dart';
import 'package:danentang/ultis/image_helper.dart';
import '../../models/Review.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final bool isLoading;
  final ScrollController scrollController;
  final Map<String, List<Review>> productReviews;

  const ProductGrid({
    super.key,
    required this.products,
    required this.isLoading,
    required this.scrollController,
    required this.productReviews,
  });

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 12); // Smaller stars
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 12);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 12);
        }
      }),
    );
  }

  Widget _smartImage(String imageUrl, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    debugPrint('Processing image URL in ProductGrid: $imageUrl');

    if (imageUrl.isEmpty) {
      debugPrint('Image URL is empty');
      return const Icon(Icons.image_not_supported, size: 80); // Smaller placeholder
    }

    if (imageUrl.startsWith('http')) {
      debugPrint('Loading network image: $imageUrl');
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Network image error: $error');
          return const Icon(Icons.error, size: 80);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    try {
      String processedUrl = imageUrl;

      if (imageUrl.startsWith('data:image')) {
        final parts = imageUrl.split(',');
        if (parts.length == 2 && parts[0].contains('base64')) {
          processedUrl = parts[1];
          debugPrint('Extracted Base64 data: ${processedUrl.substring(0, processedUrl.length > 50 ? 50 : processedUrl.length)}...');
        } else {
          debugPrint('Invalid Base64 data URI format: $imageUrl');
          return const Icon(Icons.image_not_supported, size: 80);
        }
      }

      processedUrl = processedUrl.trim();

      return imageFromBase64String(
        processedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: null, // Use default fallback (Container with Icons.broken_image)
      );
    } catch (e) {
      debugPrint('Error processing image in ProductGrid: $e');
      return const Icon(Icons.image_not_supported, size: 80);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 200).floor().clamp(2, 6); // Dynamic columns: 2–6 based on screen width

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(8), // Reduced padding
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8, // Reduced spacing
        mainAxisSpacing: 8,
        childAspectRatio: 0.9, // More square cards
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final imageUrl = product.images.isNotEmpty ? product.images[0].url : '';
        final reviews = productReviews[product.id] ?? [];
        final valid = reviews.where((r) => r.rating != null).toList();
        final avgRating = valid.isNotEmpty
            ? valid.map((r) => r.rating!).reduce((a, b) => a + b) / valid.length
            : 0.0;
        final latestComment = valid.isNotEmpty ? valid.first.comment : '';

        return Card(
          elevation: 2, // Slightly lower elevation
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Smaller radius
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: _smartImage(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 100, // Fixed image height to reduce card size
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // Smaller font
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.minPrice == product.maxPrice
                          ? '${product.minPrice.toStringAsFixed(0)}đ'
                          : '${product.minPrice.toStringAsFixed(0)} - ${product.maxPrice.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12, // Smaller font
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _buildRatingStars(avgRating),
                        const SizedBox(width: 3),
                        Text(
                          '(${valid.length})',
                          style: const TextStyle(fontSize: 10), // Smaller font
                        ),
                      ],
                    ),
                    if (latestComment.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '"$latestComment"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 10, // Smaller font
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}