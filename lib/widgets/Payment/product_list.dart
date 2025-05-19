import 'package:flutter/material.dart';

class ProductList extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final double cardMaxWidth;
  final double cardMinHeight;

  const ProductList({
    super.key,
    required this.products,
    required this.cardMaxWidth,
    required this.cardMinHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh sách hàng',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 8),
        ...products.map((item) {
          final product = item['product'];
          final qty = item['quantity'] as int;
          final variant = item['color']?.toString() ?? 'Không có biến thể';
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: cardMinHeight, maxWidth: cardMaxWidth),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Icon(Icons.watch, size: 30, color: Color(0xFF718096))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          Text(
                            'Biến thể: $variant',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                          ),
                          Text(
                            'Số lượng: $qty',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₫${(product.price * qty).toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFFF56565),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}