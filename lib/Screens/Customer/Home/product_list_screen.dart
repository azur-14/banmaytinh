import 'package:flutter/material.dart';
import 'package:danentang/models/product.dart';
import 'package:danentang/widgets/product_card.dart';

class ProductListScreen extends StatelessWidget {
  final String title;
  final List<Product> products;
  final bool isWeb;

  const ProductListScreen({
    required this.title,
    required this.products,
    required this.isWeb,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWeb ? 5 : 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: products[index]);
        },
      ),
    );
  }
}