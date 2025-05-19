import 'package:flutter/material.dart';
import 'package:danentang/models/Order.dart';           // Đảm bảo đúng import model
import 'package:danentang/Service/order_service.dart';
import 'package:go_router/go_router.dart'; // Đảm bảo đúng service

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;

  const OrderSuccessScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  Order? order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      order = await OrderService.instance.getOrderById(widget.orderId);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    final contentWidth = isWeb ? 600.0 : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: isWeb
          ? null
          : AppBar(
        title: const Text('Đặt hàng thành công',
            style: TextStyle(color: Color(0xFF2D3748))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: contentWidth),
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const CircularProgressIndicator()
              : _error != null
              ? Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          )
              : order == null
              ? const Text("Không tìm thấy đơn hàng.")
              : SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF38B2AC),
                  size: 100,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Đặt hàng thành công!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mã đơn hàng: ${order!.orderNumber ?? order!.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin giao hàng',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Người nhận: ${order!.shippingAddress.receiverName}',
                        ),
                        Text(
                          'SĐT: ${order!.shippingAddress.phoneNumber}',
                        ),
                        if (order!.shippingAddress.email.isNotEmpty)
                          Text(
                              'Email: ${order!.shippingAddress.email}'),
                        Text(
                          'Địa chỉ: ${order!.shippingAddress.addressLine}, '
                              '${order!.shippingAddress.ward}, '
                              '${order!.shippingAddress.district}, '
                              '${order!.shippingAddress.city}',
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Sản phẩm đã đặt:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        ...order!.items.map((item) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.shopping_bag),
                          title: Text(item.productName),
                          subtitle: Text(
                              'Biến thể: ${item.variantName}\nSố lượng: ${item.quantity}'),
                          trailing: Text(
                              '${(item.price * item.quantity).toStringAsFixed(0)}đ'),
                        )),
                        const Divider(),
                        if (order!.couponCode != null &&
                            order!.couponCode!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Mã giảm giá: ${order!.couponCode}',
                              style: const TextStyle(
                                  color: Color(0xFF5A4FCF)),
                            ),
                          ),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng cộng:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${order!.totalAmount.toStringAsFixed(0)}đ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (order!.discountAmount > 0)
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Giảm giá:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w400),
                              ),
                              Text(
                                '-${order!.discountAmount.toStringAsFixed(0)}đ',
                                style: const TextStyle(
                                    color: Colors.green),
                              ),
                            ],
                          ),
                        if (order!.shippingFee > 0)
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Phí vận chuyển:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w400),
                              ),
                              Text(
                                '+${order!.shippingFee.toStringAsFixed(0)}đ',
                              ),
                            ],
                          ),
                        const SizedBox(height: 6),
                        Text(
                          'Trạng thái đơn hàng: ${order!.status}',
                          style: const TextStyle(
                              color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    context.go('/my-orders');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A4FCF),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Xem đơn hàng của tôi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
