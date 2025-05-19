import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:danentang/models/product.dart';
import 'package:danentang/models/Category.dart';
import 'package:danentang/models/tag.dart';
import 'package:danentang/Service/product_service.dart';
import 'package:go_router/go_router.dart';
import 'package:danentang/widgets/Footer/mobile_navigation_bar.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({Key? key}) : super(key: key);
  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim, _scaleAnim;

  late Future<List<Product>> _fProducts;
  late Future<List<Category>> _fCategories;
  late Future<List<Tag>> _fTags;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnim = Tween(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _loadData();
  }

  void _loadData() {
    _fProducts = ProductService.fetchAllProducts();
    _fCategories = ProductService.fetchAllCategories();
    _fTags = ProductService.fetchAllTags();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/manager/dashboard'),
          ),
          title: const Text('Manage Products',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [Tab(text: 'By Category'), Tab(text: 'By Tag')],
            labelColor: Colors.black,
            indicatorColor: Colors.purple,
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: FutureBuilder<List<dynamic>>(
              future: Future.wait([_fProducts, _fCategories, _fTags]),
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final products = snap.data![0] as List<Product>;
                final cats = snap.data![1] as List<Category>;
                final tags = snap.data![2] as List<Tag>;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Products: ${products.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total Categories: ${cats.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          RefreshIndicator(
                            onRefresh: () async => setState(_loadData),
                            child: ListView.builder(
                              itemCount: cats.length,
                              itemBuilder: (ctx, i) {
                                final cat = cats[i];
                                final prods = products
                                    .where((p) => p.categoryId == cat.id)
                                    .toList();
                                return ExpansionTile(
                                  title: Text(cat.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  children: prods.isEmpty
                                      ? [
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('— No products —',
                                          textAlign: TextAlign.center),
                                    )
                                  ]
                                      : prods.map(_buildProductTile).toList(),
                                );
                              },
                            ),
                          ),
                          RefreshIndicator(
                            onRefresh: () async => setState(_loadData),
                            child: ListView.builder(
                              itemCount: tags.length,
                              itemBuilder: (ctx, i) {
                                final tag = tags[i];
                                return ExpansionTile(
                                  title: Text(tag.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  children: [
                                    FutureBuilder<List<Product>>(
                                      future:
                                      ProductService.fetchProductsByTag(tag.id),
                                      builder: (c2, psnap) {
                                        if (psnap.connectionState !=
                                            ConnectionState.done) {
                                          return const Center(
                                              child: CircularProgressIndicator());
                                        }
                                        final list = psnap.data!;
                                        if (list.isEmpty) {
                                          return const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Text('— No products —',
                                                textAlign: TextAlign.center),
                                          );
                                        }
                                        return Column(
                                            children: list
                                                .map(_buildProductTile)
                                                .toList());
                                      },
                                    )
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(FontAwesomeIcons.plus),
          onPressed: () async {
            final result = await context.pushNamed<bool>('add-product');
            if (result == true) setState(_loadData);
          },
        ),
        bottomNavigationBar: isMobile
            ? MobileNavigationBar(
          selectedIndex: 0,
          onItemTapped: (_) {},
          isLoggedIn: true,
          role: 'manager',
        )
            : null,
      ),
    );
  }

  Widget _buildProductTile(Product p) {
    final cheapest = p.variants.isNotEmpty
        ? p.variants.reduce(
            (a, b) => a.additionalPrice < b.additionalPrice ? a : b)
        : null;
    final price = cheapest?.additionalPrice ?? 0.0;
    final discounted = price * (1 - p.discountPercentage / 100);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.goNamed('manager-product-detail', pathParameters: {'id': p.id});
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: p.images.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _safeBase64Image(
                    p.images.first.url,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                )
                    : const Icon(
                  Icons.image,
                  color: Colors.grey,
                  size: 40,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '₫${discounted.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Last updated: 10:56 AM +07 on Sunday, May 18, 2025',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () async {
                  final result = await context.pushNamed<bool>('add-product',
                      extra: p);
                  if (result == true) setState(_loadData);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final result = await context.pushNamed<bool>('delete-product',
                      pathParameters: {'id': p.id}, extra: p);
                  if (result == true) setState(_loadData);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _safeBase64Image(
      String base64String, {
        double? width,
        double? height,
        BoxFit? fit,
      }) {
    try {
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _fallbackImage(width, height),
      );
    } catch (_) {
      return _fallbackImage(width, height);
    }
  }

  Widget _fallbackImage(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image,
        size: 40,
        color: Colors.grey,
      ),
    );
  }
}