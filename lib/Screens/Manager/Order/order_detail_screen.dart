import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Service/order_service.dart';
import '../../../models/Order.dart';
import '../../../models/OrderStatusHistory.dart';

class OrderDetailScreenMn extends StatefulWidget {
  final String orderId;
  final Order? order; // Thêm tham số tùy chọn để nhận từ extra

  const OrderDetailScreenMn({super.key, required this.orderId, this.order});

  @override
  State<OrderDetailScreenMn> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreenMn> {
  Order? _order;
  late String _selectedStatus;
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _statusOptions = [
    'pending',
    'in progress',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchOrder();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    if (token == null || role != 'admin') {
      context.go('/login');
    }
  }

  Future<void> _fetchOrder() async {
    try {
      // Nếu order được truyền từ extra, sử dụng nó để tối ưu hóa
      if (widget.order != null) {
        setState(() {
          _order = widget.order;
          _selectedStatus = _order!.status;
          _isLoading = false;
        });
      } else {
        final order = await OrderService.instance.getOrderById(widget.orderId);
        setState(() {
          _order = order;
          _selectedStatus = order.status;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải đơn hàng: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus() async {
    if (_order == null) return;
    if (_selectedStatus == _order!.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trạng thái không thay đổi')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận cập nhật'),
        content: Text('Bạn có chắc muốn cập nhật trạng thái thành "$_selectedStatus"?'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Hủy')),
          TextButton(onPressed: () => ctx.pop(true), child: const Text('Xác nhận')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final history = OrderStatusHistory(
        status: _selectedStatus,
        timestamp: DateTime.now(),
      );
      await OrderService.instance.updateOrderStatus(_order!.id!, history);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật trạng thái đơn hàng')),
      );
      context.go('/manager/orders?refresh=true');

    } catch (e) {
      setState(() => _errorMessage = 'Lỗi: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
        body: Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
      );
    }

    final order = _order!;
    final addr = order.shippingAddress;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) context.go('/manager/orders');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Chi tiết đơn hàng #${order.id}"),
          centerTitle: true,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrder),
          ],
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle("Thông tin người nhận"),
                _buildInfoRow("Họ tên", addr.receiverName),
                _buildInfoRow("SĐT", addr.phoneNumber),
                _buildInfoRow("Địa chỉ",
                    "${addr.addressLine}, ${addr.ward}, ${addr.district}, ${addr.city}"),
                const SizedBox(height: 16),
                _buildSectionTitle("Thông tin đơn hàng"),
                _buildInfoRow("Mã đơn hàng", order.orderNumber),
                _buildInfoRow("Tổng tiền", "${order.totalAmount.toStringAsFixed(0)} ₫"),
                if (order.discountAmount > 0)
                  _buildInfoRow("Giảm giá", "-${order.discountAmount.toStringAsFixed(0)} ₫"),
                if (order.couponCode != null)
                  _buildInfoRow("Mã giảm giá", order.couponCode!),
                _buildInfoRow("Điểm thưởng dùng", "${order.loyaltyPointsUsed}"),
                const SizedBox(height: 16),
                _buildSectionTitle("Danh sách sản phẩm"),
                ...order.items.map((item) => ListTile(
                  title: Text(item.productName),
                  subtitle: Text("Phân loại: ${item.variantName}\nSố lượng: ${item.quantity}"),
                  trailing: Text("${item.price.toStringAsFixed(0)} ₫"),
                )),
                const SizedBox(height: 16),
                _buildSectionTitle("Trạng thái đơn hàng"),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
                    border: OutlineInputBorder(),
                  ),
                  items: _statusOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStatus = v!),
                ),
                const SizedBox(height: 16),
                _buildSectionTitle("Lịch sử trạng thái"),
                if (order.statusHistory.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text("Chưa có lịch sử trạng thái"),
                  )
                else
                  ...order.statusHistory.map((h) => ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(h.status),
                    subtitle: Text(DateFormat('dd/MM/yyyy – HH:mm').format(h.timestamp)),
                  )),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                      icon: const Icon(Icons.save),
                      label: const Text("Lưu thay đổi"),
                      onPressed: _isLoading ? null : _updateOrderStatus,
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => context.go('/manager/orders'),
                      child: const Text("Hủy"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  );

  Widget _buildInfoRow(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Text("$title:", style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 3, child: Text(value)),
      ],
    ),
  );
}