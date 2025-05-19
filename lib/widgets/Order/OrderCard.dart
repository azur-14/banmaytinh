import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../Service/order_service.dart';
import '../../Service/product_service.dart';
import '../../models/Order.dart';
import '../../models/OrderItem.dart';
import '../../models/OrderStatusHistory.dart';
import '../../models/product.dart';
import 'package:danentang/ultis/image_helper.dart';

// Màn hình danh sách đơn hàng
class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final int _itemsPerPage = 10; // Số đơn hàng mỗi trang
  int _currentPage = 1; // Trang hiện tại

  // Lấy danh sách đơn hàng từ OrderService
  Future<List<Order>> _fetchSortedOrders() async {
    final orders = await OrderService.fetchAllOrders();
    // Sắp xếp theo createdAt giảm dần (mới nhất lên đầu)
    return orders..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  Future<List<Product>> _fetchAllProducts() async {
    return await ProductService.fetchAllProducts(); // Đảm bảo bạn đã import đúng ProductService
  }
  Future<Map<String, dynamic>> _fetchData() async {
    final orders = await _fetchSortedOrders();
    final products = await _fetchAllProducts();
    return {
      'orders': orders,
      'products': products,
    };
  }

  // Lấy danh sách đơn hàng cho trang hiện tại
  List<Order> _getPagedOrders(List<Order> orders) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return orders.sublist(
      startIndex,
      endIndex > orders.length ? orders.length : endIndex,
    );
  }

  // Tổng số trang
  int _getTotalPages(List<Order> orders) => (orders.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách đơn hàng'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final orders = data['orders'] as List<Order>;
          final products = data['products'] as List<Product>;

          if (orders.isEmpty) {
            return const Center(child: Text('Không có đơn hàng nào'));
          }

          final pagedOrders = _getPagedOrders(orders);
          final totalPages = _getTotalPages(orders);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: pagedOrders.length,
                  itemBuilder: (context, index) => OrderCard(
                    order: pagedOrders[index],
                    products: products, // ✅ Truyền products vào đây
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Trang trước', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Trang $_currentPage / $totalPages',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Trang sau', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// OrderCard (giữ nguyên từ mã gốc)
class OrderCard extends StatefulWidget {
  final Order order;
  final List<Product> products;

  const OrderCard({super.key, required this.order, required this.products});

  @override
  _OrderCardState createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  void _cancelOrder() {
    setState(() {
      widget.order.status = 'Đã hủy';
      widget.order.statusHistory.add(OrderStatusHistory(
        status: 'Đã hủy',
        timestamp: DateTime.now(),
      ));
      widget.order.updatedAt = DateTime.now();
    });
  }

  void _confirmDelivery() {
    setState(() {
      widget.order.status = 'Đã giao';
      widget.order.statusHistory.add(OrderStatusHistory(
        status: 'Đã giao',
        timestamp: DateTime.now(),
      ));
      widget.order.updatedAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.order.status == 'Đang chờ xử lý' || widget.order.status == 'Đặt hàng';
    final isShipped = widget.order.status == 'Đang giao';
    final isDelivered = widget.order.status == 'Đã giao';
    final isCanceled = widget.order.status == 'Đã hủy';

    Color statusColor = Colors.grey;
    if (isCanceled) {
      statusColor = Colors.red;
    } else if (isDelivered) {
      statusColor = Colors.green;
    } else if (isShipped) {
      statusColor = Colors.blue[700]!;
    } else if (isPending) {
      statusColor = Colors.orange;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn hàng #${widget.order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  widget.order.status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Sản phẩm:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            ...widget.order.items.map((item) => _buildOrderItem(item)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  '₫${NumberFormat('#,##0', 'vi_VN').format(widget.order.totalAmount)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ngày đặt:',
                  style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
                ),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(widget.order.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPending)
                  ElevatedButton(
                    onPressed: _cancelOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Hủy đơn',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    context.push('/order-details/${widget.order.id}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Xem chi tiết',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                if (isDelivered) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => context.push('/review/${widget.order.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Đánh giá',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => context.push('/return/${widget.order.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Trả hàng',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    final Product product = widget.products.firstWhere(
          (p) => p.variants.any((v) => v.id == item.productVariantId),
      orElse: () => Product(
        id: '',
        name: 'Sản phẩm không tìm thấy',
        brand: '',
        description: '',
        discountPercentage: 0,
        categoryId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        images: [],
        variants: [],
      ),
    );

    final imageUrl = product.images.isNotEmpty ? product.images.first.url : 'assets/placeholder.jpg';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageFromBase64String(
              imageUrl,
              width: 80,
              height: 80,
              placeholder: const AssetImage('assets/placeholder.jpg'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Biến thể: ${item.variantName} | Số lượng: ${item.quantity}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '₫${NumberFormat('#,##0', 'vi_VN').format(item.price * item.quantity)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          if (widget.order.status == 'Đang giao')
            ElevatedButton(
              onPressed: _confirmDelivery,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}