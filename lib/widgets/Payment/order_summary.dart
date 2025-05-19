import 'package:flutter/material.dart';

class OrderSummary extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double deliveryCharge;
  final double total;
  final double cardMaxWidth;

  const OrderSummary({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.deliveryCharge,
    required this.total,
    required this.cardMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tóm tắt đơn hàng',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            constraints: BoxConstraints(maxWidth: cardMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tạm tính', style: TextStyle(color: Color(0xFF2D3748))),
                      Text('₫${subtotal.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF2D3748))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Giảm giá', style: TextStyle(color: Color(0xFF2D3748))),
                      Text('₫${discount.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF2D3748))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Phí vận chuyển', style: TextStyle(color: Color(0xFF2D3748))),
                      Text('₫${deliveryCharge.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF2D3748))),
                    ],
                  ),
                ),
                const Divider(height: 16, color: Color(0xFFE2E8F0)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
                      Text('₫${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}