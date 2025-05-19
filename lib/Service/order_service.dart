import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:danentang/models/Cart.dart';
import 'package:danentang/models/CartItem.dart';
import 'package:danentang/models/Coupon.dart';
import 'package:danentang/models/Order.dart';
import 'package:danentang/models/OrderStatusHistory.dart';

import '../models/OrderItem.dart';
import '../models/ShippingAddress.dart';

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  static const String _baseUrl = 'https://orderservice-production-e536.up.railway.app.up.railway.app/api';
  static const String _cartUrl = 'https://orderservice-production-e536.up.railway.app.up.railway.app/api/carts';  final http.Client _http = http.Client();
  final Uuid _uuid = Uuid();

  // ───────────────────────────────────────────────
  // CART
  // ───────────────────────────────────────────────
  Future<String?> _getCartId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cartId');
  }
  Future<Cart> fetchCartByUserId(String userId) async {
    final uri = Uri.parse('$_baseUrl/carts/user/$userId');
    debugPrint('→ GET $uri');
    final resp = await _http.get(uri);
    debugPrint('← ${resp.statusCode} ${resp.body}');

    if (resp.statusCode == 200) {
      return Cart.fromJson(json.decode(resp.body));
    }
    if (resp.statusCode == 404) {
      return await createCart(userId); // nếu chưa có cart thì tạo mới
    }
    throw Exception('fetchCartByUserId failed (${resp.statusCode})');
  }

  /// Lưu cartId (sau khi create hoặc lần đầu add)
  Future<void> _saveCartId(String cartId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cartId', cartId);
  }

  Future<void> addToCart(CartItem item) async {
    String? cartId = await _getCartId();

    if (cartId == null) {
      final res = await http.post(
        Uri.parse(_cartUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'items': [], 'userId': null}),
      );
      if (res.statusCode == 201) {
        final body = jsonDecode(res.body);
        // ép về String
        final String newCartId = body['id'] as String;
        cartId = newCartId;
        await _saveCartId(newCartId);
      } else {
        throw Exception('Không tạo được giỏ');
      }
    }

    // tới đây cartId đã non-null
    final String nonNullCartId = cartId!;
    final res2 = await http.patch(
      Uri.parse('$_cartUrl/$nonNullCartId/items'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (res2.statusCode != 204) {
      throw Exception('Không thêm được sản phẩm vào giỏ');
    }
  }


  Future<Cart> fetchCart(String cartId) async {
    final uri = Uri.parse('$_baseUrl/carts/$cartId');
    debugPrint('→ GET $uri');
    final resp = await _http.get(uri);
    debugPrint('← ${resp.statusCode} ${resp.body}');

    if (resp.statusCode == 200) {
      return Cart.fromJson(json.decode(resp.body));
    }
    if (resp.statusCode == 404) {
      return createCart(cartId);
    }
    throw Exception('fetchCart failed (${resp.statusCode})');
  }

  Future<Cart> createCart(String userId) async {
    final uri = Uri.parse('$_baseUrl/carts');
    final now = DateTime.now().toUtc().toIso8601String();
    final generatedId = _uuid.v4();

    final payload = {
      'id': generatedId,
      'userId': userId,      // giờ luôn là String, không null
      'items': <dynamic>[],
      'createdAt': now,
      'updatedAt': now,
    };

    final resp = await _http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    if (resp.statusCode == 201) {
      return Cart.fromJson(json.decode(resp.body));
    }
    throw Exception('createCart failed (${resp.statusCode})');
  }


  Future<void> upsertCartItemSmart(Cart cart, CartItem newItem) async {
    final existing = cart.items.firstWhere(
          (i) => i.productVariantId == newItem.productVariantId,
      orElse: () => CartItem.empty(),
    );
    if (existing.productId != null) {
      existing.quantity += newItem.quantity;
      await replaceCartItems(cart.id, cart.items);
    } else {
      await upsertCartItem(cart.id, newItem);
    }
  }

  Future<void> replaceCartItems(String cartId, List<CartItem> items) async {
    final uri = Uri.parse('$_baseUrl/carts/$cartId');
    final payload = json.encode(items.map((e) => e.toJson()).toList());
    final resp = await _http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );
    if (resp.statusCode != 204) {
      throw Exception('replaceCartItems failed (${resp.statusCode})');
    }
  }

  Future<void> clearCart(String cartId) async {
    await replaceCartItems(cartId, []);
  }

  Future<void> upsertCartItem(String cartId, CartItem item) async {
    final uri = Uri.parse('$_baseUrl/carts/$cartId/items');
    final body = json.encode(item.toJson());
    debugPrint('→ PATCH $uri  body=$body');
    final resp = await _http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    debugPrint('← ${resp.statusCode}');
    if (resp.statusCode != 204) {
      throw Exception('upsertCartItem failed (${resp.statusCode})');
    }
  }

  Future<void> removeCartItem(String cartId, String variantOrProductId) async {
    final uri = Uri.parse('$_baseUrl/carts/$cartId/items/$variantOrProductId');
    debugPrint('→ DELETE $uri');
    final resp = await _http.delete(uri);
    debugPrint('← ${resp.statusCode}');
    if (resp.statusCode != 204) {
      throw Exception('removeCartItem failed (${resp.statusCode})');
    }
  }

  // ───────────────────────────────────────────────
  // COUPONS
  // ───────────────────────────────────────────────

  Future<List<Coupon>> fetchAllCoupons() async {
    final uri = Uri.parse('$_baseUrl/coupons');
    debugPrint('→ GET $uri');
    final resp = await _http.get(uri);
    debugPrint('← ${resp.statusCode} ${resp.body}');
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as List<dynamic>;
      return data.map((e) => Coupon.fromJson(e)).toList();
    }
    throw Exception('fetchAllCoupons failed (${resp.statusCode})');
  }

  Future<Coupon> getCouponById(String id) async {
    final uri = Uri.parse('$_baseUrl/coupons/$id');
    debugPrint('→ GET $uri');
    final resp = await _http.get(uri);
    debugPrint('← ${resp.statusCode} ${resp.body}');
    if (resp.statusCode == 200) {
      return Coupon.fromJson(json.decode(resp.body));
    }
    throw Exception('getCouponById failed (${resp.statusCode})');
  }

  Future<Coupon> validateCoupon(String code) async {
    final uri = Uri.parse('$_baseUrl/coupons/validate/$code');
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      // Coupon hợp lệ, trả về Coupon object
      return Coupon.fromJson(json.decode(resp.body));
    } else if (resp.statusCode == 400 || resp.statusCode == 404) {
      // Coupon hết lượt hoặc không tồn tại
      throw Exception(json.decode(resp.body)["title"] ?? "Coupon không hợp lệ");
    } else {
      // Lỗi khác
      throw Exception('Có lỗi khi kiểm tra coupon (${resp.statusCode})');
    }
  }
  Future<Coupon> createCoupon(Coupon coupon) async {
    final uri = Uri.parse('$_baseUrl/coupons');
    final body = json.encode(coupon.toJson());
    debugPrint('→ POST $uri  body=$body');
    final resp = await _http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    debugPrint('← ${resp.statusCode} ${resp.body}');
    if (resp.statusCode == 201) {
      return Coupon.fromJson(json.decode(resp.body));
    }
    throw Exception('createCoupon failed (${resp.statusCode})');
  }

  Future<void> updateCoupon(Coupon coupon) async {
    final uri = Uri.parse('$_baseUrl/coupons/${coupon.id}');
    final body = json.encode(coupon.toJson());
    debugPrint('→ PUT $uri  body=$body');
    final resp = await _http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    debugPrint('← ${resp.statusCode}');
    if (resp.statusCode != 204) {
      throw Exception('updateCoupon failed (${resp.statusCode})');
    }
  }

  Future<void> deleteCoupon(String id) async {
    final uri = Uri.parse('$_baseUrl/coupons/$id');
    debugPrint('→ DELETE $uri');
    final resp = await _http.delete(uri);
    debugPrint('← ${resp.statusCode}');
    if (resp.statusCode != 204) {
      throw Exception('deleteCoupon failed (${resp.statusCode})');
    }
  }
  Future<Coupon> applyCoupon(String code, String orderId) async {
    final uri = Uri.parse('$_baseUrl/coupons/apply/$code?orderId=$orderId');
    final resp = await _http.post(uri);
    debugPrint('← ${resp.statusCode} ${resp.body}');
    if (resp.statusCode == 200) {
      return Coupon.fromJson(json.decode(resp.body));
    }
    throw Exception('applyCoupon failed (${resp.statusCode})');
  }

  // ───────────────────────────────────────────────
  // ORDERS
  // ───────────────────────────────────────────────

  static Future<List<Order>> fetchAllOrders() async {
    final uri = Uri.parse('$_baseUrl/Orders');
    debugPrint('→ GET $uri');
    final resp = await http.get(uri);
    debugPrint('← ${resp.statusCode} ${resp.body}');
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as List<dynamic>;
      return data.map((e) => Order.fromJson(e)).toList();
    }
    throw Exception('fetchAllOrders failed (${resp.statusCode})');
  }

  Future<Order> getOrderById(String id) async {
    final uri = Uri.parse('$_baseUrl/orders/$id');
    debugPrint('→ GET $uri');
    final resp = await _http.get(uri);
    debugPrint('← ${resp.statusCode} ${resp.body}');
    if (resp.statusCode == 200) {
      return Order.fromJson(json.decode(resp.body));
    }
    throw Exception('getOrderById failed (${resp.statusCode})');
  }
