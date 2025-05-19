// lib/Screens/Manager/MobileDashboard.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../models/User.dart';
import '../../../widgets/Footer/mobile_navigation_bar.dart';
import '../../../Service/user_service.dart';
import '../../../Service/order_service.dart';
import '../../../models/Order.dart';
import '../../../models/OrderItem.dart';
import '../../../Service/product_service.dart';
import '../../../models/Category.dart';

enum IntervalType { yearly, quarterly, monthly, weekly, custom }

class MobileDashboard extends StatefulWidget {
  const MobileDashboard({Key? key}) : super(key: key);

  @override
  State<MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends State<MobileDashboard>
    with TickerProviderStateMixin {
  // --- Nav & Auth ---
  int _currentIndex = 0;
  bool _isLoggedIn = false;

  // --- View Tabs ---
  late final TabController _viewTabController;

  // --- Simple stats ---
  int    _userCount    = 0;
  int    _newUserCount = 0;
  int    _orderCount   = 0;
  double _totalRevenue = 0;

  // --- Advanced filters ---
  IntervalType _interval    = IntervalType.yearly;
  DateTime?    _customStart;
  DateTime?    _customEnd;
// Thêm ở trên cùng của _MobileDashboardState:
  List<User> _allUsers = [];

  // --- Raw data ---
  List<Order> _allOrders = [];

  bool   _loading    = true;
  String? _errorText;
  Map<String, String> _productCategory = {};

  @override
  void initState() {
    super.initState();
    _viewTabController = TabController(length: 2, vsync: this);
    _checkLogin();
    _loadNavIndex();
    _loadStats();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      context.go('/login');
      return;
    }
    setState(() => _isLoggedIn = true);
  }

