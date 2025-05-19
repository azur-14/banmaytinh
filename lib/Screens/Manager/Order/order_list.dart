import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/Order.dart';
import '../../../Service/order_service.dart';
import '../../../widgets/Footer/mobile_navigation_bar.dart';

class OrderListScreenMn extends StatefulWidget {
  const OrderListScreenMn({super.key});

  @override
  State<OrderListScreenMn> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreenMn> {
  late Future<List<Order>> _ordersFuture;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  static const int _itemsPerPage = 20;

  String selectedFilter = 'all';
  String? selectedStatus;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadFilters();
    _refreshOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final refreshParam = GoRouterState.of(context).uri.queryParameters['refresh'];
    if (refreshParam == 'true') {
      _refreshOrders();
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    if (token == null || role != 'admin') {
      context.go('/login');
    }
  }

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedFilter = prefs.getString('order_filter') ?? 'all';
      selectedStatus = prefs.getString('order_status');
      final start = prefs.getInt('order_start_date');
      final end = prefs.getInt('order_end_date');
      if (start != null) startDate = DateTime.fromMillisecondsSinceEpoch(start);
      if (end != null) endDate = DateTime.fromMillisecondsSinceEpoch(end);
    });
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('order_filter', selectedFilter);
    if (selectedStatus != null) {
      await prefs.setString('order_status', selectedStatus!);
    } else {
      await prefs.remove('order_status');
    }
    if (startDate != null) {
      await prefs.setInt('order_start_date', startDate!.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      await prefs.setInt('order_end_date', endDate!.millisecondsSinceEpoch);
    }
  }

  void _refreshOrders() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _ordersFuture = OrderService.fetchAllOrders().then(_applyFilters).whenComplete(() {
        setState(() => _isLoading = false);
      });
    });
  }

  List<Order> _applyFilters(List<Order> all) {
    final now = DateTime.now();
    List<Order> filtered = all;

    if (selectedFilter == 'today') {
      filtered = filtered.where((o) =>
      o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day).toList();
    } else if (selectedFilter == 'week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      filtered = filtered.where((o) => o.createdAt.isAfter(startOfWeek)).toList();
    } else if (selectedFilter == 'month') {
      filtered = filtered.where((o) =>
      o.createdAt.year == now.year && o.createdAt.month == now.month).toList();
    }

    if (startDate != null && endDate != null) {
      filtered = filtered.where((o) =>
      o.createdAt.isAfter(startDate!.subtract(const Duration(days: 1))) &&
          o.createdAt.isBefore(endDate!.add(const Duration(days: 1)))).toList();
    }

    if (selectedStatus != null && selectedStatus != 'all') {
      filtered = filtered.where((o) => o.status == selectedStatus).toList();
    }

    return filtered;
  }

  List<Order> _getPagedOrders(List<Order> orders) {
    final start = (_currentPage - 1) * _itemsPerPage;
    return orders.skip(start).take(_itemsPerPage).toList();
  }

  int _getTotalPages(List<Order> orders) =>
      (orders.length / _itemsPerPage).ceil();

  void _changeFilter(String value) {
    setState(() {
      selectedFilter = value;
      startDate = null;
      endDate = null;
      _currentPage = 1;
    });
    _saveFilters();
    _refreshOrders();
  }

  void _onStatusChanged(String? value) {
    setState(() {
      selectedStatus = value;
      _currentPage = 1;
    });
    _saveFilters();
    _refreshOrders();
  }

  void _onDateRangePicked(DateTimeRange? range) {
    if (range != null) {
      setState(() {
        startDate = range.start;
        endDate = range.end;
        selectedFilter = 'custom';
        _currentPage = 1;
      });
      _saveFilters();
      _refreshOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          context.go('/manager');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Quản lý đơn hàng", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.go('/manager'),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh, color: Colors.black), onPressed: _refreshOrders),
            DropdownButton<String>(
              value: selectedStatus ?? 'all',
              underline: Container(),
              onChanged: _onStatusChanged,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
                DropdownMenuItem(value: 'pending', child: Text('Chờ xử lý')),
                DropdownMenuItem(value: 'in progress', child: Text('Đang xử lý')),
                DropdownMenuItem(value: 'delivered', child: Text('Đã giao')),
                DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month, color: Colors.black),
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                _onDateRangePicked(range);
              },
              tooltip: 'Chọn khoảng thời gian',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list, color: Colors.black),
              onSelected: _changeFilter,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'all', child: Text("Tất cả")),
                PopupMenuItem(value: 'today', child: Text("Hôm nay")),
                PopupMenuItem(value: 'week', child: Text("Tuần này")),
                PopupMenuItem(value: 'month', child: Text("Tháng này")),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade100,
        body: Stack(
          children: [
            FutureBuilder<List<Order>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi: ${snapshot.error}"));
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const Center(child: Text("Không có đơn hàng."));
                }
                final pagedOrders = _getPagedOrders(orders);
                final totalPages = _getTotalPages(orders);
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: pagedOrders.length,
                        itemBuilder: (context, index) {
                          final order = pagedOrders[index];
                          return GestureDetector(
                            onTap: () {
                              if (order.id != null) {
                                context.push(
                                  '/manager/orders/${order.id}',
                                  extra: order,
                                );
                              }
                            },
                            child: _OrderCard(order: order),
                          );
                        },
                      ),
                    ),
                    _buildPaginationBar(totalPages),
                  ],
                );
              },
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
        bottomNavigationBar: isMobile
            ? MobileNavigationBar(
          selectedIndex: 0,
          onItemTapped: (_) {},
          isLoggedIn: true,
          role: 'admin',
        )
            : null,
      ),
    );
  }

  Widget _buildPaginationBar(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          ),
          Text("Trang $_currentPage / $totalPages"),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.blue;
      case 'in progress':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipping = order.shippingAddress;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(order.status, style: TextStyle(color: getStatusColor(order.status), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow("Người nhận", shipping.receiverName),
          _infoRow("SĐT", shipping.phoneNumber),
          _infoRow("Địa chỉ", "${shipping.addressLine}, ${shipping.ward}, ${shipping.district}, ${shipping.city}"),
          _infoRow("Ngày tạo", DateFormat('dd/MM/yyyy – HH:mm').format(order.createdAt)),
          _infoRow("Tổng tiền", "${order.totalAmount.toStringAsFixed(0)} ₫"),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Flexible(child: Text(value)),
      ],
    ),
  );
}