// Xóa toàn bộ items trong cart
  Future<void> clearCartOnServer(String cartId) async {
    final url = Uri.parse('$_cartUrl/$cartId/items');  // Đúng đường dẫn
    final resp = await http.delete(url);
    if (resp.statusCode != 204) {
      throw Exception('Không thể xóa cart trên server');
    }
  }

  Future<Order> createOrder(Order order) async {
    final url = Uri.parse('$_baseUrl/orders');
    final headers = {'Content-Type': 'application/json'};

    print('POST $url');
    print('Order JSON: ${jsonEncode(order.toJson())}');

    final resp = await http.post(
      url,
      headers: headers,
      body: jsonEncode(order.toJson()),
    );

    if (resp.statusCode == 201) {
      return Order.fromJson(jsonDecode(utf8.decode(resp.bodyBytes)));
    } else {
      print('Lỗi tạo đơn hàng: ${resp.statusCode} ${resp.body}');
      throw Exception('Tạo đơn hàng thất bại: ${resp.body}');
    }
  }

  // trong order_service.dart
  Future<Map<String, dynamic>> fetchProductInfo(String productId, String? variantId) async {
    final productUri = Uri.parse('https://productservice-production.up.railway.app/api/products/$productId');
    final resp = await http.get(productUri);
    if (resp.statusCode != 200) {
      throw Exception('Lỗi lấy sản phẩm $productId');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    final variants = (data['variants'] as List<dynamic>)
        .map((v) => v as Map<String, dynamic>)
        .toList();

    // Nếu không truyền variantId, chọn variant đầu tiên
    final variant = variants.firstWhere(
          (v) => v['id'] == variantId,
      orElse: () => variants.first,
    );

    // Lấy giá từ additionalPrice của variant
    final price = (variant['additionalPrice'] as num).toDouble();

    return {
      'productName': data['name'] as String,
      'variantName': variant['variantName'] as String? ?? '',
      'price': price,
    };
  }

  Future<Order> createOrderFromCart({
    required Cart cart,
    required ShippingAddress shippingAddress,
    Coupon? appliedCoupon,
    bool applyPoints = false,
  }) async {
    final List<OrderItem> orderItems = [];

    for (final item in cart.items) {
      final info = await fetchProductInfo(item.productId, item.productVariantId);
      orderItems.add(OrderItem(
        productId: item.productId,
        productVariantId: item.productVariantId,
        productName: info['productName'],
        variantName: info['variantName'],
        quantity: item.quantity,
        price: info['price'],
      ));
    }

    final subtotal = orderItems.fold<double>(
      0,
          (sum, i) => sum + i.price * i.quantity,
    );

    final discount = appliedCoupon?.discountValue?.toDouble() ?? 0.0;
    final shipping = 50000.0; // hardcoded or fetch from config
    final vat = 0.0;
    final total = subtotal + shipping + vat - discount;

    final order = Order(
      id: '',
      userId: cart.userId,
      orderNumber: const Uuid().v4(),
      shippingAddress: shippingAddress,
      items: orderItems,
      totalAmount: total,
      discountAmount: discount,
      couponCode: appliedCoupon?.code,
      loyaltyPointsUsed: applyPoints ? 100 : 0,
      status: 'pending',
      statusHistory: [
        OrderStatusHistory(status: 'pending', timestamp: DateTime.now()),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await createOrder(order);
  }


  Future<void> updateOrder(Order order) async {
    final uri = Uri.parse('$_baseUrl/orders/${order.id}');
    final body = json.encode(order.toJson());
    debugPrint('→ PUT $uri  body=$body');
    final resp = await _http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    debugPrint('← ${resp.statusCode}');
    if (resp.statusCode != 204) {
      throw Exception('updateOrder failed (${resp.statusCode})');
    }
  }

  Future<void> deleteOrder(String id) async {
    final uri = Uri.parse('$_baseUrl/orders/$id');
    debugPrint('→ DELETE $uri');
    final resp = await _http.delete(uri);
    debugPrint('← ${resp.statusCode}');
    if (resp.statusCode != 204) {
      throw Exception('deleteOrder failed (${resp.statusCode})');
    }
  }

  static Future<List<Order>> fetchOrdersByUserId(String userId) async {
    final uri = Uri.parse('https://orderservice-production-e536.up.railway.app.up.railway.app/api/orders/user/$userId');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as List<dynamic>;
      return data.map((e) => Order.fromJson(e)).toList();
    }
    throw Exception('fetchOrdersByUserId failed: ${resp.statusCode}');
  }

  Future<void> updateOrderStatus(String id, OrderStatusHistory history) async {
    final uri = Uri.parse('$_baseUrl/orders/$id/status');
    final body = json.encode(history.toJson());
    debugPrint('→ PATCH $uri  body=$body');
    final resp = await _http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    debugPrint('← ${resp.statusCode}');
    if (resp.statusCode != 204) {
      throw Exception('updateOrderStatus failed (${resp.statusCode})');
    }
  }
}