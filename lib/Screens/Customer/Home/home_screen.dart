import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:danentang/Screens/Customer/Product/ProductCatalogPage.dart';
import '../../../models/product.dart';
import '../../../models/Category.dart';
import '../../../models/tag.dart';
import '../../../Service/product_service.dart';
import '../../../widgets/banner_section.dart';
import '../../../widgets/product_section.dart';
import '../../../widgets/category_icon.dart';
import '../../../widgets/Header/mobile_header.dart';
import '../../../widgets/Header/web_header.dart';
import '../../../widgets/Search/mobile_search_bar.dart';
import '../../../widgets/Search/web_search_bar.dart';
import '../../../widgets/Footer/mobile_navigation_bar.dart';
import '../../../widgets/footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoggedIn = false;
  int selectedIndex = 0;
  bool showAllCategories = false;
  bool isLoading = true;
  double _opacity = 0.0;

  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  List<Category> categories = [];
  List<Tag> tags = [];
  Map<String, List<Product>> productsByTag = {};

  String? selectedCategory;
  String? selectedTag;
  double minPrice = 0;
  double maxPrice = 10000000;
  bool isPromoOnly = false;
  String sortOrder = 'A-Z';

  static const Map<String, Map<String, Object>> _iconMap = {
    'Laptops': {
      'icon': Icons.laptop,
      'color': Color(0xFFB3CDE0), // Pastel blue
    },
    'Hard Drives': {
      'icon': Icons.storage,
      'color': Color(0xFFE0BBE4), // Pastel purple
    },
    'Monitors': {
      'icon': Icons.monitor,
      'color': Color(0xFFC5E1A5), // Pastel green
    },
    'Keyboards': {
      'icon': Icons.keyboard,
      'color': Color(0xFFF9C1B1), // Pastel peach
    },
    'Headsets': {
      'icon': Icons.headset,
      'color': Color(0xFFB0E0E6), // Pastel aqua
    },
    'Speakers': {
      'icon': Icons.speaker,
      'color': Color(0xFFF8E1B0), // Pastel yellow
    },
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getString('token') != null;
    });
    await _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);
    try {
      final prods = await ProductService.fetchAllProducts();
      final cats = await ProductService.fetchAllCategories();
      final usedTags = await ProductService.fetchTagsWithProducts();

      final mapByTag = <String, List<Product>>{};
      for (final t in usedTags) {
        mapByTag[t.id] = await ProductService.fetchProductsByTag(t.id);
      }

      setState(() {
        allProducts = prods;
        filteredProducts = List<Product>.from(prods);
        categories = cats;
        tags = usedTags;
        productsByTag = mapByTag;
        _applyFilters(prods);
        isLoading = false;
        Future.delayed(const Duration(milliseconds: 100), () {
          setState(() => _opacity = 1.0);
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    } finally {
      if (mounted && isLoading) setState(() => isLoading = false);
    }
  }

  void _applyFilters(List<Product> products) {
    var filtered = List<Product>.from(products);

    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      filtered = filtered.where((p) => p.categoryId == selectedCategory).toList();
    }

    if (selectedTag != null && selectedTag!.isNotEmpty) {
      filtered = filtered
          .where((p) => productsByTag[selectedTag]
          ?.any((tp) => tp.id == p.id) ?? false)
          .toList();
    }

    filtered = filtered.where((p) {
      final effectivePrice = (p.discountPercentage ?? 0) > 0
          ? p.minPrice * (1 - p.discountPercentage! / 100)
          : p.minPrice;
      return effectivePrice >= minPrice && effectivePrice <= maxPrice;
    }).toList();

    if (isPromoOnly) {
      filtered = filtered
          .where((p) => (p.discountPercentage ?? 0) > 0)
          .toList();
    }

    filtered.sort((a, b) =>
    sortOrder == 'A-Z' ? a.name.compareTo(b.name) : b.name.compareTo(a.name));

    setState(() {
      filteredProducts = filtered;
    });
  }

  void _onNavTapped(int idx) {
    setState(() => selectedIndex = idx);
    switch (idx) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/checkout');
        break;
      case 2:
        context.go('/profile');
        break;
      case 3:
        context.go('/chat');
        break;
    }
  }

  int _calculateItemsPerRow(double w, double itemW, double spacing, double pad) {
    final avail = w - pad * 2;
    return ((avail + spacing) / (itemW + spacing)).floor();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bộ Lọc'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                hint: const Text('Chọn Danh Mục'),
                value: selectedCategory ?? '',
                items: [
                  const DropdownMenuItem(value: '', child: Text('Tất cả danh mục')),
                  ...categories.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  )),
                ],
                onChanged: (v) => setState(() {
                  selectedCategory = v!.isEmpty ? null : v;
                  _applyFilters(allProducts);
                }),
              ),
              DropdownButton<String>(
                hint: const Text('Chọn Thẻ'),
                value: selectedTag ?? '',
                items: [
                  const DropdownMenuItem(value: '', child: Text('Tất cả thẻ')),
                  ...tags.map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.name),
                  )),
                ],
                onChanged: (v) => setState(() {
                  selectedTag = v!.isEmpty ? null : v;
                  _applyFilters(allProducts);
                }),
              ),
              Row(
                children: [
                  Expanded(child: Text('Giá Từ: ₫${minPrice.toStringAsFixed(0)}')),
                  Expanded(
                    child: Slider(
                      value: minPrice,
                      min: 0,
                      max: 10000000,
                      onChanged: (v) => setState(() {
                        minPrice = v;
                        if (minPrice > maxPrice) maxPrice = minPrice;
                        _applyFilters(allProducts);
                      }),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text('Giá Đến: ₫${maxPrice.toStringAsFixed(0)}')),
                  Expanded(
                    child: Slider(
                      value: maxPrice,
                      min: 0,
                      max: 10000000,
                      onChanged: (v) => setState(() {
                        maxPrice = v;
                        if (maxPrice < minPrice) minPrice = maxPrice;
                        _applyFilters(allProducts);
                      }),
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                title: const Text('Chỉ Khuyến Mãi'),
                value: isPromoOnly,
                onChanged: (v) => setState(() {
                  isPromoOnly = v!;
                  _applyFilters(allProducts);
                }),
              ),
              DropdownButton<String>(
                hint: const Text('Sắp Xếp'),
                value: sortOrder,
                items: ['A-Z', 'Z-A']
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) => setState(() {
                  sortOrder = v!;
                  _applyFilters(allProducts);
                }),
              ),
              ElevatedButton(
                onPressed: () => setState(() {
                  selectedCategory = null;
                  selectedTag = null;
                  minPrice = 0;
                  maxPrice = 10000000;
                  isPromoOnly = false;
                  sortOrder = 'A-Z';
                  _applyFilters(allProducts);
                  Navigator.pop(ctx);
                }),
                child: const Text('Xóa Bộ Lọc'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (allProducts.isEmpty) {
      return const Scaffold(body: Center(child: Text('Không có sản phẩm nào để hiển thị')));
    }
    return w > 800 ? _buildWebLayout(w) : _buildMobileLayout(w);
  }

  Widget _buildMobileLayout(double w) {
    const iconSize = 80.0, iconSpacing = 8.0, iconPadding = 16.0;
    final maxCats = _calculateItemsPerRow(w, iconSize, iconSpacing, iconPadding);
    final visibleCats =
    showAllCategories ? categories : categories.take(maxCats).toList();

    return Scaffold(
      appBar: MobileHeader(isLoggedIn: _isLoggedIn),
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 500),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // search + filter
              Row(
                children: [
                  Expanded(child: MobileSearchBar()),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _showFilterDialog,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // categories
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: iconPadding, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Loại sản phẩm',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () =>
                          setState(() => showAllCategories = !showAllCategories),
                      child: Text(
                        showAllCategories ? 'Thu lại' : 'Xem tất cả',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              BannerSection(isWeb: false, screenWidth: w),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: iconPadding),
                child: Row(
                  children: visibleCats.map((cat) {
                    final iconData =
                        _iconMap[cat.name]?['icon'] as IconData? ?? Icons.category;
                    final iconColor =
                        _iconMap[cat.name]?['color'] as Color? ?? Colors.grey;
                    return Padding(
                      padding: const EdgeInsets.only(right: iconSpacing),
                      child: _AnimatedCategoryIcon(
                        icon: iconData,
                        label: cat.name,
                        color: iconColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductCatalogPage(categoryId: cat.id),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 40),
              // promo
              if (filteredProducts.any((p) => (p.discountPercentage ?? 0) > 0))
                ProductSection(
                  title: 'Khuyến mãi',
                  products: filteredProducts
                      .where((p) => (p.discountPercentage ?? 0) > 0)
                      .toList(),
                  isWeb: false,
                  screenWidth: w,
                  onTap: (p) =>
                      context.goNamed('product', pathParameters: {'id': p.id}),
                ),
              const SizedBox(height: 20),
              // by category
              for (final cat in categories)
                if (filteredProducts.any((p) => p.categoryId == cat.id))
                  ProductSection(
                    title: cat.name,
                    products: filteredProducts
                        .where((p) => p.categoryId == cat.id)
                        .toList(),
                    isWeb: false,
                    screenWidth: w,
                    onTap: (p) =>
                        context.goNamed('product', pathParameters: {'id': p.id}),
                  ),
              const SizedBox(height: 20),
              // by tag
              for (final tag in tags)
                if ((productsByTag[tag.id] ?? []).isNotEmpty)
                  ProductSection(
                    title: tag.name,
                    products: productsByTag[tag.id]!,  // ← show thẳng list này
                    isWeb: false,                       // ← thật ra đang chạy mobile
                    screenWidth: w,
                    onTap: (p) => context.goNamed('product', pathParameters: {'id': p.id}),
                  ),

            ],
          ),
        ),
      ),
      bottomNavigationBar: MobileNavigationBar(
        selectedIndex: selectedIndex,
        onItemTapped: _onNavTapped,
        isLoggedIn: _isLoggedIn,
        role: 'user',
      ),
    );
  }

  Widget _buildWebLayout(double w) {
    const iconSize = 80.0, iconSpacing = 16.0, iconPadding = 32.0;
    final maxCats = _calculateItemsPerRow(w, iconSize, iconSpacing, iconPadding);
    final visibleCats =
    showAllCategories ? categories : categories.take(maxCats).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: WebHeader(isLoggedIn: _isLoggedIn),
      ),
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 500),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // search + filter
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: w * 0.8, child: WebSearchBar(isLoggedIn: _isLoggedIn)),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _showFilterDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              BannerSection(isWeb: true, screenWidth: w),
              const SizedBox(height: 16),
              // categories
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: iconPadding, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Loại sản phẩm',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0251CD))),
                        GestureDetector(
                          onTap: () =>
                              setState(() => showAllCategories = !showAllCategories),
                          child: Text(
                            showAllCategories ? 'Thu lại' : 'Xem tất cả',
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: visibleCats.map((cat) {
                        final iconData =
                            _iconMap[cat.name]?['icon'] as IconData? ?? Icons.category;
                        final iconColor =
                            _iconMap[cat.name]?['color'] as Color? ?? Colors.grey;
                        return Padding(
                          padding: const EdgeInsets.only(right: iconSpacing),
                          child: _AnimatedCategoryIcon(
                            icon: iconData,
                            label: cat.name,
                            color: iconColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductCatalogPage(categoryId: cat.id),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // promo
              const SizedBox(height: 16),
              if (filteredProducts.any((p) => (p.discountPercentage ?? 0) > 0))
                ProductSection(
                  title: 'Khuyến mãi',
                  products:
                  filteredProducts.where((p) => (p.discountPercentage ?? 0) > 0).toList(),
                  isWeb: true,
                  screenWidth: w,
                  onTap: (p) =>
                      context.goNamed('product', pathParameters: {'id': p.id}),
                ),

              // by tag
              const SizedBox(height: 16),
              for (final tag in tags)
                if ((productsByTag[tag.id] ?? []).isNotEmpty)
                  ProductSection(
                    title: tag.name,
                    products: productsByTag[tag.id]!,
                    isWeb: true,
                    screenWidth: w,
                    onTap: (p) => context.goNamed('product', pathParameters: {'id': p.id}),
                  ),
              // by category
              const SizedBox(height: 16),
              for (final cat in categories)
                if (filteredProducts.any((p) => p.categoryId == cat.id))
                  ProductSection(
                    title: cat.name,
                    products:
                    filteredProducts.where((p) => p.categoryId == cat.id).toList(),
                    isWeb: true,
                    screenWidth: w,
                    onTap: (p) =>
                        context.goNamed('product', pathParameters: {'id': p.id}),
                  ),

              const SizedBox(height: 16),
              Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

// Animated Category Icon Widget
class _AnimatedCategoryIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedCategoryIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  __AnimatedCategoryIconState createState() => __AnimatedCategoryIconState();
}

class __AnimatedCategoryIconState extends State<_AnimatedCategoryIcon>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _scale = 1.1),
      onExit: (_) => setState(() => _scale = 1.0),
      child: InkWell(
        onTap: () {
          setState(() => _scale = 0.95);
          Future.delayed(const Duration(milliseconds: 100), () {
            setState(() => _scale = 1.0);
            widget.onTap();
          });
        },
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 200),
          child: CategoryIcon(
            icon: widget.icon,
            label: widget.label,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}
