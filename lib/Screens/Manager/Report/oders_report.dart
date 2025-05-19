import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Service/order_service.dart';
import '../../../models/Order.dart';
import '../../../widgets/Footer/mobile_navigation_bar.dart';

class OrdersReport extends StatelessWidget {
  const OrdersReport({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveOrdersScreen();
  }
}

class ResponsiveOrdersScreen extends StatelessWidget {
  const ResponsiveOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        return OrdersScreen(isMobile: isMobile);
      },
    );
  }
}

class OrdersScreen extends StatefulWidget {
  final bool isMobile;
  const OrdersScreen({super.key, required this.isMobile});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  int selectedTab = 2; // Tháng
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Future<List<Order>> _ordersFuture;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
    _checkLoginStatus();
    _loadTab();
    _refreshOrders();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    if (token == null || role != 'admin') {
      context.go('/login');
    }
  }

  Future<void> _loadTab() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedTab = prefs.getInt('orders_report_tab') ?? 2;
    });
  }

  Future<void> _saveTab() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('orders_report_tab', selectedTab);
  }

  void _refreshOrders() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _ordersFuture = OrderService.fetchAllOrders().then((orders) => _applyFilters(orders));
    });
  }

  List<Order> _applyFilters(List<Order> orders) {
    final now = DateTime.now();
    if (selectedTab == 0) {
      // Ngày
      return orders.where((o) => o.createdAt.day == now.day && o.createdAt.month == now.month && o.createdAt.year == now.year).toList();
    } else if (selectedTab == 1) {
      // Tuần
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return orders.where((o) => o.createdAt.isAfter(startOfWeek)).toList();
    }
    // Tháng
    return orders.where((o) => o.createdAt.month == now.month && o.createdAt.year == now.year).toList();
  }

  Widget _buildTabButton(String text, int index) {
    bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
          _controller.forward(from: 0);
        });
        _saveTab();
        _refreshOrders();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.purple : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildChart(List<Order> orders) {
    // Tính số đơn hàng theo ngày/tuần/tháng
    final spots = List.generate(4, (index) {
      final count = orders.where((o) => o.createdAt.day <= (index + 1) * (selectedTab == 0 ? 1 : selectedTab == 1 ? 2 : 10)).length.toDouble();
      return FlSpot((index + 1).toDouble(), count);
    });
    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, horizontalInterval: 1, verticalInterval: 1),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (value, meta) => Text('Đơn: ${value.toInt()}')),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (value, meta) => Text(selectedTab == 0 ? 'Giờ' : selectedTab == 1 ? 'Ngày' : 'Tuần')),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey, width: 1)),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    Color statusColor;
    switch (order.status.toLowerCase()) {
      case 'in progress':
        statusColor = Colors.purpleAccent;
        break;
      case 'delivered':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }
    return GestureDetector(
      onTap: () {
        if (order.id != null) {
          context.push('/manager/orders/${order.id}', extra: order);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đơn hàng không hợp lệ')));
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(order.status, style: TextStyle(color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text("Người dùng: ${order.shippingAddress.receiverName}", style: const TextStyle(color: Colors.grey)),
              Text("Tổng tiền: ${order.totalAmount.toStringAsFixed(0)} ₫", style: const TextStyle(color: Colors.grey)),
              Text("Địa chỉ: ${order.shippingAddress.addressLine}, ${order.shippingAddress.city}", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text("Ngày: ${DateFormat('dd/MM/yyyy').format(order.createdAt)}", style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(List<Order> orders) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTabButton("Ngày", 0),
              _buildTabButton("Tuần", 1),
              _buildTabButton("Tháng", 2),
            ],
          ),
          const SizedBox(height: 20),
          _buildChart(orders),
          const SizedBox(height: 20),
          const Text("Danh sách Đơn hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (orders.isEmpty) const Text("Không có đơn hàng"),
          ...orders.take(5).map((order) => _buildOrderCard(order)),
        ],
      ),
    );
  }

  Widget _buildWebLayout(List<Order> orders) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                _buildTabButton("Ngày", 0),
                const SizedBox(width: 12),
                _buildTabButton("Tuần", 1),
                const SizedBox(width: 12),
                _buildTabButton("Tháng", 2),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildChart(orders)),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      const Text("Danh sách Đơn hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      if (orders.isEmpty) const Text("Không có đơn hàng"),
                      ...orders.take(5).map((order) => _buildOrderCard(order)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          context.go('/manager');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Báo cáo Đơn hàng", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.go('/manager'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _refreshOrders,
            ),
          ],
        ),
        body: Stack(
          children: [
            FutureBuilder<List<Order>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Lỗi: ${snapshot.error}"),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshOrders,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                final orders = snapshot.data ?? [];
                return widget.isMobile ? _buildMobileLayout(orders) : _buildWebLayout(orders);
              },
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
        bottomNavigationBar: widget.isMobile
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
}