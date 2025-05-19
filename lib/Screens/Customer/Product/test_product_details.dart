import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:danentang/models/product.dart';
import 'package:danentang/models/ProductRating.dart';
import 'package:danentang/Service/order_service.dart';
import 'package:danentang/Service/product_service.dart';
import 'package:danentang/widgets/Header/web_header.dart';
import 'package:danentang/widgets/Product/product_image_carousel.dart';
import 'package:danentang/widgets/Product/product_info.dart';
import 'package:danentang/widgets/Product/product_tabs.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({Key? key, required this.productId})
      : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<Product> _productFuture;
  late Future<ProductRating> _ratingFuture;
  late TabController _tabController;
  bool _isLoggedIn = false;

  final OrderService _orderService = OrderService.instance;

  @override
  void initState() {
    super.initState();

    // 1. Khởi tạo TabController cho ProductTabs
    _tabController = TabController(length: 2, vsync: this);

    // 2. Load product và rating
    _productFuture = ProductService.getById(widget.productId);
    _ratingFuture = ProductService.getRating(widget.productId);

    // 3. Kiểm tra login để hiển thị header phù hợp
    _checkLoginState();

    // 4. Đảm bảo đã có cartId anonymous trong prefs
    _ensureAnonymousCart();
  }

  Future<void> _checkLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getString('token') != null;
    });
  }

  /// Nếu chưa có cartId trong prefs, tạo 1 cart anonymous và lưu vào prefs
  Future<void> _ensureAnonymousCart() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('cartId') == null) {
      // Tạo cart rỗng với userId = ""
      final cart = await _orderService.createCart('');
      await prefs.setString('cartId', cart.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const maxContentWidth = 1200.0;

    // Define blue-green color scheme
    const primaryColor = Color(0xFF1E90FF); // Dodger Blue
    const accentColor = Color(0xFF20B2AA); // Light Sea Green
    const backgroundColor = Color(0xFFE6F3F7); // Light blue-green background

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_productFuture, _ratingFuture]),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: primaryColor)),
          );
        }
        if (snap.hasError || snap.data == null) {
          return const Scaffold(
            body: Center(child: Text('Không tải được dữ liệu sản phẩm.', style: TextStyle(color: primaryColor))),
          );
        }

        final product = snap.data![0] as Product;
        final productRating = snap.data![1] as ProductRating;

        return Scaffold(
          backgroundColor: backgroundColor, // Subtle blue-green background
          appBar: screenWidth <= 800
              ? AppBar(
            title: const Text("Chi tiết sản phẩm", style: TextStyle(color: Colors.white)),
            backgroundColor: primaryColor,
          )
              : null,
          body: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: screenWidth > 800 ? maxContentWidth : 600.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [backgroundColor, Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Web header chỉ hiển thị ở desktop
                      if (screenWidth > 800) WebHeader(isLoggedIn: _isLoggedIn),

                      // Layout ảnh + info
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: screenWidth > 800
                              ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 400,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: ProductImageCarousel(product: product),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: ProductInfo(
                                    product: product,
                                  ),
                                ),
                              ),
                            ],
                          )
                              : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: ProductImageCarousel(product: product),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: ProductInfo(
                                  product: product,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Tabs: chi tiết vs đánh giá
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: ProductTabs(
                            tabController: _tabController,
                            product: product,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}