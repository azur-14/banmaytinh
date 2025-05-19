import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Service/user_service.dart';
import '../../../Service/order_service.dart';
import '../../../Service/product_service.dart';
import '../../../models/Order.dart';
import '../../../models/User.dart';
import '../../../models/Category.dart';

enum IntervalType { yearly, quarterly, monthly, weekly, custom }

class WebDashboard extends StatefulWidget {
  const WebDashboard({Key? key}) : super(key: key);

  @override
  State<WebDashboard> createState() => _WebDashboardState();
}

class _WebDashboardState extends State<WebDashboard> with SingleTickerProviderStateMixin {
  bool _isAdmin = false;
  int _selectedDrawerIndex = 0;

  // dữ liệu
  List<User> _allUsers = [];
  List<Order> _allOrders = [];
  Map<String, String> _productCategory = {};

  // stats
  int _userCount = 0;
  int _newUserCount = 0;
  int _orderCount = 0;
  double _totalRevenue = 0;

  bool _loading = true;
  String? _error;

  // filter chung cho advanced
  IntervalType _ordersInterval = IntervalType.yearly;
  IntervalType _revenueInterval = IntervalType.yearly;
  IntervalType _regInterval = IntervalType.yearly;
  DateTime? _customStart;
  DateTime? _customEnd;
  late final AnimationController _opacityController;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _opacityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _opacityAnimation = CurvedAnimation(
      parent: _opacityController,
      curve: Curves.easeInOut,
    );

    _opacityController.forward();

