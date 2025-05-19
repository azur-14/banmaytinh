import 'package:flutter/material.dart';
import 'package:danentang/models/Order.dart';
import 'package:danentang/Service/order_service.dart';
import 'package:danentang/widgets/Order/OrderCard.dart';
import 'package:danentang/widgets/Order/order_filter_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Service/user_service.dart';
import 'package:danentang/models/product.dart';
import 'package:danentang/Service/product_service.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<Order> userOrders = [];
  String? userId;
  bool _isLoading = true;
  String? _error;
  Map<String, List<Order>> filteredOrders = {};
  Map<String, int> orderCounts = {};
  DateTime? _startDate;
  DateTime? _endDate;
  RangeValues _priceRange = const RangeValues(0, 10000000);
  String _searchQuery = '';
  final double _maxPrice = 10000000;
  late TabController _tabController;
  String _selectedCategory = 'All';
  String _selectedBrand = 'All';
  final List<String> _categories = ['All', 'Laptop', 'Headphones', 'MacBook'];
  final List<String> _brands = ['All', 'Lenovo', 'Apple', 'Logitech'];
  List<Product> products = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? '';
      if (email.isEmpty) throw Exception("Bạn chưa đăng nhập!");

      final user = await UserService().fetchUserByEmail(email);
      userId = user.id;

      userOrders = await OrderService.fetchOrdersByUserId(userId!);
      products = await ProductService.fetchAllProducts(); // ✅ THÊM DÒNG NÀY

      debugPrint('💡 fetched userOrders.length = ${userOrders.length} for userId=$userId');
      _applyFilters();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _fetchOrders() async {
    if (userId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      userOrders = await OrderService.fetchOrdersByUserId(userId!);
      _applyFilters();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _applyFilters() {
    // Kiểm tra xem có đang bật filter nào không
    final bool hasFilters =
        _startDate != null ||
            _endDate   != null ||
            _searchQuery.isNotEmpty ||
            _selectedCategory != 'All' ||
            _selectedBrand   != 'All' ||
            _priceRange.start > 0 ||
            _priceRange.end   < _maxPrice;

    // Danh sách đã lọc hoặc toàn bộ
    final List<Order> filteredList = hasFilters
        ? userOrders.where((order) {
      // DATE
      bool passesDate = true;
      if (_startDate != null) {
        passesDate = order.createdAt.isAfter(_startDate!);
      }
      if (_endDate != null) {
        passesDate = passesDate && order.createdAt.isBefore(_endDate!);
      }
      // PRICE
      final price = order.totalAmount ?? 0;
      final passesPrice = price >= _priceRange.start && price <= _priceRange.end;
      // SEARCH
      final passesSearch = _searchQuery.isEmpty ||
          order.items.any((item) => item.productName.toLowerCase().contains(_searchQuery.toLowerCase()));
      // CATEGORY
      final passesCategory = _selectedCategory == 'All' ||
          order.items.any((item) => item.productName.contains(_selectedCategory));
      // BRAND
      final passesBrand = _selectedBrand == 'All' ||
          order.items.any((item) => item.productName.contains(_selectedBrand));

      return passesDate && passesPrice && passesSearch && passesCategory && passesBrand;
    }).toList()
        : List<Order>.from(userOrders);

    // Tạo map filteredOrders cho từng tab, dựa trên filteredList
    filteredOrders = {
      'all'      : filteredList,
      'pending'  : filteredList.where((o) => ['pending','Chờ xác nhận','Đặt hàng','Đang chờ xử lý'].contains(o.status)).toList(),
      'shipped'  : filteredList.where((o) => ['shipped','Đang giao'].contains(o.status)).toList(),
      'delivered': filteredList.where((o) => ['delivered','Đã giao'].contains(o.status)).toList(),
      'canceled' : filteredList.where((o) => ['canceled','Đã hủy'].contains(o.status)).toList(),
    };

    // Cập nhật số lượng trên mỗi tab
    orderCounts = {
      'all'      : filteredOrders['all']!.length,
      'pending'  : filteredOrders['pending']!.length,
      'shipped'  : filteredOrders['shipped']!.length,
      'delivered': filteredOrders['delivered']!.length,
      'canceled' : filteredOrders['canceled']!.length,
    };

    setState(() {});
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _priceRange = RangeValues(0, _maxPrice);
      _searchQuery = '';
      _selectedCategory = 'All';
      _selectedBrand = 'All';
      _applyFilters();
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return OrderFilterWidget(
          maxPrice: _maxPrice,
          priceRange: _priceRange,
          startDate: _startDate,
          endDate: _endDate,
          selectedCategory: _selectedCategory,
          selectedBrand: _selectedBrand,
          categories: _categories,
          brands: _brands,
          isDialog: true,
          onPriceRangeChanged: (v) => setState(() => _priceRange = v),
          onStartDateChanged: (d) => setState(() => _startDate = d),
          onEndDateChanged:   (d) => setState(() => _endDate = d),
          onCategoryChanged:  (c) => setState(() => _selectedCategory = c),
          onBrandChanged:     (b) => setState(() => _selectedBrand = b),
          onApply:            _applyFilters,
          onReset:            _clearFilters,
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    bool hasActiveFilters = _startDate != null ||
        _endDate != null ||
        _priceRange.start != 0 ||
        _priceRange.end != _maxPrice ||
        _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF4B5EFC),
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3B82F6)),
          onPressed: () {
            if (context.canPop()) context.pop();
            else context.go('/homepage');
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = constraints.maxWidth < 900 ? constraints.maxWidth : 900.0;
                return Center(
                  child: Container(
                    width: contentWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF64748B),
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                      tabs: [
                        _buildTab('Tất cả', orderCounts['all'] ?? 0, Icons.all_inclusive),
                        _buildTab('Chờ xác nhận', orderCounts['pending'] ?? 0, Icons.hourglass_empty),
                        _buildTab('Đang giao', orderCounts['shipped'] ?? 0, Icons.local_shipping),
                        _buildTab('Đã giao', orderCounts['delivered'] ?? 0, Icons.check_circle),
                        _buildTab('Đã hủy', orderCounts['canceled'] ?? 0, Icons.cancel),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: MediaQuery.of(context).size.width <= 800
          ? FloatingActionButton(
        onPressed: _showFilterDialog,
        backgroundColor: const Color(0xFF3B82F6),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.filter_list, color: Colors.white),
            if (hasActiveFilters)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: const Text('!', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : LayoutBuilder(
        builder: (context, constraints) {
          final isWeb = constraints.maxWidth > 800;
          final contentWidth = constraints.maxWidth < 900 ? constraints.maxWidth : 900.0;
          return Row(
            children: [
              if (isWeb)
                Container(
                  width: 300,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 2, blurRadius: 8, offset: const Offset(0,2))],
                  ),
                  child: OrderFilterWidget(
                    maxPrice: _maxPrice,
                    priceRange: _priceRange,
                    startDate: _startDate,
                    endDate: _endDate,
                    selectedCategory: _selectedCategory,
                    selectedBrand: _selectedBrand,
                    categories: _categories,
                    brands: _brands,
                    isDialog: false,
                    onPriceRangeChanged: (v) => setState(() => _priceRange = v),
                    onStartDateChanged: (d) => setState(() => _startDate = d),
                    onEndDateChanged:   (d) => setState(() => _endDate = d),
                    onCategoryChanged:  (c) => setState(() => _selectedCategory = c),
                    onBrandChanged:     (b) => setState(() => _selectedBrand = b),
                    onApply:            _applyFilters,
                    onReset:            _clearFilters,
                  ),
                ),
              Expanded(
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    padding: const EdgeInsets.all(16),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrderList(filteredOrders['all'] ?? []),
                        _buildOrderList(filteredOrders['pending'] ?? []),
                        _buildOrderList(filteredOrders['shipped'] ?? []),
                        _buildOrderList(filteredOrders['delivered'] ?? []),
                        _buildOrderList(filteredOrders['canceled'] ?? []),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(String title, int count, IconData icon) {
    return Tab(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Flexible(child: Text('$title ($count)', overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    return orders.isEmpty
        ? const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Color(0xFF94A3B8)),
          SizedBox(height: 16),
          Text('Không có đơn hàng nào', style: TextStyle(fontSize: 18, color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Hãy đặt hàng để bắt đầu!', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        ],
      ),
    )
        : RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: OrderCard(
              order: order,
              products: products,
            ),

          );
        },
      ),
    );
  }
}
