import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Service/order_service.dart';
import '../../../models/Order.dart';
import '../../../widgets/Footer/mobile_navigation_bar.dart';

class RevenueReport extends StatelessWidget {
  const RevenueReport({super.key});

  @override
  Widget build(BuildContext context) {
    return const RevenueScreen();
  }
}

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> with SingleTickerProviderStateMixin {
  int selectedTab = 2; // Tháng
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Future<List<Order>> _ordersFuture;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
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
      selectedTab = prefs.getInt('revenue_report_tab') ?? 2;
    });
  }

  Future<void> _saveTab() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('revenue_report_tab', selectedTab);
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

  Widget _buildFilterButtons(bool isMobile) {
    List<String> labels = ['Ngày', 'Tuần', 'Tháng'];
    return Row(
      mainAxisAlignment: isMobile ? MainAxisAlignment.spaceAround : MainAxisAlignment.start,
      children: List.generate(
        labels.length,
            (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(labels[index]),
            selected: selectedTab == index,
            onSelected: (_) {
              setState(() => selectedTab = index);
              _saveTab();
              _refreshOrders();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueChart(List<Order> orders, bool isMobile) {
    final height = isMobile ? 220.0 : 160.0;
    final aspectRatio = isMobile ? 1.6 : 2.5;
    // Tính doanh thu theo ngày/tuần/tháng
    final spots = List.generate(4, (index) {
      final revenue = orders
          .where((o) => o.createdAt.day <= (index + 1) * (selectedTab == 0 ? 1 : selectedTab == 1 ? 2 : 10))
          .fold(0.0, (sum, o) => sum + o.totalAmount);
      return FlSpot((index + 1).toDouble(), revenue / 1000); // Chia 1000 để dễ đọc
    });
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SizedBox(
          height: height,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey, strokeWidth: 0.5),
                  getDrawingVerticalLine: (value) => FlLine(color: Colors.grey, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (value, meta) => Text('${value.toInt()}K ₫')),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value >= 1 && value <= 4) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                            child: Text(selectedTab == 0 ? 'Giờ' : selectedTab == 1 ? 'Ngày' : 'Tuần'),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.black, width: 1)),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.redAccent,
                    barWidth: 3,
                    belowBarData: BarAreaData(show: true, color: Colors.redAccent.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeList(List<Order> orders) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
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
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.receipt, color: Colors.black45),
              ),
              title: Text(
                order.orderNumber,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Khách hàng: ${order.shippingAddress.receiverName}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} ₫',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    order.status,
                    style: TextStyle(
                      color: order.status == 'delivered' ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Scaffold(
            appBar: AppBar(
              leading: isMobile
                  ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => context.go('/manager'),
              )
                  : null,
              title: const Text('Báo cáo Doanh thu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              centerTitle: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 1,
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
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilterButtons(isMobile),
                            const SizedBox(height: 10),
                            _buildRevenueChart(orders, isMobile),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Thu vào',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            _buildIncomeList(orders),
                          ],
                        ),
                      ),
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
          );
        },
      ),
    );
  }
}