    _checkAuth();
    _loadStats();
  }

  @override
  void dispose() {
    _opacityController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    if (token == null || role != 'admin') {
      context.go('/login');
    } else {
      setState(() => _isAdmin = true);
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await UserService().fetchUsers();
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(days: 30));
      final orders = await OrderService.fetchAllOrders();
      final revenue = orders.fold<double>(0, (sum, o) => sum + (o.totalAmount ?? 0));

      final productIds = orders.expand((o) => o.items.map((i) => i.productId)).toSet().toList();
      final products = await Future.wait(productIds.map((id) => ProductService.getById(id)));
      final categories = await ProductService.fetchAllCategories();
      final lookup = { for (var p in products)
        p.id: categories.firstWhere(
                (c) => c.id == p.categoryId,
            orElse: () => Category(id: p.categoryId, name: 'Unknown', createdAt: now)
        ).name
      };

      setState(() {
        _allUsers = users;
        _userCount = users.length;
        _newUserCount = users.where((u) => u.createdAt.isAfter(cutoff)).length;
        _allOrders = orders;
        _orderCount = orders.length;
        _totalRevenue = revenue;
        _productCategory = lookup;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) return const Scaffold(body: SizedBox.shrink());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển', style: TextStyle(color: Color(0xFF171F32), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE2EEFE), Color(0xFFE2EEFE)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1)))
          : (_error != null
          ? Center(child: Text('Error: $_error', style: TextStyle(color: Color(0xFF0D47A1), fontSize: 16)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Overview ---
            _sectionTitle('Overview'),
            _buildStatCards(),
            const SizedBox(height: 24),
            _buildChartsGrid(),

            // --- Advanced ---
            const Divider(height: 40, color: Color(0xFF0288D1), thickness: 1),
            _sectionTitle('Advanced Filters & Charts'),
            _buildAdvancedCharts(),
            const SizedBox(height: 24),
            _buildManagementLinks(context),
          ],
        ),
      )),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE2EEFE), Color(0xFFE2EEFE)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Text('Menu Quản trị viên', style: TextStyle(color: Color(0xFF171F32), fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            _drawerItem(context, 'Trang chủ', Icons.dashboard, '/manager/dashboard', Color(0xFF0D47A1)),
            _drawerItem(context, 'Quản lý Sản phẩm', Icons.shopping_cart, '/manager/products', Color(0xFF0D47A1)),
            _drawerItem(context, 'Quản lý Mã giảm giá', Icons.card_giftcard, '/manager/coupons', Color(0xFF0D47A1)),
            _drawerItem(context, 'Quản lý Danh mục', Icons.category, '/manager/categories', Color(0xFF0D47A1)),
            _drawerItem(context, 'Quản lý Người dùng', Icons.people, '/manager/users', Color(0xFF0D47A1)),
            _drawerItem(context, 'Quản lý Đơn hàng', Icons.receipt, '/manager/orders', Color(0xFF0D47A1)),
            _drawerItem(context, 'Hỗ trợ người dùng', Icons.support, '/manager/support', Color(0xFF0D47A1)),
            const Divider(color: Colors.white54),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF171F32)),
              title: const Text('Đăng xuất', style: TextStyle(color: Color(0xFF171F32))),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pop(context);
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, String title, IconData icon, String? path, Color iconColor) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: iconColor)),
      onTap: () {
        Navigator.pop(context);
        if (path != null) {
          context.go(path);
        }
      },
      hoverColor: Color(0xFFBBDEFB).withOpacity(0.3),
    );
  }

  Widget _buildStatCards() {
    final stats = [
      {'title': 'Người dùng', 'value': '$_userCount', 'icon': Icons.people},
      {'title': 'Người dùng mới (30d)', 'value': '$_newUserCount', 'icon': Icons.person_add},
      {'title': 'Đơn đặt hàng', 'value': '$_orderCount', 'icon': Icons.shopping_cart},
      {'title': 'Doanh thu', 'value': '₫${_totalRevenue.toStringAsFixed(0)}', 'icon': Icons.attach_money},
    ];
    return LayoutBuilder(builder: (ctx, cons) {
      final itemW = (cons.maxWidth - 48) / 4;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats.map((s) {
          return SizedBox(
            width: itemW,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(s['icon'] as IconData, size: 32, color: Color(0xFF0D47A1)),
                    const SizedBox(height: 8),
                    Text(s['title'] as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0D47A1))),
                    const SizedBox(height: 4),
                    Text(s['value'] as String, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0288D1))),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildChartsGrid() {
    final ordersByMonth = _aggOrdersByMonth();
    final revenueByMonth = _aggRevenueByMonth();
    final catShares = _aggCategoryShares();
    final top5Cats = catShares.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return LayoutBuilder(builder: (ctx, cons) {
      final cross = cons.maxWidth > 1200 ? 3 : (cons.maxWidth > 800 ? 2 : 1);
      return GridView.count(
        crossAxisCount: cross,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
        children: [
          _chartCard(
            title: 'Đơn đặt hàng (12m)',
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (x, _) {
                      final key = ordersByMonth.keys.elementAt(x.toInt().clamp(0, ordersByMonth.length - 1));
                      return Text(key, style: TextStyle(fontSize: 10, color: Color(0xFF0D47A1)));
                    },
                  )),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(ordersByMonth.length,
                            (i) => FlSpot(i.toDouble(), ordersByMonth.values.elementAt(i))),
                    isCurved: true,
                    color: Color(0xFF0288D1),
                    barWidth: 2,
                  )
                ],
                gridData: FlGridData(show: true, drawVerticalLine: true, getDrawingHorizontalLine: (value) => FlLine(color: Color(0xFFBBDEFB).withOpacity(0.5))),
              ),
            ),
          ),
          _chartCard(
            title: 'Doanh thu (12m)',
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (x, _) {
                      final key = revenueByMonth.keys.elementAt(x.toInt().clamp(0, revenueByMonth.length - 1));
                      return Text(key, style: TextStyle(fontSize: 10, color: Color(0xFF0D47A1)));
                    },
                  )),
                ),
                barGroups: List.generate(revenueByMonth.length, (i) => BarChartGroupData(x: i, barRods: [
                  BarChartRodData(toY: revenueByMonth.values.elementAt(i), color: Color(0xFF0288D1), width: 8)
                ])),
                gridData: FlGridData(show: true, drawVerticalLine: true, getDrawingHorizontalLine: (value) => FlLine(color: Color(0xFFBBDEFB).withOpacity(0.5))),
              ),
            ),
          ),
          _chartCard(
            title: 'Tỉ lệ loại sản phẩm',
            child: PieChart(PieChartData(
              sections: catShares.entries.map((e) => PieChartSectionData(
                value: e.value.toDouble(),
                title: e.key,
                radius: 40,
                color: Colors.primaries[catShares.keys.toList().indexOf(e.key) % Colors.primaries.length].withOpacity(0.8),
                titleStyle: TextStyle(fontSize: 12, color: Color(0xFF0D47A1)),
              )).toList(),
              centerSpaceRadius: 40,
            )),
          ),
          _chartCard(
            title: '5 danh mục hàng đầu',
            child: BarChart(BarChartData(
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (x, _) {
                    final key = top5Cats[x.toInt().clamp(0, top5Cats.length - 1)].key;
                    return Text(key, style: TextStyle(fontSize: 10, color: Color(0xFF0D47A1)));
                  },
                )),
              ),
              barGroups: List.generate(top5Cats.length, (i) => BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: top5Cats[i].value.toDouble(), color: Color(0xFF0288D1), width: 8)
              ])),
              gridData: FlGridData(show: true, drawVerticalLine: true, getDrawingHorizontalLine: (value) => FlLine(color: Color(0xFFBBDEFB).withOpacity(0.5))),
            )),
          ),
        ],
      );
    });
  }

  Widget _buildAdvancedCharts() {
    return Column(
      children: [
        _filterableChart(
          title: 'Số đơn hàng trong thời gian',
          dropdownValue: _ordersInterval,
          onIntervalChanged: (v) {
            if (v != null) setState(() => _ordersInterval = v);
          },
          chart: LineChart(LineChartData(
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (x, _) {
                  final map = _aggByInterval(_ordersInterval, onlyRevenue: false);
                  final key = map.keys.elementAt(x.toInt().clamp(0, map.length - 1));
                  return Text(key, style: TextStyle(fontSize: 10, color: Color(0xFF0D47A1)));
                },
              )),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                    _aggByInterval(_ordersInterval, onlyRevenue: false).length,
                        (i) => FlSpot(i.toDouble(),
                        _aggByInterval(_ordersInterval, onlyRevenue: false).values.elementAt(i))),
                isCurved: true,
                color: Color(0xFF0288D1),
                barWidth: 2,
              )
            ],
            gridData: FlGridData(show: true, drawVerticalLine: true, getDrawingHorizontalLine: (value) => FlLine(color: Color(0xFFBBDEFB).withOpacity(0.5))),
          )),
        ),
        const SizedBox(height: 16),
        _filterableChart(
          title: 'Doanh thu và lợi nhuận',
          dropdownValue: _revenueInterval,
          onIntervalChanged: (v) {
            if (v != null) setState(() => _revenueInterval = v);
          },
          chart: BarChart(BarChartData(
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (x, _) {
                  final map = _aggregateRevenueByInterval(_revenueInterval);
                  final key = map.keys.elementAt(x.toInt().clamp(0, map.length - 1));
                  return Text(key, style: TextStyle(fontSize: 10, color: Color(0xFF0D47A1)));
                },
              )),
            ),
            barGroups: List.generate(
              _aggregateRevenueByInterval(_revenueInterval).length,
                  (i) {
                final key = _aggregateRevenueByInterval(_revenueInterval).keys.elementAt(i);
                final rev = _aggregateRevenueByInterval(_revenueInterval)[key]!;
                final prof = rev * 0.2;
                return BarChartGroupData(x: i, barsSpace: 4, barRods: [
                  BarChartRodData(toY: rev, width: 8, color: Color(0xFF0288D1)),
                  BarChartRodData(toY: prof, width: 8, color: Color(0xFF0D47A1)),
                ]);
              },
            ),
            gridData: FlGridData(show: true, drawVerticalLine: true, getDrawingHorizontalLine: (value) => FlLine(color: Color(0xFFBBDEFB).withOpacity(0.5))),
          )),
        ),
        const SizedBox(height: 16),
        _filterableChart(
          title: 'Lượng người dùng đăng ký',
          dropdownValue: _regInterval,
          onIntervalChanged: (v) {
            if (v != null) setState(() => _regInterval = v);
          },
          chart: LineChart(LineChartData(
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (x, _) {
                  final map = _aggRegistrationsByInterval(_regInterval);
                  final key = map.keys.elementAt(x.toInt().clamp(0, map.length - 1));
                  return Text(key, style: TextStyle(fontSize: 10, color: Color(0xFF0D47A1)));
                },
              )),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                    _aggRegistrationsByInterval(_regInterval).length,
                        (i) => FlSpot(i.toDouble(),
                        _aggRegistrationsByInterval(_regInterval).values.elementAt(i))),
                isCurved: true,
                color: Color(0xFF0288D1),
                barWidth: 2,
              )
            ],
            gridData: FlGridData(show: true, drawVerticalLine: true, getDrawingHorizontalLine: (value) => FlLine(color: Color(0xFFBBDEFB).withOpacity(0.5))),
          )),
        ),
      ],
    );
  }

  Widget _filterableChart({
    required String title,
    required IntervalType dropdownValue,
    required ValueChanged<IntervalType?> onIntervalChanged,
    required Widget chart,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0D47A1))),
                const Spacer(),
                DropdownButton<IntervalType>(
                  value: dropdownValue,
                  dropdownColor: Color(0xFFBBDEFB),
                  style: TextStyle(color: Color(0xFF0D47A1)),
                  underline: Container(height: 1, color: Color(0xFF0288D1)),
                  items: IntervalType.values.map((i) {
                    return DropdownMenuItem(
                      value: i,
                      child: Text(i.toString().split('.').last, style: TextStyle(color: Color(0xFF0D47A1))),
                    );
                  }).toList(),
                  onChanged: onIntervalChanged,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String txt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(txt, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
    );
  }

  Map<String, double> _aggOrdersByMonth() {
    final now = DateTime.now();
    final m = <String, double>{};
    for (int i = 11; i >= 0; i--) {
      final dt = DateTime(now.year, now.month - i);
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      m[key] = 0;
    }
    for (var o in _allOrders) {
      final key = '${o.createdAt.year}-${o.createdAt.month.toString().padLeft(2, '0')}';
      if (m.containsKey(key)) m[key] = m[key]! + 1;
    }
    return m;
  }

  Map<String, double> _aggRevenueByMonth() {
    final now = DateTime.now();
    final m = <String, double>{};
    for (int i = 11; i >= 0; i--) {
      final dt = DateTime(now.year, now.month - i);
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      m[key] = 0;
    }
    for (var o in _allOrders) {
      final key = '${o.createdAt.year}-${o.createdAt.month.toString().padLeft(2, '0')}';
      if (m.containsKey(key)) m[key] = m[key]! + (o.totalAmount ?? 0);
    }
    return m;
  }

  Map<String, int> _aggCategoryShares() {
    final cnt = <String, int>{};
    for (var o in _allOrders) {
      for (var i in o.items) {
        final cat = _productCategory[i.productId] ?? 'Unknown';
        cnt[cat] = (cnt[cat] ?? 0) + i.quantity;
      }
    }
    return cnt;
  }

  Map<String, double> _aggByInterval(IntervalType t, {required bool onlyRevenue}) {
    final out = <String, double>{};
    for (var o in _allOrders) {
      final dt = o.createdAt;
      String key;
      switch (t) {
        case IntervalType.yearly:
          key = '${dt.year}';
          break;
        case IntervalType.quarterly:
          final q = ((dt.month - 1) ~/ 3) + 1;
          key = '${dt.year}-Q$q';
          break;
        case IntervalType.monthly:
          key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          break;
        case IntervalType.weekly:
          final w = ((dt.day - 1) ~/ 7) + 1;
          key = '${dt.year}-W$w';
          break;
        case IntervalType.custom:
          key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          break;
      }
      final value = onlyRevenue ? (o.totalAmount ?? 0) : 1;
      out[key] = (out[key] ?? 0) + value;
    }
    return out;
  }

  Map<String, double> _aggregateRevenueByInterval(IntervalType t) {
    final map = _aggByInterval(t, onlyRevenue: true);
    return map;
  }

  Map<String, double> _aggRegistrationsByInterval(IntervalType t) {
    final now = DateTime.now();
    final out = <String, double>{};
    // Initialize keys based on interval type (last 12 months for monthly, adjust for others as needed)
    if (t == IntervalType.monthly) {
      for (int i = 11; i >= 0; i--) {
        final dt = DateTime(now.year, now.month - i);
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        out[key] = 0;
      }
    }
    // For other intervals, keys will be generated dynamically
    for (var u in _allUsers) {
      final dt = u.createdAt;
      String key;
      switch (t) {
        case IntervalType.yearly:
          key = '${dt.year}';
          break;
        case IntervalType.quarterly:
          final q = ((dt.month - 1) ~/ 3) + 1;
          key = '${dt.year}-Q$q';
          break;
        case IntervalType.monthly:
          key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          break;
        case IntervalType.weekly:
          final w = ((dt.day - 1) ~/ 7) + 1;
          key = '${dt.year}-W$w';
          break;
        case IntervalType.custom:
          key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          break;
      }
      out[key] = (out[key] ?? 0) + 1;
    }
    return out;
  }

  Widget _chartCard({required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0D47A1))),
            const SizedBox(height: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementLinks(BuildContext context) {
    List<Map<String, dynamic>> managements = [
      {"title": "Quản lý Sản phẩm", "path": "/manager/products"},
      {"title": "Quản lý Mã giảm giá", "path": "/manager/coupons"},
      {"title": "Quản lý Danh mục", "path": "/manager/categories"},
      {"title": "Quản lý Người dùng", "path": "/manager/users"},
      {"title": "Quản lý Đơn hàng", "path": "/manager/orders"},
      {"title": "Hỗ trợ người dùng", "path": "/manager/support"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Lối tắt", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
        const SizedBox(height: 12),
        ...managements.map((item) {
          return AnimatedBuilder(
            animation: _opacityAnimation,
            builder: (context, _) => Opacity(
              opacity: _opacityAnimation.value,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(item["title"], style: TextStyle(fontSize: 16, color: Color(0xFF0D47A1))),
                    trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF0288D1), size: 18),
                    onTap: () {
                      context.go(item["path"]);
                    },
                    hoverColor: Color(0xFFBBDEFB).withOpacity(0.3),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}