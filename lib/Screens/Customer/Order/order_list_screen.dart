import 'package:flutter/material.dart';
import 'package:danentang/models/Order.dart';

class OrderListScreen extends StatelessWidget {
  final List<Order> orders;

  const OrderListScreen({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    final contentWidth = isWeb ? 800.0 : double.infinity;
    final padding = isWeb ? 32.0 : 16.0;
    final fontSize = isWeb ? 18.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: Text(
          'Đơn hàng của tui',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF2D3748)),
            onPressed: () {
              // Implement filter functionality if needed
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: contentWidth),
          padding: EdgeInsets.all(padding),
          child: orders.isEmpty
              ? Center(
            child: Text(
              'Chưa có đơn hàng nào.',
              style: TextStyle(fontSize: fontSize, color: const Color(0xFF718096)),
            ),
          )
              : ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              // Use the first item from the order
              final firstItem = order.items.isNotEmpty ? order.items.first : null;

              if (firstItem == null) return const SizedBox.shrink();

              // Parse variantName to extract color/size if needed
              final variantParts = firstItem.variantName.split(', ');
              String? colorSize = variantParts.isNotEmpty ? variantParts[0] : 'N/A';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: EdgeInsets.symmetric(vertical: padding / 2),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Product Image (Placeholder for now)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.watch,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Product Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstItem.productName,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                            /* Removed rating since it's not in OrderItem
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '4.8', // Placeholder, fetch from Product if available
                                        style: TextStyle(
                                          fontSize: fontSize - 2,
                                          color: const Color(0xFF718096),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.star,
                                        color: Colors.yellow,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                  */
                            const SizedBox(height: 4),
                            Text(
                              '₫${firstItem.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: fontSize,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              colorSize,
                              style: TextStyle(
                                fontSize: fontSize - 2,
                                color: const Color(0xFF718096),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // View Order Button
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to a detailed order screen if needed
                          print('View order: ${order.id}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A4FCF),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Xem đơn hàng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize - 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}