import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:danentang/models/product.dart';
import 'package:danentang/models/Review.dart';
import 'package:danentang/models/CartItem.dart';
import 'package:danentang/Service/order_service.dart';
import 'package:danentang/Service/product_service.dart';
import 'package:danentang/widgets/Product/AddToCartDialog.dart';

class ProductInfo extends StatefulWidget {
  final Product product;

  const ProductInfo({super.key, required this.product});

  @override
  _ProductInfoState createState() => _ProductInfoState();
}

class _ProductInfoState extends State<ProductInfo> {
  late double _discountedBasePrice;
  late Future<List<Review>> _futureReviews;
  double _averageRating = 0;
  int _reviewCount = 0;
  WebSocket? _socket;

  @override
  void initState() {
    super.initState();
    _calculateDiscountedPrice();
    _loadReviews();
    _connectWebSocket();
  }

  void _calculateDiscountedPrice() {
    final cheapest = widget.product.variants.isNotEmpty
        ? widget.product.variants.reduce((a, b) =>
    a.additionalPrice < b.additionalPrice ? a : b)
        : null;
    final base = cheapest?.additionalPrice ?? 0.0;
    _discountedBasePrice =
        base * (1 - widget.product.discountPercentage / 100);
  }

  void _loadReviews() {
    _futureReviews = ProductService.getReviews(widget.product.id).then((reviews) {
      final rated = reviews.where((r) => r.rating != null).toList();
      _reviewCount = rated.length;
      _averageRating = rated.isEmpty
          ? 0
          : rated.map((e) => e.rating!).reduce((a, b) => a + b) / rated.length;
      return reviews;
    });
  }

  Future<void> _connectWebSocket() async {
    try {
      _socket = await WebSocket.connect('ws://localhost:5005/ws/review-stream');
      _socket!.listen((data) {
        final decoded = jsonDecode(data);
        if (decoded['productId'] == widget.product.id) {
          _loadReviews();
          setState(() {});
        }
      });
    } catch (e) {
      debugPrint("WebSocket error: $e");
    }
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }

  Future<void> _onAddToCart() async {
    final CartItem? item = await showDialog<CartItem>(
      context: context,
      builder: (_) => AddToCartDialog(
        product: widget.product,
        discountedPrice: _discountedBasePrice,
      ),
    );
    if (item == null) return;

    try {
      await OrderService.instance.addToCart(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm ${item.quantity} x ${widget.product.name} vào giỏ',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF87CEEB),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi thêm giỏ: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E90FF),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    const primaryColor = Color(0xFF1E90FF);
    const lightBlueColor = Color(0xFF87CEEB);
    const backgroundColor = Colors.white;

    return Container(
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.name,
            style: TextStyle(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Review>>(
            future: _futureReviews,
            builder: (context, snapshot) {
              return Row(
                children: [
                  RatingBarIndicator(
                    rating: _averageRating,
                    itemBuilder: (_, __) =>
                    const Icon(Icons.star, color: Colors.amber),
                    itemCount: 5,
                    itemSize: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($_reviewCount đánh giá)',
                    style: TextStyle(color: primaryColor.withOpacity(0.7)),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                "₫${_discountedBasePrice.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              if (widget.product.discountPercentage > 0)
                Text(
                  "₫${(_discountedBasePrice /
                      (1 - widget.product.discountPercentage / 100))
                      .toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 16,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Biến thể:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.product.variants.map((variant) {
            final variantPrice = variant.additionalPrice *
                (1 - widget.product.discountPercentage / 100);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    "${variant.variantName}: ",
                    style: TextStyle(color: primaryColor.withOpacity(0.7)),
                  ),
                  Text(
                    "₫${variantPrice.toStringAsFixed(0)} (Kho: ${variant.inventory})",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _onAddToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightBlueColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 16 : 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Thêm vào giỏ hàng",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2)),
                  ],
                ),

                child: IconButton(
                  icon: Icon(Icons.chat_bubble_outline,
                      size: 24, color: primaryColor),
                  onPressed: () => GoRouter.of(context).go('/chat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}