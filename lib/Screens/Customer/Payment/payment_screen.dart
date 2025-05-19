import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:danentang/models/OrderItem.dart';
import 'package:danentang/models/ShippingAddress.dart';
import 'package:danentang/widgets/Header/web_header.dart';
import 'package:danentang/models/Coupon.dart';
import 'package:danentang/models/User.dart';
import 'package:danentang/models/Address.dart';
import 'package:danentang/Service/user_service.dart';
import 'package:uuid/uuid.dart';

import '../../../Service/order_service.dart';
import '../../../models/Order.dart';
import 'address_selection_screen.dart';
import 'order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> products; // mỗi item: {'product', 'variant', 'quantity'}
  final Coupon? voucher;
  final int loyaltyPointsToUse;

  const PaymentScreen({
    Key? key,
    required this.products,
    this.voucher,
    this.loyaltyPointsToUse = 0,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Biến cho guest (customer chưa đăng nhập)
  String guestName = '';
  String guestPhone = '';
  String guestAddress = '';
  String guestWard = '';
  String guestDistrict = '';
  String guestCity = '';
  String guestEmail = '';
  bool _isLoading = false;
  // Biến cho user đã login
  bool isLoggedIn = false;
  User? user;
  Address? shippingAddress;
  String? email;
  Address? selectedAddress;  // Địa chỉ đang chọn
  List<Address> addressList = []; // Danh sách tất cả địa chỉ

  @override
  void initState() {
    super.initState();
    _initUserAndAddress();
  }
  Future<void> _clearCartAfterOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString('cartId');
    if (cartId != null) {
      try {
        await OrderService.instance.clearCartOnServer(cartId);
      } catch (e) {
        print('Lỗi khi xóa cart trên server: $e');
      }
      await prefs.remove('cartId');
    }
  }

  Future<void> _initUserAndAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    email = prefs.getString('email');
    if (token != null && email != null) {
      try {
        final u = await UserService().fetchUserByEmail(email!);
        setState(() {
          isLoggedIn = true;
          user = u;
          if (u.addresses.isNotEmpty) {
            shippingAddress = u.addresses.firstWhere(
                  (a) => a.isDefault,
              orElse: () => u.addresses.first,
            );
          }
        });
      } catch (_) {
        setState(() {
          isLoggedIn = false;
          email = null;
        });
      }
    } else {
      setState(() {
        isLoggedIn = false;
        email = null;
      });
    }
  }

  double get shippingFee => 30000;

  double get subtotal => widget.products.fold<double>(
      0,
          (sum, item) => sum + (item['variant'].additionalPrice * item['quantity'])
  );

  double get voucherDiscount {
    if (widget.voucher == null) return 0.0;
    if (widget.voucher!.discountValue != null) {
      final value = widget.voucher!.discountValue!;
      if (value < 1) {
        return subtotal * value;
      } else {
        return value.toDouble();
      }
    }
    return 0.0;
  }

  double get loyaltyDiscount => (widget.loyaltyPointsToUse * 1000).toDouble();

  double get total => subtotal + shippingFee - voucherDiscount - loyaltyDiscount;

  void _placeOrder() async {
    setState(() => _isLoading = true);

    String? guestUserId;

    // 1. Xác thực thông tin
    if (!isLoggedIn) {
      // Kiểm tra dữ liệu nhập
      if (guestName.isEmpty || guestPhone.isEmpty || guestAddress.isEmpty ||
          guestWard.isEmpty || guestDistrict.isEmpty || guestCity.isEmpty ||
          guestEmail.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin giao hàng')),
        );
        return;
      }
      // 2. Xử lý tài khoản guest (QUAN TRỌNG)
      final guestUser = await _handleGuestUserByEmail(guestEmail);
      if (guestUser == null) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Email đã đăng ký!'),
            content: Text('Email này đã đăng ký tài khoản và đã xác thực. Vui lòng đăng nhập để tiếp tục mua hàng.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      guestUserId = guestUser.id;
    } else {
      if (shippingAddress == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng chọn địa chỉ giao hàng')),
        );
        return;
      }
    }

    // 3. Chuẩn bị địa chỉ giao hàng
    final shippingAddr = isLoggedIn
        ? ShippingAddress(
      receiverName: shippingAddress!.receiverName,
      phoneNumber: shippingAddress!.phone,
      addressLine: shippingAddress!.addressLine,
      ward: shippingAddress!.commune ?? '',
      district: shippingAddress!.district ?? '',
      city: shippingAddress!.city ?? '',
      email: email ?? '',
    )
        : ShippingAddress(
      receiverName: guestName,
      phoneNumber: guestPhone,
      addressLine: guestAddress,
      ward: guestWard,
      district: guestDistrict,
      city: guestCity,
      email: guestEmail,
    );

    // 4. Chuẩn bị danh sách sản phẩm
    final List<OrderItem> orderItems = widget.products.map((item) {
      final product = item['product'];
      final variant = item['variant'];
      final qty = item['quantity'] as int;
      return OrderItem(
        productId: product.id ?? '',
        productVariantId: variant.id ?? '',
        productName: product.name,
        variantName: variant.variantName,
        quantity: qty,
        price: variant.additionalPrice,
      );
    }).toList();

    // 5. Tạo Order
    final order = Order(
      id: '',
      userId: isLoggedIn ? (user?.id ?? '') : guestUserId,
      orderNumber: '',
      shippingAddress: shippingAddr,
      items: orderItems,
      totalAmount: subtotal + shippingFee,
      discountAmount: voucherDiscount + loyaltyDiscount,
      couponCode: widget.voucher?.code,
      loyaltyPointsUsed: widget.loyaltyPointsToUse,
      loyaltyPointsEarned: 0,
      status: 'pending',
      statusHistory: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      print('Order gửi lên: ${order.toJson()}');
      var createdOrder = await OrderService.instance.createOrder(order);

      // 6. Xóa cart sau khi đặt hàng
      await _clearCartAfterOrder();
      setState(() => _isLoading = false);
// Lấy id để truyền sang màn success:
      final orderId = createdOrder.id; // Đảm bảo là String, không nullable
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(orderId: orderId),
        ),
      );



    } catch (e) {
      setState(() => _isLoading = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Lỗi đặt hàng'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  Future<User> _handleGuestUserByEmail(String email) async {
    try {
      // 1. Thử fetch user theo email
      final user = await UserService().fetchUserByEmail(email);

      // 2. Nếu user đã tồn tại và là guest (isVerifiedMail == false), return luôn
      if (user.isEmailVerified == false) {
        return user;
      }

      // 3. Nếu user đã tồn tại nhưng là user chính thức, có thể báo lỗi hoặc xử lý khác
      throw Exception('Email đã được đăng ký chính thức, vui lòng đăng nhập.');

    } catch (e) {
      // 4. Nếu fetch thất bại (user chưa tồn tại), tiến hành tạo guest user
      await UserService().registerGuest(email: email);

      // 5. Sau khi tạo xong, fetch lại user để lấy dữ liệu mới
      return await UserService().fetchUserByEmail(email);
    }
  }
  Future<void> _selectAddress() async {
    if (user == null) return;
    final selected = await Navigator.push<Address>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressSelectionScreen(user: user!),
      ),
    );
    if (selected != null) {
      setState(() {
        shippingAddress = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isWeb
          ? null
          : AppBar(
        title: const Text('Thanh toán',
            style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            constraints: BoxConstraints(maxWidth: isWeb ? 700 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWeb) ...[
                  WebHeader(isLoggedIn: isLoggedIn),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Địa chỉ giao hàng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                if (isLoggedIn && shippingAddress != null)
                  Card(
                    child: ListTile(
                      title: Text(shippingAddress!.receiverName),
                      subtitle: Text(
                        '${shippingAddress!.addressLine}'
                            '${shippingAddress!.commune != null ? ', ${shippingAddress!.commune}' : ''}'
                            '${shippingAddress!.district != null ? ', ${shippingAddress!.district}' : ''}'
                            '${shippingAddress!.city != null ? ', ${shippingAddress!.city}' : ''}'
                            '${email != null ? '\nEmail: $email' : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Chọn địa chỉ khác',
                            onPressed: _selectAddress,
                          ),
                        ],
                      ),
                    ),
                  )

                else ...[
                  TextField(
                    decoration: InputDecoration(labelText: 'Tên người nhận'),
                    onChanged: (v) => setState(() => guestName = v),
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Số điện thoại'),
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => setState(() => guestPhone = v),
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Địa chỉ (số nhà, tên đường)'),
                    onChanged: (v) => setState(() => guestAddress = v),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(labelText: 'Phường/Xã'),
                          onChanged: (v) => setState(() => guestWard = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(labelText: 'Quận/Huyện'),
                          onChanged: (v) => setState(() => guestDistrict = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(labelText: 'Thành phố/Tỉnh'),
                    onChanged: (v) => setState(() => guestCity = v),
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (v) => setState(() => guestEmail = v),
                  ),
                ],
                const SizedBox(height: 20),
                Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                ...widget.products.map((item) {
                  final product = item['product'];
                  final variant = item['variant'];
                  final qty = item['quantity'];
                  return ListTile(
                    leading: Icon(Icons.shopping_bag),
                    title: Text(product.name),
                    subtitle: Text('Biến thể: ${variant.variantName}\nSố lượng: $qty'),
                    trailing: Text('${(variant.additionalPrice * qty).toStringAsFixed(0)}đ'),
                  );
                }).toList(),
                Divider(),
                ListTile(
                  title: Text('Tạm tính'), trailing: Text('${subtotal.toStringAsFixed(0)}đ'),
                ),
                ListTile(
                  title: Text('Voucher'),
                  trailing: Text('-${voucherDiscount.toStringAsFixed(0)}đ'),
                ),
                ListTile(
                  title: Text('Điểm thưởng sử dụng'),
                  trailing: Text('-${loyaltyDiscount.toStringAsFixed(0)}đ'),
                ),
                ListTile(
                  title: Text('Phí vận chuyển'), trailing: Text('${shippingFee.toStringAsFixed(0)}đ'),
                ),
                Divider(),
                ListTile(
                  title: Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text('${total.toStringAsFixed(0)}đ', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF5A4FCF),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _isLoading ? null : _placeOrder,   // ← disabled khi loading
                    child: _isLoading
                        ? SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : Text('ĐẶT HÀNG', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
