// lib/widgets/product_section.dart

import 'package:flutter/material.dart';
import 'package:danentang/models/product.dart';
import 'package:danentang/widgets/product_card.dart';

typedef ProductTapCallback = void Function(Product product);

class ProductSection extends StatelessWidget {
  final String title;
  final List<Product> products;
  final bool isWeb;
  final double screenWidth;
  final ProductTapCallback onTap;

  const ProductSection({
    Key? key,
    required this.title,
    required this.products,
    required this.isWeb,
    required this.screenWidth,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const cardWidth = 180.0;
    final padding = isWeb ? 32.0 : 16.0;
    final itemsPerRow = ((screenWidth - 2 * padding) / (cardWidth + 8)).floor();
    final crossAxisCount = itemsPerRow > 0 ? itemsPerRow : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        // Grid of products
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: cardWidth / 250,
            ),
            itemCount: products.length,
            itemBuilder: (ctx, i) {
              final product = products[i];
              return GestureDetector(
                onTap: () => onTap(product),
                child: ProductCard(product: product),
              );
            },
          ),
        ),
      ],
    );
  }
}
