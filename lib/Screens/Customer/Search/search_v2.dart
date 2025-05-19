import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../Service/product_service.dart';
import '../../../Service/search_service.dart';
import '../../../models/product.dart';
import '../../../models/Review.dart';
import '../../../widgets/Search/ProductCard.dart';

class Searching extends StatelessWidget {
  const Searching({super.key});

  @override
  Widget build(BuildContext context) {
    return const SearchScreen();
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  List<Product> _searchResults = [];
  List<Product> _recommendedProducts = [];
  List<String> _autocompleteSuggestions = [];
  Timer? _debounce;
  Map<String, String> _categoryNames = {};
  List<String> _brands = [];
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  Map<String, List<Review>> _productReviews = {};
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
    _loadInitialData();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
        if (_isSearchFocused && _searchController.text.isEmpty) {
          _loadRecommendedProducts();
          _animationController?.forward();
        } else {
          _animationController?.reverse();
        }
      });
    });
  }

  Future<void> _loadInitialData() async {
    await _loadCategoryNames();
    await _loadBrands();
  }

  Future<void> _loadCategoryNames() async {
    try {
      final categories = await _searchService.getCategories();
      for (var categoryId in categories) {
        final name = await _searchService.getCategoryName(categoryId!);
        if (!mounted) return;
        setState(() {
          _categoryNames[categoryId] = name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh mục: $e')),
      );
    }
  }

  Future<void> _loadBrands() async {
    try {
      final brands = await _searchService.getBrands();
      if (!mounted) return;
      setState(() {
        _brands = brands.whereType<String>().toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải thương hiệu: $e')),
      );
    }
  }

  Future<void> _loadRecommendedProducts() async {
    try {
      final highRatedProducts = await _searchService.getHighRatedProducts(minRating: 3.0);
      if (!mounted) return;
      setState(() {
        _recommendedProducts = highRatedProducts.where((product) {
          final reviews = _productReviews[product.id] ?? [];
          final validReviews = reviews.where((r) => r.rating != null).toList();
          final averageRating = validReviews.isNotEmpty
              ? validReviews.map((r) => r.rating!.toDouble()).reduce((a, b) => a + b) /
              validReviews.length
              : 0.0;
          return averageRating >= 3.0;
        }).toList();
        _animationController?.forward();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải sản phẩm đề xuất: $e')),
      );
    }
  }

  Future<void> _loadReviewsForProducts(List<Product> products) async {
    try {
      for (final product in products) {
        final reviews = await ProductService.getReviews(product.id);
        _productReviews[product.id] = reviews;
      }
    } catch (e) {
      debugPrint('Lỗi khi tải đánh giá: $e');
    }
  }

  Map<String, dynamic> _parseFilterInput(String filterText) {
    List<String> brands = [];
    double? minPrice;
    double? maxPrice;
    String? category;
    double? minRating;
    String? error;

    final parts = filterText.trim().split(' ').where((p) => p.isNotEmpty).toList();
    for (var part in parts) {
      if (part.startsWith('brand:')) {
        brands = part.substring(6).split(',').where((b) => b.isNotEmpty).toList();
        if (brands.any((b) => !_brands.contains(b))) {
          error = 'Thương hiệu không hợp lệ: ${brands.firstWhere((b) => !_brands.contains(b))}';
        }
      } else if (part.startsWith('min:')) {
        minPrice = double.tryParse(part.substring(4));
        if (minPrice == null) error = 'Giá tối thiểu không hợp lệ';
      } else if (part.startsWith('max:')) {
        maxPrice = double.tryParse(part.substring(4));
        if (maxPrice == null) error = 'Giá tối đa không hợp lệ';
      } else if (part.startsWith('cat:')) {
        category = part.substring(4);
        if (!_categoryNames.containsKey(category)) error = 'Danh mục không hợp lệ';
      } else if (part.startsWith('rating:')) {
        minRating = double.tryParse(part.substring(7));
        if (minRating == null || minRating < 0 || minRating > 5) {
          error = 'Đánh giá phải từ 0 đến 5';
        }
      } else {
        error = 'Tiêu chí không hợp lệ: $part';
      }
    }

    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      error = 'Giá tối thiểu không được lớn hơn giá tối đa';
    }

    return {
      'brands': brands,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'category': category,
      'minRating': minRating,
      'error': error,
    };
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.isNotEmpty) {
        try {
          final suggestions = await _searchService.autocomplete(query);
          if (!mounted) return;
          setState(() {
            _autocompleteSuggestions = suggestions;
            _searchResults = [];
            _recommendedProducts = [];
            _animationController?.forward();
          });
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi gợi ý: $e')),
          );
        }
      } else {
        if (!mounted) return;
        setState(() {
          _autocompleteSuggestions.clear();
          _searchResults.clear();
          if (_searchFocusNode.hasFocus) {
            _loadRecommendedProducts();
          } else {
            _animationController?.reverse();
          }
        });
      }
    });
  }

  void _submitSearch(String query, {String filterText = ''}) async {
    try {
      final filter = _parseFilterInput(filterText);
      if (filter['error'] != null) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Lỗi bộ lọc'),
            content: Text(filter['error']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final results = await _searchService.searchProducts(
        query,
        brands: filter['brands'],
        minPrice: filter['minPrice'],
        maxPrice: filter['maxPrice'],
        category: filter['category'],
        minRating: filter['minRating'],
      );
      await _loadReviewsForProducts(results);
      if (!mounted) return;
      setState(() {
        _searchResults = results
          ..sort((a, b) {
            final reviewsA = _productReviews[a.id] ?? [];
            final validReviewsA = reviewsA.where((r) => r.rating != null).toList();
            final averageRatingA = validReviewsA.isNotEmpty
                ? validReviewsA.map((r) => r.rating!.toDouble()).reduce((a, b) => a + b) /
                validReviewsA.length
                : 0.0;

            final reviewsB = _productReviews[b.id] ?? [];
            final validReviewsB = reviewsB.where((r) => r.rating != null).toList();
            final averageRatingB = validReviewsB.isNotEmpty
                ? validReviewsB.map((r) => r.rating!.toDouble()).reduce((a, b) => a + b) /
                validReviewsB.length
                : 0.0;

            if (averageRatingA == 5.0 && averageRatingB != 5.0) return -1;
            if (averageRatingA != 5.0 && averageRatingB == 5.0) return 1;
            return averageRatingB.compareTo(averageRatingA);
          });
        _autocompleteSuggestions.clear();
        _recommendedProducts = [];
        _animationController?.forward();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tìm kiếm: $e')),
      );
    }
  }

  void _clearSearchHistory() {
    setState(() {
      _searchService.clearSearchHistory();
    });
  }

  void _removeSearchItem(String query) {
    setState(() {
      _searchService.removeFromSearchHistory(query);
    });
  }

  void _showFilterBottomSheet() {
    _animationController?.forward();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AnimatedBuilder(
          animation: _fadeAnimation!,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation!,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController!,
                  curve: Curves.easeInOut,
                )),
                child: child,
              ),
            );
          },
          child: FilterBottomSheet(
            brands: _brands,
            categories: _categoryNames,
            onApply: (brands, minPrice, maxPrice, category, minRating) {
              final filterText = [
                if (brands.isNotEmpty) 'brand:${brands.join(',')}',
                if (minPrice != null) 'min:$minPrice',
                if (maxPrice != null) 'max:$maxPrice',
                if (category != null) 'cat:$category',
                if (minRating != null) 'rating:$minRating',
              ].join(' ');
              _submitSearch(_searchController.text, filterText: filterText);
            },
          ),
        );
      },
    ).whenComplete(() => _animationController?.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  onSubmitted: (query) => _submitSearch(query),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.black87),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.black87),
                onPressed: _showFilterBottomSheet,
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
                onPressed: () {
                  if (context.mounted) {
                    context.go('/checkout');
                  }
                },
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isSearchFocused &&
                      _searchController.text.isEmpty &&
                      _recommendedProducts.isNotEmpty) ...[
                    const Text(
                      'Sản phẩm được đánh giá cao',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      opacity: _recommendedProducts.isNotEmpty ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 900
                              ? 6
                              : MediaQuery.of(context).size.width > 600
                              ? 4
                              : 2,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: _recommendedProducts.length,
                        itemBuilder: (context, index) {
                          final product = _recommendedProducts[index];
                          final imageUrl = product.images.isNotEmpty ? product.images[0].url : '';
                          final reviews = _productReviews[product.id] ?? [];
                          final validReviews = reviews.where((r) => r.rating != null).toList();
                          final averageRating = validReviews.isNotEmpty
                              ? validReviews
                              .map((r) => r.rating!.toDouble())
                              .reduce((a, b) => a + b) /
                              validReviews.length
                              : 0.0;
                          final reviewCount = validReviews.length;
                          return ProductCard(
                            product: product,
                            imageUrl: imageUrl,
                            averageRating: averageRating,
                            reviewCount: reviewCount,
                            width: double.infinity,
                            height: 120,
                          );
                        },
                      ),
                    ),
                  ],
                  if (_searchController.text.isEmpty &&
                      _searchService.getSearchHistory().isNotEmpty &&
                      !_isSearchFocused) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lịch sử tìm kiếm',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: _clearSearchHistory,
                          child: const Text(
                            'Xóa tất cả',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      opacity: _searchService.getSearchHistory().isNotEmpty ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: _searchService.getSearchHistory().length,
                        itemBuilder: (context, index) {
                          final query = _searchService.getSearchHistory()[index];
                          return ListTile(
                            leading: const Icon(Icons.history, color: Colors.grey),
                            title: Text(query),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _removeSearchItem(query),
                            ),
                            onTap: () {
                              _searchController.text = query;
                              _submitSearch(query);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Kết quả tìm kiếm',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      opacity: _searchResults.isNotEmpty ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 900
                              ? 6
                              : MediaQuery.of(context).size.width > 600
                              ? 4
                              : 2,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final product = _searchResults[index];
                          final imageUrl = product.images.isNotEmpty ? product.images[0].url : '';
                          final reviews = _productReviews[product.id] ?? [];
                          final validReviews = reviews.where((r) => r.rating != null).toList();
                          final averageRating = validReviews.isNotEmpty
                              ? validReviews
                              .map((r) => r.rating!.toDouble())
                              .reduce((a, b) => a + b) /
                              validReviews.length
                              : 0.0;
                          final reviewCount = validReviews.length;
                          return ProductCard(
                            product: product,
                            imageUrl: imageUrl,
                            averageRating: averageRating,
                            reviewCount: reviewCount,
                            width: double.infinity,
                            height: 120,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_autocompleteSuggestions.isNotEmpty && _isSearchFocused)
              Positioned(
                top: 0,
                left: 12,
                right: 12,
                child: AnimatedOpacity(
                  opacity: _autocompleteSuggestions.isNotEmpty ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.identity()
                      ..scale(_autocompleteSuggestions.isNotEmpty ? 1.0 : 0.95),
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: _autocompleteSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = _autocompleteSuggestions[index];
                            final normalizedQuery = _searchController.text.toLowerCase();
                            final normalizedSuggestion = suggestion.toLowerCase();
                            final startIndex = normalizedSuggestion.indexOf(normalizedQuery);
                            return ListTile(
                              title: RichText(
                                text: TextSpan(
                                  children: [
                                    if (startIndex != -1) ...[
                                      TextSpan(
                                        text: suggestion.substring(0, startIndex),
                                        style: const TextStyle(color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: suggestion.substring(
                                            startIndex, startIndex + normalizedQuery.length),
                                        style: const TextStyle(
                                            color: Colors.teal, fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text:
                                        suggestion.substring(startIndex + normalizedQuery.length),
                                        style: const TextStyle(color: Colors.black),
                                      ),
                                    ] else
                                      TextSpan(
                                        text: suggestion,
                                        style: const TextStyle(color: Colors.black),
                                      ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                _searchController.text = suggestion;
                                _submitSearch(suggestion);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController?.dispose();
    super.dispose();
  }
}

class FilterBottomSheet extends StatefulWidget {
  final List<String> brands;
  final Map<String, String> categories;
  final Function(List<String>, double?, double?, String?, double?) onApply;

  const FilterBottomSheet({
    super.key,
    required this.brands,
    required this.categories,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  List<String> selectedBrands = [];
  double? minPrice;
  double? maxPrice;
  String? selectedCategory;
  double? minRating;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bộ lọc nâng cao',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 16),
                const Text('Thương hiệu', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: widget.brands.map((brand) {
                    final isSelected = selectedBrands.contains(brand);
                    return ChoiceChip(
                      label: Text(brand),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedBrands.add(brand);
                          } else {
                            selectedBrands.remove(brand);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Khoảng giá', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tối thiểu',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          minPrice = double.tryParse(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tối đa',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          maxPrice = double.tryParse(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Danh mục', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Chọn danh mục'),
                  value: selectedCategory,
                  items: widget.categories.entries
                      .map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Đánh giá tối thiểu', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: minRating ?? 0,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: minRating?.toStringAsFixed(1) ?? '0.0',
                  onChanged: (value) {
                    setState(() {
                      minRating = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        widget.onApply(
                          selectedBrands,
                          minPrice,
                          maxPrice,
                          selectedCategory,
                          minRating,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Áp dụng'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}