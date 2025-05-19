import 'package:flutter/material.dart';
import 'package:danentang/models/Order.dart';
import 'package:danentang/models/OrderStatusHistory.dart';
import 'package:danentang/models/product.dart';
import 'package:danentang/Service/order_service.dart';
import 'package:danentang/Service/product_service.dart';
import 'package:danentang/ultis/image_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> with SingleTickerProviderStateMixin {
  Order? order;
  List<Product> products = [];
  bool _isLoading = true;
  late AnimationController _controller;
  late Animation<double> _animation;
  String? _error;
  final List<String> _statusOptions = [
    'pending',
    'in progress',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final fetchedOrder = await OrderService.instance.getOrderById(widget.orderId);
      final fetchedProducts = await ProductService.fetchAllProducts();
      setState(() {
        order = fetchedOrder;
        products = fetchedProducts;
        _isLoading = false;
      });
      _controller.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmDelivery() async {
    if (order == null) return;
    setState(() => _isLoading = true);
    try {
      final newStatus = OrderStatusHistory(
        status: 'Đã giao',
        timestamp: DateTime.now(),
      );
      await OrderService.instance.updateOrderStatus(order!.id!, newStatus);
      await _fetchData();
      // Sau khi xác nhận, chuyển sang review
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.push('/review/${order!.id}');
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B5EFC),
        elevation: 4,
        title: Text(
          order != null
              ? 'Chi tiết đơn hàng #${order!.orderNumber ?? order!.id}'
              : 'Chi tiết đơn hàng',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4B5EFC)))
            : _error != null
            ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
            : (order == null)
            ? const Center(child: Text('Không tìm thấy đơn hàng'))
            : LayoutBuilder(
          builder: (context, constraints) {
            final expectedDeliveryDate = order!.createdAt.add(const Duration(days: 5));
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  margin: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                      child: FadeTransition(
                        opacity: _animation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Thông tin đơn hàng'),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 4,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow('Mã đơn hàng:', order!.id ?? order!.id!),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      'Ngày đặt hàng:',
                                      DateFormat('dd MMM yyyy, HH:mm').format(order!.createdAt),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      'Tổng tiền:',
                                      '₫${NumberFormat('#,##0', 'vi_VN').format(order!.totalAmount)}',
                                      isBold: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Địa chỉ giao hàng'),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 4,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Wrap(
                                  spacing: 16.0,
                                  runSpacing: 12.0,
                                  children: [
                                    _buildAddressInfo('Tên người nhận:', order!.shippingAddress.receiverName),
                                    _buildAddressInfo('Địa chỉ:', order!.shippingAddress.addressLine),
                                    _buildAddressInfo('Phường/Xã:', order!.shippingAddress.ward),
                                    _buildAddressInfo('Quận/Huyện:', order!.shippingAddress.district),
                                    _buildAddressInfo('Thành phố:', order!.shippingAddress.city),
                                    _buildAddressInfo('Số điện thoại:', order!.shippingAddress.phoneNumber),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Sản phẩm'),
                            const SizedBox(height: 12),
                            ...order!.items.map((item) {
                              final product = products.firstWhere(
                                    (p) => p.variants.any((v) => v.id == item.productVariantId),
                                orElse: () => Product(
                                  id: '',
                                  name: 'Sản phẩm không tìm thấy',
                                  discountPercentage: 0,
                                  categoryId: '',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  images: [],
                                  variants: [],
                                ),
                              );
                              final imageUrl = product.images.isNotEmpty
                                  ? product.images.first.url
                                  : 'assets/placeholder.jpg';

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Card(
                                  elevation: 2,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Hero(
                                          tag: 'product-image-${item.productVariantId ?? item.productName.hashCode}',
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.asset(
                                              imageUrl,
                                              width: screenWidth * 0.25 > 80 ? 80 : screenWidth * 0.25,
                                              height: screenWidth * 0.25 > 80 ? 80 : screenWidth * 0.25,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Image.asset(
                                                  'assets/placeholder.jpg',
                                                  width: screenWidth * 0.25 > 80 ? 80 : screenWidth * 0.25,
                                                  height: screenWidth * 0.25 > 80 ? 80 : screenWidth * 0.25,
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Biến thể: ${item.variantName} | Số lượng: ${item.quantity}',
                                                style: const TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontSize: 13,
                                                ),
                                              ),
                                              if (item.productVariantId != null) ...[
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Mã biến thể: ${item.productVariantId}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF64748B),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 8),
                                              Text(
                                                '₫${NumberFormat('#,##0', 'vi_VN').format(item.price * item.quantity)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Tình trạng đơn hàng'),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 4,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: _buildOrderStatusTimeline(order!),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: order != null && order!.status == 'Đang giao'
          ? FloatingActionButton.extended(
        onPressed: _confirmDelivery,
        backgroundColor: const Color(0xFF4B5EFC),
        label: const Text(
          'Xác nhận đã nhận hàng',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: const Icon(Icons.check, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )
          : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF1E293B),
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressInfo(String label, String value) {
    return SizedBox(
      width: 300,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusTimeline(Order order) {
    final List<Map<String, dynamic>> statuses = [
      {'key': 'pending',     'label': 'Chờ xử lý', 'icon': Icons.hourglass_empty},
      {'key': 'in progress', 'label': 'Đang giao',  'icon': Icons.local_shipping},
      {'key': 'delivered',   'label': 'Đã giao',    'icon': Icons.check_circle},
      {'key': 'cancelled',   'label': 'Đã hủy',     'icon': Icons.cancel},
    ];

    return Column(
      children: List.generate(statuses.length, (index) {
        final statusKey = statuses[index]['key'] as String;
        final statusLabel = statuses[index]['label'] as String;
        final icon        = statuses[index]['icon'] as IconData;
        final isCurrent   = order.status == statusKey;
        final historyItem = order.statusHistory.firstWhere(
              (h) => h.status == statusKey,
          orElse: () => OrderStatusHistory(status: '', timestamp: order.createdAt),
        );
        final isCompleted = order.statusHistory.any((h) => h.status == statusKey) || isCurrent;
        final isLast      = index == statuses.length - 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  // icon vòng tròn
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? const Color(0xFF4B5EFC)
                          : (isCompleted ? const Color(0xFF22C55E) : Colors.grey.shade200),
                    ),
                    child: Icon(icon, size: 18, color: Colors.white),
                  ),
                  // đường nối
                  if (!isLast)
                    Container(
                      height: 48,
                      width: 2,
                      color: isCompleted ? const Color(0xFF22C55E) : Colors.grey.shade200,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                        color: isCompleted || isCurrent
                            ? const Color(0xFF1E293B)
                            : Colors.grey.shade500,
                      ),
                    ),
                    if (order.statusHistory.any((h) => h.status == statusKey))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('dd/MM/yyyy – HH:mm').format(historyItem.timestamp),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
