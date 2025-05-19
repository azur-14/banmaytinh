import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/Footer/mobile_navigation_bar.dart';
import 'package:danentang/models/Coupon.dart';
import 'package:danentang/Service/order_service.dart';

class CouponManagement extends StatelessWidget {
  const CouponManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveCouponScreen();
  }
}

class ResponsiveCouponScreen extends StatefulWidget {
  const ResponsiveCouponScreen({super.key});

  @override
  State<ResponsiveCouponScreen> createState() => _ResponsiveCouponScreenState();
}

class _ResponsiveCouponScreenState extends State<ResponsiveCouponScreen> {
  int _selectedIndex = 0;
  final _codeCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _couponService = OrderService.instance;
  late Future<List<Coupon>> _couponFuture;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refreshCoupons();
    _loadSelectedIndex();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    if (token == null || role != 'admin') {
      context.go('/login');
    }
  }

  Future<void> _loadSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedIndex = prefs.getInt('coupon_management_nav_index') ?? 0;
    });
  }

  Future<void> _saveSelectedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coupon_management_nav_index', index);
  }

  void _refreshCoupons() {
    setState(() {
      _couponFuture = _couponService.fetchAllCoupons();
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _saveSelectedIndex(index);
  }

  Future<void> _createCoupon() async {
    // Validate inputs
    final code = _codeCtrl.text.trim();
    final discount = int.tryParse(_discountCtrl.text.trim());
    final usageLimit = int.tryParse(_limitCtrl.text.trim());

    // Validation checks
    if (code.isEmpty || code.length < 5) {
      setState(() => _errorMessage = 'Mã giảm giá phải có ít nhất 5 ký tự');
      return;
    }

    if (discount == null || discount <= 0) {
      setState(() => _errorMessage = 'Giá trị giảm phải là số nguyên dương');
      return;
    }

    if (usageLimit == null || usageLimit <= 0 || usageLimit > 10) {
      setState(() => _errorMessage = 'Số lần sử dụng phải từ 1 đến 10');
      return;
    }


    // Check if code is unique
    try {
      final existingCoupons = await _couponFuture;
      if (existingCoupons.any((c) => c.code.toLowerCase() == code.toLowerCase())) {
        setState(() => _errorMessage = 'Mã giảm giá đã tồn tại');
        return;
      }

      // Create coupon
      final coupon = Coupon(
        code: code,
        discountValue: discount,
        usageLimit: usageLimit,
        usageCount: 0,
        createdAt: DateTime.now(),
        orderIds: [],
      );

      await _couponService.createCoupon(coupon);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo mã giảm giá thành công')),
      );

      // Clear inputs
      _codeCtrl.clear();
      _discountCtrl.clear();
      _limitCtrl.clear();
      setState(() => _errorMessage = null);
      _refreshCoupons();
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi: $e');
    }
  }

  void _clearForm() {
    _codeCtrl.clear();
    _discountCtrl.clear();
    _limitCtrl.clear();
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          context.go('/manager'); // Quay lại dashboard
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.maxWidth < 600
              ? MobileCouponScreen(
            onBackPressed: () => context.go('/manager'),
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
            isLoggedIn: true,
            couponFuture: _couponFuture,
            codeCtrl: _codeCtrl,
            discountCtrl: _discountCtrl,
            limitCtrl: _limitCtrl,
            onCreateCoupon: _createCoupon,
            onClearForm: _clearForm,
            errorMessage: _errorMessage,
          )
              : WebCouponScreen(
            couponFuture: _couponFuture,
            codeCtrl: _codeCtrl,
            discountCtrl: _discountCtrl,
            limitCtrl: _limitCtrl,
            onCreateCoupon: _createCoupon,
            onClearForm: _clearForm,
            errorMessage: _errorMessage,
          );
        },
      ),
    );
  }
}

class MobileCouponScreen extends StatelessWidget {
  final VoidCallback onBackPressed;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final bool isLoggedIn;
  final Future<List<Coupon>> couponFuture;
  final TextEditingController codeCtrl, discountCtrl, limitCtrl;
  final VoidCallback onCreateCoupon;
  final VoidCallback onClearForm;
  final String? errorMessage;

  const MobileCouponScreen({
    super.key,
    required this.onBackPressed,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.isLoggedIn,
    required this.couponFuture,
    required this.codeCtrl,
    required this.discountCtrl,
    required this.limitCtrl,
    required this.onCreateCoupon,
    required this.onClearForm,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: onBackPressed,
        ),
        title: const Text(
          "Quản lý mã giảm giá",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => context.findAncestorStateOfType<_ResponsiveCouponScreenState>()?._refreshCoupons(),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: CouponContent(
        couponFuture: couponFuture,
        codeCtrl: codeCtrl,
        discountCtrl: discountCtrl,
        limitCtrl: limitCtrl,
        onCreateCoupon: onCreateCoupon,
        onClearForm: onClearForm,
        errorMessage: errorMessage,
      ),
      bottomNavigationBar: MobileNavigationBar(
        selectedIndex: selectedIndex,
        onItemTapped: onItemTapped,
        isLoggedIn: isLoggedIn,
        role: 'admin',
      ),
    );
  }
}

