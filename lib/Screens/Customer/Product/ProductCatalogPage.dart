import 'package:flutter/material.dart';
import 'package:danentang/models/product.dart';
import 'package:danentang/models/Category.dart';
import 'package:danentang/models/Review.dart';
import 'package:danentang/widgets/Product_Catalog/filter_panel.dart';
import 'package:danentang/widgets/Product_Catalog/product_grid.dart';
import 'package:danentang/Service/product_service.dart';
import 'package:go_router/go_router.dart';

class ProductCatalogPage extends StatefulWidget {
  final String? categoryId;

  const ProductCatalogPage({super.key, this.categoryId});

  @override
  _ProductCatalogPageState createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  int _currentPage = 0;
  final int _pageSize = 8;
  bool _isLoading = false;
  bool _isFilterApplied = false;

  String? _selectedBrand;
  double _priceRange = double.infinity;
  int? _selectedRating;
  Map<String, List<Review>> _productReviews = {};

  late Future<List<Category>> _futureCategories;

  @override
  void initState() {
    super.initState();
    _futureCategories = ProductService.fetchAllCategories();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReviewsForProducts(List<Product> products) async {
    for (var product in products) {
      try {
        final reviews = await ProductService.getReviews(product.id);
        _productReviews[product.id] = reviews;
      } catch (e) {
        debugPrint('❌ Lỗi tải review cho ${product.id}: $e');
        _productReviews[product.id] = [];
      }
    }
  }

  Future<void> _loadProducts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      List<Product> allProducts;
      if (widget.categoryId != null) {
        allProducts = await ProductService.fetchProductsByCategory(widget.categoryId!);
      } else {
        allProducts = await ProductService.fetchAllProducts();
      }

      var filteredProducts = allProducts;
      if (_isFilterApplied) {
        if (_selectedBrand != null && _selectedBrand != 'All') {
          filteredProducts = filteredProducts.where((p) => p.brand == _selectedBrand).toList();
        }

        filteredProducts = filteredProducts.where((p) {
          final price = p.variants.isNotEmpty ? p.variants[0].additionalPrice : 0;
          return price <= _priceRange;
        }).toList();
      }

      final startIndex = _currentPage * _pageSize;
      final newProducts = filteredProducts.skip(startIndex).take(_pageSize).toList();
      await _loadReviewsForProducts(newProducts);
      if (_isFilterApplied && _selectedRating != null) {
        newProducts.removeWhere((product) {
          final reviews = _productReviews[product.id] ?? [];
          final validRatings = reviews.where((r) => r.rating != null).map((r) => r.rating!.toDouble()).toList();
          if (validRatings.isEmpty) return true;
          final avgRating = validRatings.reduce((a, b) => a + b) / validRatings.length;
          return avgRating < _selectedRating!;
        });
      }

      setState(() {
        _products.addAll(newProducts);
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading products: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadProducts();
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedBrand = null;
      _priceRange = double.infinity;
      _selectedRating = null;
      _isFilterApplied = false;
      _products.clear();
      _currentPage = 0;
      _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final canPop = GoRouter.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elap Commerce', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[700],
        leading: canPop
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            debugPrint('Back button pressed, canPop: $canPop');
            context.pop();
          },
        )
            : IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            debugPrint('No previous page, navigating to /home');
            context.go('/homepage');
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.shopping_cart, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        FutureBuilder<List<Category>>(
          future: _futureCategories,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                width: 250,
                padding: const EdgeInsets.all(16),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            final categories = snapshot.data!;
            final selectedCategoryId = categories.any((c) => c.id == widget.categoryId) ? widget.categoryId : null;
            return Container(
              width: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: FilterPanel(
                categories: categories,
                brands: ['All', 'Lenovo', 'Apple', 'Razer'],
                selectedCategoryId: selectedCategoryId,
                selectedBrand: _selectedBrand,
                priceRange: _priceRange.isFinite ? _priceRange : 100000000,
                selectedRating: _selectedRating,
                onCategoryChanged: (value) {
                  setState(() {
                    _products.clear();
                    _currentPage = 0;
                    _isFilterApplied = false;
                    context.go('/catalog/$value');
                  });
                },
                onBrandChanged: (value) {
                  setState(() {
                    _selectedBrand = value;
                    _isFilterApplied = true;
                    _products.clear();
                    _currentPage = 0;
                    _loadProducts();
                  });
                },
                onPriceChanged: (value) => setState(() => _priceRange = value),
                onPriceChangeEnd: (value) {
                  setState(() {
                    _priceRange = value;
                    _isFilterApplied = true;
                    _products.clear();
                    _currentPage = 0;
                    _loadProducts();
                  });
                },
                onRatingChanged: (value) {
                  setState(() {
                    _selectedRating = value;
                    _isFilterApplied = true;
                    _products.clear();
                    _currentPage = 0;
                    _loadProducts();
                  });
                },
                onReset: _resetFilters,
                onApply: () {
                  setState(() {
                    _isFilterApplied = true;
                    _products.clear();
                    _currentPage = 0;
                    _loadProducts();
                  });
                },
              ),
            );
          },
        ),
        Expanded(
          child: _products.isEmpty && !_isLoading
              ? const Center(child: Text('Không tìm thấy sản phẩm'))
              : ProductGrid(
            products: _products,
            isLoading: _isLoading,
            scrollController: _scrollController,
            productReviews: _productReviews,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => FutureBuilder<List<Category>>(
                  future: _futureCategories,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final categories = snapshot.data!;
                    final selectedCategoryId = categories.any((c) => c.id == widget.categoryId)
                        ? widget.categoryId
                        : null;
                    return FilterPanel(
                      categories: categories,
                      brands: ['All', 'Lenovo', 'Apple', 'Razer'],
                      selectedCategoryId: selectedCategoryId,
                      selectedBrand: _selectedBrand,
                      priceRange: _priceRange.isFinite ? _priceRange : 100000000,
                      selectedRating: _selectedRating,
                      onCategoryChanged: (value) {
                        setState(() {
                          _products.clear();
                          _currentPage = 0;
                          _isFilterApplied = false;
                          context.go('/catalog/$value');
                        });
                      },
                      onBrandChanged: (value) {
                        setState(() {
                          _selectedBrand = value;
                          _isFilterApplied = true;
                          _products.clear();
                          _currentPage = 0;
                          _loadProducts();
                        });
                      },
                      onPriceChanged: (value) => setState(() => _priceRange = value),
                      onPriceChangeEnd: (value) {
                        setState(() {
                          _priceRange = value;
                          _isFilterApplied = true;
                          _products.clear();
                          _currentPage = 0;
                          _loadProducts();
                        });
                      },
                      onRatingChanged: (value) {
                        setState(() {
                          _selectedRating = value;
                          _isFilterApplied = true;
                          _products.clear();
                          _currentPage = 0;
                          _loadProducts();
                        });
                      },
                      onReset: _resetFilters,
                      onApply: () {
                        setState(() {
                          _isFilterApplied = true;
                          _products.clear();
                          _currentPage = 0;
                          _loadProducts();
                        });
                      },
                    );
                  },
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Filters'),
          ),
        ),
        Expanded(
          child: _products.isEmpty && !_isLoading
              ? const Center(child: Text('Không tìm thấy sản phẩm'))
              : ProductGrid(
            products: _products,
            isLoading: _isLoading,
            scrollController: _scrollController,
            productReviews: _productReviews,
          ),
        ),
      ],
    );
  }
}