  Future<void> _loadNavIndex() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _currentIndex = prefs.getInt('nav_index') ?? 0);
  }

  Future<void> _saveNavIndex(int idx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('nav_index', idx);
  }

  void _onNavTapped(int idx) {
    setState(() => _currentIndex = idx);
    _saveNavIndex(idx);
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading   = true;
      _errorText = null;
    });
    try {
      // 1. Fetch users and orders
      // 1. Fetch users and orders
      final users  = await UserService().fetchUsers();
      final now    = DateTime.now();
      final cutoff = now.subtract(const Duration(days: 30));

      final orders  = await OrderService.fetchAllOrders();
      final revenue = orders.fold<double>(0, (sum, o) => sum + (o.totalAmount ?? 0));
      // 2. Build list of distinct productIds in all orders
      final productIds = orders
          .expand((o) => o.items.map((i) => i.productId))
          .toSet()
          .toList();

      // 3. Fetch each product and *all* categories
      final products   = await Future.wait(productIds.map((id) => ProductService.getById(id)));
      final categories = await ProductService.fetchAllCategories();

      // 4. Build productId → categoryName lookup
      _productCategory = {
        for (final p in products)
          p.id: categories
              .firstWhere((c) => c.id == p.categoryId,
              orElse: () => Category(
                  id: p.categoryId,
                  name: 'Unknown',
                  createdAt: DateTime.now()))
              .name
      };

      // 5. Finally, update your state
      setState(() {
        _allUsers      = users;
        _userCount    = users.length;
        _newUserCount = users.where((u) => u.createdAt.isAfter(cutoff)).length;
        _allOrders    = orders;
        _orderCount   = orders.length;
        _totalRevenue = revenue;
        _loading      = false;
      });
    } catch (e) {
      setState(() {
        _errorText = e.toString();
        _loading   = false;
      });
    }
  }
  /// Gộp số user đăng ký theo interval
  Map<String,double> _aggregateUserRegistrationsByInterval(
      IntervalType t,
      DateTime? start,
      DateTime? end,
      ) {
    final out = <String,double>{};
    for (var u in _allUsers) {
      if (start != null && u.createdAt.isBefore(start)) continue;
      if (end   != null && u.createdAt.isAfter(end))   continue;
      final dt = u.createdAt;
      late String key;
      switch (t) {
        case IntervalType.yearly:
          key = '${dt.year}'; break;
        case IntervalType.quarterly:
          final q = ((dt.month - 1) ~/ 3) + 1;
          key = '${dt.year}-Q$q'; break;
        case IntervalType.monthly:
          key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}'; break;
        case IntervalType.weekly:
          final w = ((dt.day - 1) ~/ 7) + 1;
          key = '${dt.year}-W$w'; break;
        case IntervalType.custom:
          key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
          break;
      }
      out[key] = (out[key] ?? 0) + 1;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        bottom: TabBar(
          controller: _viewTabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Advanced'),
          ],
        ),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: _buildDrawer(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_errorText != null
          ? Center(child: Text('Lỗi: $_errorText', style: const TextStyle(color: Colors.red)))
          : TabBarView(
        controller: _viewTabController,
        children: [
          _buildOverview(),
          _buildAdvanced(),
        ],
      )),
      bottomNavigationBar: MobileNavigationBar(
        selectedIndex: _currentIndex,
        onItemTapped: _onNavTapped,
        isLoggedIn: _isLoggedIn,
        role: 'admin',
      ),
    );
  }

  /// --- Overview Tab ---
  Widget _buildOverview() {
    // 1) Top 5 bestselling products for pie chart
    final Map<String,int> productCounts = {};
    for (var o in _allOrders) {
      for (var item in o.items) {
        productCounts[item.productName] = (productCounts[item.productName] ?? 0) + item.quantity;
      }
    }

    // 2) Quantity sold by category via lookup map
    final Map<String,int> categoryCounts = {};
    for (var o in _allOrders) {
      for (var item in o.items) {
        final cat = _productCategory[item.productId] ?? 'Unknown';
        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + item.quantity;
      }
    }

    // 3) Pie sections for all categories
    final pieSectionsCat = categoryCounts.entries.map((e) {
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: e.key,
        radius: 40,
        titleStyle: const TextStyle(fontSize: 10),
      );
    }).toList();

    // 4) Top-5 categories bar data
    final topCats = categoryCounts.entries.toList()
      ..sort((a,b)=>b.value.compareTo(a.value));
    final barDataCats = Map<String,double>.fromEntries(
        topCats.take(5).map((e) => MapEntry(e.key, e.value.toDouble()))
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12, runSpacing: 12,
          children: [
            _statCard('Users',     _userCount.toString(),      Icons.people),
            _statCard('New Users', _newUserCount.toString(),   Icons.person_add),
            _statCard('Orders',    _orderCount.toString(),     Icons.shopping_cart),
            _statCard('Revenue',   '₫${_totalRevenue.toStringAsFixed(0)}', Icons.attach_money),
          ],
        ),
        const SizedBox(height: 24),

        const Text('Purchase share by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sections: pieSectionsCat,
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),

        _sectionTitle('Orders (last 12 months)'),
        SizedBox(
          height: 200,
          child: _buildLineChart(
            data: _aggOrdersByMonth(),
          ),
        ),
        const SizedBox(height: 16),

        _sectionTitle('Revenue (last 12 months)'),
        SizedBox(
          height: 200,
          child: _buildBarChart(
            data: _aggRevenueByMonth(),
          ),
        ),
        const SizedBox(height: 24),

        const Text('Top 5 Categories by Units Sold', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(
          height: 200,
          child: _buildBarChart(
            data: barDataCats,
          ),
        ),

        const SizedBox(height: 24),

        const Text('Top 5 Products by Units Sold', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(
          height: 200,
          child: _buildBarChart(data: barDataCats),
        ),
      ],
    );
  }


  /// --- Advanced Tab ---
  Widget _buildAdvanced() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Interval selector
          Row(
            children: [
              DropdownButton<IntervalType>(
                value: _interval,
                items: IntervalType.values.map((i) {
                  return DropdownMenuItem(
                    value: i,
                    child: Text(i.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _interval = v!),
              ),
              const SizedBox(width: 16),
              if (_interval == IntervalType.custom) ...[
                TextButton(
                  onPressed: () => _pickDate(isStart: true),
                  child: Text(_customStart == null
                      ? 'Start date'
                      : '${_customStart!.toLocal()}'.split(' ')[0]),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _pickDate(isStart: false),
                  child: Text(_customEnd == null
                      ? 'End date'
                      : '${_customEnd!.toLocal()}'.split(' ')[0]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          _sectionTitle('Orders over interval'),
          Expanded(
            child: _buildLineChart(
              data: _aggByInterval(_interval, onlyRevenue: false),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('User Registrations over interval'),
          Expanded(
            child: _buildLineChart(
              data: _aggregateUserRegistrationsByInterval(
                _interval,
                _customStart,
                _customEnd,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Revenue vs Profit'),
          SizedBox(
            height: 200,
            child: _buildBarChartComparative(
              series: {
                'Revenue': _aggregateRevenueByInterval(
                  _allOrders,
                  _interval,
                  _customStart,
                  _customEnd,
                ),
                'Profit': _aggregateProfitByInterval(
                  _allOrders,
                  _interval,
                  _customStart,
                  _customEnd,
                ),
              },
            ),
          ),


        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _customStart = picked;
        else         _customEnd   = picked;
      });
    }
  }
  /// Group total revenue by the chosen interval (yearly, quarterly, etc.)
  Map<String,double> _aggregateRevenueByInterval(
      List<Order> orders,
      IntervalType interval,
      DateTime? start,
      DateTime? end,
      ) {
    final out = <String,double>{};
    for (var o in orders) {
      if (start != null && o.createdAt.isBefore(start)) continue;
      if (end   != null && o.createdAt.isAfter(end))   continue;
      late String key;
      final dt = o.createdAt;
      switch (interval) {
        case IntervalType.yearly:
          key = '${dt.year}';
          break;
        case IntervalType.quarterly:
          final q = ((dt.month - 1) ~/ 3) + 1;
          key = '${dt.year}-Q$q';
          break;
        case IntervalType.monthly:
          key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}';
          break;
        case IntervalType.weekly:
          final week = ((dt.day - 1) ~/ 7) + 1;
          key = '${dt.year}-W$week';
          break;
        case IntervalType.custom:
          key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
          break;
      }
      out[key] = (out[key] ?? 0) + (o.totalAmount ?? 0);
    }
    return out;
  }

  /// Example profit aggregation: simply 20% of revenue
  Map<String,double> _aggregateProfitByInterval(
      List<Order> orders,
      IntervalType interval,
      DateTime? start,
      DateTime? end,
      ) {
    final revenueMap = _aggregateRevenueByInterval(orders, interval, start, end);
    return revenueMap.map((k, v) => MapEntry(k, v * 0.2));
  }

  // --- Aggregators ---

  Map<String,double> _aggOrdersByMonth() {
    final now = DateTime.now();
    final m = <String,double>{};
    for (int i = 11; i >= 0; i--) {
      final dt = DateTime(now.year, now.month - i);
      final key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}';
      m[key] = 0;
    }
    for (var o in _allOrders) {
      final key = '${o.createdAt.year}-${o.createdAt.month.toString().padLeft(2,'0')}';
      if (m.containsKey(key)) m[key] = m[key]! + 1;
    }
    return m;
  }

  Map<String,double> _aggRevenueByMonth() {
    final now = DateTime.now();
    final m = <String,double>{};
    for (int i = 11; i >= 0; i--) {
      final dt = DateTime(now.year, now.month - i);
      final key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}';
      m[key] = 0;
    }
    for (var o in _allOrders) {
      final key = '${o.createdAt.year}-${o.createdAt.month.toString().padLeft(2,'0')}';
      if (m.containsKey(key)) m[key] = m[key]! + (o.totalAmount ?? 0);
    }
    return m;
  }

  Map<String,double> _aggByInterval(IntervalType t, {required bool onlyRevenue}) {
    final out = <String,double>{};
    for (var o in _allOrders) {
      if (_customStart != null && o.createdAt.isBefore(_customStart!)) continue;
      if (_customEnd   != null && o.createdAt.isAfter(_customEnd!))   continue;

      String key;
      final dt = o.createdAt;
      switch (t) {
        case IntervalType.yearly:
          key = '${dt.year}'; break;
        case IntervalType.quarterly:
          final q = ((dt.month - 1) ~/ 3) + 1;
          key = '${dt.year}-Q$q'; break;
        case IntervalType.monthly:
          key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}'; break;
        case IntervalType.weekly:
          final w = ((dt.day - 1) ~/ 7) + 1;
          key = '${dt.year}-W$w'; break;
        case IntervalType.custom:
          key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}'; break;
      }
      final value = onlyRevenue ? (o.totalAmount ?? 0) : 1;
      out[key] = (out[key] ?? 0) + value;
    }
    return out;
  }

  // --- Chart builders ---

  Widget _buildLineChart({required Map<String,double> data}) {
    final list = data.entries.toList();
    final spots = <FlSpot>[];
    for (var i = 0; i < list.length; i++) {
      spots.add(FlSpot(i.toDouble(), list[i].value));
    }
    return LineChart(LineChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (x, _) {
              final idx = x.toInt().clamp(0, list.length - 1);
              return Text(list[idx].key, style: const TextStyle(fontSize: 10));
            },
          ),
        ),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
      ),
      lineBarsData: [LineChartBarData(spots: spots, isCurved: true)],
    ));
  }

  Widget _buildBarChart({required Map<String,double> data}) {
    final list = data.entries.toList();
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < list.length; i++) {
      groups.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: list[i].value, width: 12),
      ]));
    }
    return BarChart(BarChartData(
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (x, _) {
              final idx = x.toInt().clamp(0, list.length - 1);
              return Text(list[idx].key, style: const TextStyle(fontSize: 10));
            },
          ),
        ),
      ),
      barGroups: groups,
    ));
  }

  Widget _buildBarChartComparative({required Map<String,Map<String,double>> series}) {
    final keys = series.values.first.keys.toList();
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < keys.length; i++) {
      final k = keys[i];
      final y1 = series.values.elementAt(0)[k]!;
      final y2 = series.values.elementAt(1)[k]!;
      groups.add(BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [
          BarChartRodData(toY: y1, width: 8, color: Colors.blue),
          BarChartRodData(toY: y2, width: 8, color: Colors.red),
        ],
      ));
    }
    return BarChart(BarChartData(
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (x, _) {
              final idx = x.toInt().clamp(0, keys.length - 1);
              return Text(keys[idx], style: const TextStyle(fontSize: 10));
            },
          ),
        ),
      ),
      barGroups: groups,
    ));
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 24,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: Colors.deepPurple),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String txt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(txt, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDrawer(BuildContext ctx) {
    final items = {
      'Products': '/manager/products',
      'Coupons': '/manager/coupons',
      'Categories': '/manager/categories',
      'Users': '/manager/users',
      'Orders': '/manager/orders',
      'Support': '/manager/support',
    };
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Text('Admin Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          for (final e in items.entries)
            ListTile(
              title: Text(e.key),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                context.go(e.value);
                Navigator.of(ctx).pop();
              },
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _viewTabController.dispose();
    super.dispose();
  }
}