class WebCouponScreen extends StatelessWidget {
  final Future<List<Coupon>> couponFuture;
  final TextEditingController codeCtrl, discountCtrl, limitCtrl;
  final VoidCallback onCreateCoupon;
  final VoidCallback onClearForm;
  final String? errorMessage;

  const WebCouponScreen({
    super.key,
    required this.couponFuture,
    required this.codeCtrl,
    required this.discountCtrl,
    required this.limitCtrl,
    required this.onCreateCoupon,
    required this.onClearForm,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Quản lý mã giảm giá",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => context.findAncestorStateOfType<_ResponsiveCouponScreenState>()?._refreshCoupons(),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          width: 800,
          child: CouponContent(
            couponFuture: couponFuture,
            codeCtrl: codeCtrl,
            discountCtrl: discountCtrl,
            limitCtrl: limitCtrl,
            onCreateCoupon: onCreateCoupon,
            onClearForm: onClearForm,
            errorMessage: errorMessage,
          ),
        ),
      ),
    );
  }
}

class CouponContent extends StatelessWidget {
  final Future<List<Coupon>> couponFuture;
  final TextEditingController codeCtrl, discountCtrl, limitCtrl;
  final VoidCallback onCreateCoupon;
  final VoidCallback onClearForm;
  final String? errorMessage;

  const CouponContent({
    super.key,
    required this.couponFuture,
    required this.codeCtrl,
    required this.discountCtrl,
    required this.limitCtrl,
    required this.onCreateCoupon,
    required this.onClearForm,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Danh sách mã giảm giá", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        FutureBuilder<List<Coupon>>(
          future: couponFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Lỗi: ${snapshot.error}"),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.findAncestorStateOfType<_ResponsiveCouponScreenState>()?._refreshCoupons(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }
            final coupons = snapshot.data!;
            if (coupons.isEmpty) {
              return const Text("Chưa có mã giảm giá.");
            }
            return Column(
              children: coupons.map((c) => _buildCouponItem(context, c)).toList(),
            );
          },
        ),
        const Divider(height: 32),
        const Text("Tạo mã giảm giá mới", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (errorMessage != null) ...[
          Text(
            errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: codeCtrl,
          decoration: const InputDecoration(
            labelText: 'Mã giảm giá (ít nhất 5 ký tự)',
            border: OutlineInputBorder(),
            errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
            focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
          ),
          maxLength: 20,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: discountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Giá trị giảm (VND, số nguyên dương)',
            border: OutlineInputBorder(),
            errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
            focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: limitCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Số lần sử dụng (1-10)',
            border: OutlineInputBorder(),
            errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
            focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onCreateCoupon,
              child: const Text("Tạo mã giảm giá"),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: onClearForm,
              child: const Text("Xóa dữ liệu"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCouponItem(BuildContext context, Coupon c) {
    final percentUsed = (c.usageCount / c.usageLimit * 100).clamp(0, 100).round();
    final isExhausted = c.usageCount >= c.usageLimit; // Check if coupon is exhausted

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: isExhausted ? Colors.grey.shade400 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: isExhausted ? Colors.grey.shade100 : Colors.white, // Grey background if exhausted
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(
            Icons.card_giftcard,
            color: isExhausted ? Colors.grey : Colors.purple, // Grey icon if exhausted
            size: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mã: ${c.code}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isExhausted ? Colors.grey.shade600 : Colors.black,
                  ),
                ),
                Text(
                  "Giảm: ${c.discountValue}đ",
                  style: TextStyle(
                    color: isExhausted ? Colors.grey.shade600 : Colors.black,
                  ),
                ),
                Text(
                  "Đã dùng: ${c.usageCount}/${c.usageLimit} (${percentUsed}%)",
                  style: TextStyle(
                    color: isExhausted ? Colors.grey.shade600 : Colors.black,
                  ),
                ),
                if (c.orderIds.isNotEmpty)
                  Text(
                    "Đơn đã dùng: ${c.orderIds.join(', ')}",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
              ],
            ),
          ),
          Tooltip(
            message: isExhausted ? 'Mã đã hết lượt sử dụng' : 'Xóa mã giảm giá',
            child: IconButton(
              icon: Icon(
                Icons.delete,
                color: isExhausted ? Colors.grey : Colors.red, // Grey icon if exhausted
              ),
              onPressed: isExhausted
                  ? null // Disable button if exhausted
                  : () async {
                final confirmed = await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Xác nhận xóa"),
                    content: Text("Bạn có chắc muốn xóa mã '${c.code}' không?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Hủy"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Xóa"),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await OrderService.instance.deleteCoupon(c.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã xóa mã")),
                  );
                  // Refresh coupons after deletion
                  context
                      .findAncestorStateOfType<_ResponsiveCouponScreenState>()
                      ?._refreshCoupons();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}