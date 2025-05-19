import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:danentang/models/CartItem.dart';
import 'package:danentang/models/Cart.dart';
import 'package:danentang/models/product.dart';
import 'package:danentang/models/User.dart';
import 'package:danentang/models/Coupon.dart';
import 'package:danentang/Service/order_service.dart';
import 'package:danentang/Service/product_service.dart';
import 'package:danentang/Service/user_service.dart';
import 'package:danentang/widgets/Cart_CheckOut/cart_item_widget.dart';
import 'package:danentang/widgets/Cart_CheckOut/order_summary_widget.dart';
import 'package:danentang/widgets/Header/web_header.dart';
import 'package:danentang/widgets/Search/web_search_bar.dart';
import 'package:danentang/constants/colors.dart';

import '../Payment/payment_screen.dart';

class CartScreenCheckOut extends StatefulWidget {
  const CartScreenCheckOut({Key? key}) : super(key: key);

  @override
  _CartScreenCheckOutState createState() => _CartScreenCheckOutState();
}

class _CartScreenCheckOutState extends State<CartScreenCheckOut> {
  final OrderService _api = OrderService.instance;
  Future<Cart>? _cartFuture;
  late String _effectiveCartId;
  bool isEditing = false;
  final Set<String> _selectedItemIds = {};
  bool _selectAll = false;

  // Coupon & loyalty logic
  Coupon? _appliedCoupon;
  String? _errorCoupon;
  int _couponDiscountAmount = 0;
  bool _applyingCoupon = false;
  int _loyaltyPointsToUse = 0;
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _loyaltyController = TextEditingController();

  User? _currentUser;
  Map<String, Product> _productsById = {};

  @override
  void initState() {
    super.initState();
    _loadUserAndCart();
  }

  Future<void> _loadUserAndCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final email = prefs.getString('email');

    Cart cart;

    try {
      if (email != null && token != null) {
        final user = await UserService().fetchUserByEmail(email);
        setState(() => _currentUser = user);

        cart = await _api.fetchCartByUserId(user.id!);
        _effectiveCartId = cart.id;

        await prefs.setString('cartId', cart.id);
      } else {
        String? cartId = prefs.getString('cartId');
        if (cartId == null) {
          final newCart = await _api.createCart('');
          cartId = newCart.id;
          await prefs.setString('cartId', cartId);
        }

        _effectiveCartId = cartId!;
        cart = await _api.fetchCart(_effectiveCartId);
        setState(() => _currentUser = null);
      }

      final ids = cart.items.map((i) => i.productId).toSet().toList();
      final products = await Future.wait(ids.map((id) => ProductService.getById(id)));
      _productsById = {for (var p in products) p.id: p};

      setState(() {
        _cartFuture = Future.value(cart);
        _selectedItemIds.clear();
        _selectAll = false;
      });
    } catch (e) {
      debugPrint('❌ Lỗi khi load giỏ hàng: $e');
      setState(() {
        _cartFuture = Future.error('Không thể tải giỏ hàng');
      });
    }
  }

  Future<void> _refresh() async {
    await _loadUserAndCart();
  }

  Future<void> _deleteSelectedItems(Cart cart) async {
    try {
      for (final id in _selectedItemIds) {
        await _api.removeCartItem(cart.id, id);
      }
      setState(() {
        _selectedItemIds.clear();
        _selectAll = false;
      });
      await _refresh();
    } catch (e) {
      debugPrint('❌ Lỗi khi xóa các mục đã chọn: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi xóa các mục đã chọn')),
      );
    }
  }

  void _toggleSelectAll(bool? value, Cart cart) {
    setState(() {
      _selectAll = value ?? false;
      _selectedItemIds.clear();
      if (_selectAll) {
        _selectedItemIds.addAll(cart.items.map((item) => item.productVariantId ?? item.productId));
      }
    });
  }

  Future<double> _calculateSubtotal(List<CartItem> items) async {
    double subtotal = 0.0;
    for (final item in items) {
      final product = _productsById[item.productId];
      final variant = product?.variants.firstWhere(
            (v) => v.id == item.productVariantId,
        orElse: () => product!.variants.first,
      );
      subtotal += (variant?.additionalPrice ?? 0) * item.quantity;
    }
    return subtotal;
  }

  Future<void> _applyCoupon() async {
    final code = _discountController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _applyingCoupon = true;
      _errorCoupon = null;
    });
    try {
      final coupon = await OrderService.instance.validateCoupon(code);
      final cart = await _cartFuture!;
      final subtotal = await _calculateSubtotal(cart.items);

      if (coupon.discountValue > subtotal) {
        setState(() {
          _appliedCoupon = null;
          _couponDiscountAmount = 0;
          _errorCoupon = "Giá trị giảm giá lớn hơn giá trị đơn hàng. Không thể áp dụng!";
        });
      } else {
        setState(() {
          _appliedCoupon = coupon;
          _couponDiscountAmount = coupon.discountValue;
          _errorCoupon = null;
        });
      }
    } catch (e) {
      setState(() {
        _appliedCoupon = null;
        _couponDiscountAmount = 0;
        _errorCoupon = "Mã giảm giá không hợp lệ hoặc đã hết lượt sử dụng";
      });
    } finally {
      setState(() => _applyingCoupon = false);
    }
  }

  void _onLoyaltyChanged(String v) {
    final maxPoints = _currentUser?.loyaltyPoints ?? 0;
    final pts = int.tryParse(v) ?? 0;
    setState(() {
      _loyaltyPointsToUse = (pts > maxPoints) ? maxPoints : pts;
      _loyaltyController.text = _loyaltyPointsToUse.toString();
    });
  }

  double get _discount {
    return (_couponDiscountAmount) + (_loyaltyPointsToUse * 1000);
  }

  double get _shipping => 30000;
  double get _vat => 0;

  void _onCheckout(Cart cart) async {
    final List<Map<String, dynamic>> products = cart.items.map((item) {
      final product = _productsById[item.productId];
      final variant = product?.variants.firstWhere(
            (v) => v.id == item.productVariantId,
        orElse: () => product!.variants.first,
      );
      return {
        'product': product!,
        'quantity': item.quantity,
        'variant': variant,
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          products: products,
          voucher: _appliedCoupon,
          loyaltyPointsToUse: _loyaltyPointsToUse,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cartFuture == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final width = MediaQuery.of(context).size.width;
    return width > 800 ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        leading: BackButton(onPressed: () => context.go('/homepage')),
        actions: [
          TextButton(
            onPressed: () => setState(() => isEditing = !isEditing),
            child: Text(
              isEditing ? 'Done' : 'Edit',
              style: TextStyle(color: AppColors.hexToColor(AppColors.black)),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.hexToColor('#F5F5F5'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) => SingleChildScrollView(
                controller: scrollController,
                child: FutureBuilder<Cart>(
                  future: _cartFuture!,
                  builder: (ctx, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    final cart = snap.data!;
                    return FutureBuilder<double>(
                      future: _calculateSubtotal(cart.items),
                      builder: (context, subSnap) {
                        if (!subSnap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final subtotal = subSnap.data!;
                        final total = subtotal + _shipping + _vat - _discount;
                        return OrderSummaryWidget(
                          subtotal: subtotal,
                          vat: _vat,
                          shipping: _shipping,
                          discount: _discount,
                          total: total,
                          discountController: _discountController,
                          onApplyCoupon: _applyCoupon,
                          applyingCoupon: _applyingCoupon,
                          errorCoupon: _errorCoupon,
                          loyaltyPointsAvailable: _currentUser?.loyaltyPoints ?? 0,
                          loyaltyPointsToUse: _loyaltyPointsToUse,
                          loyaltyController: _loyaltyController,
                          onLoyaltyChanged: _onLoyaltyChanged,
                          onCheckout: () => _onCheckout(cart),
                          couponDiscountValue: _couponDiscountAmount,
                          couponApplied: _appliedCoupon != null,
                          onRemoveCoupon: () {
                            setState(() {
                              _appliedCoupon = null;
                              _couponDiscountAmount = 0;
                              _discountController.clear();
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
        backgroundColor: AppColors.hexToColor(AppColors.purple),
        label: const Text(
          'Xem tóm tắt đơn hàng',
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.receipt_long, color: Colors.white),
      ),
      body: FutureBuilder<Cart>(
        future: _cartFuture!,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final cart = snap.data!;
          return Column(
            children: [
              if (cart.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _selectAll,
                            onChanged: (value) => _toggleSelectAll(value, cart),
                            activeColor: const Color(0xFF2E2E2E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Chọn Tất Cả',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      Visibility(
                        visible: _selectedItemIds.isNotEmpty,
                        child: ElevatedButton(
                          onPressed: () => _deleteSelectedItems(cart),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E2E2E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Xóa Tất Cả Đã Chọn',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (_, i) {
                    final item = cart.items[i];
                    final product = _productsById[item.productId];
                    final variants = product?.variants ?? [];
                    return CartItemWidget(
                      item: item,
                      product: product!,
                      isEditing: isEditing,
                      variants: variants,
                      onVariantChanged: (String? newVariantId) async {
                        if (newVariantId == null) return;
                        await _api.upsertCartItem(
                          cart.id,
                          CartItem(
                            productId: item.productId,
                            productVariantId: newVariantId,
                            quantity: item.quantity,
                          ),
                        );
                        await _refresh();
                      },
                      onDelete: () async {
                        final idToRemove = item.productVariantId ?? item.productId;
                        await _api.removeCartItem(cart.id, idToRemove);
                        await _refresh();
                      },
                      onQuantityChanged: (qty) async {
                        await _api.upsertCartItem(
                          cart.id,
                          CartItem(
                            productId: item.productId,
                            productVariantId: item.productVariantId,
                            quantity: qty,
                          ),
                        );
                        await _refresh();
                      },
                      isMobile: true,
                      onSelectionChanged: (selected) {
                        setState(() {
                          final itemId = item.productVariantId ?? item.productId;
                          if (selected) {
                            _selectedItemIds.add(itemId);
                          } else {
                            _selectedItemIds.remove(itemId);
                          }
                          _selectAll = _selectedItemIds.length == cart.items.length;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: WebHeader(isLoggedIn: _currentUser != null),
      ),
      body: Column(
        children: [
          WebSearchBar(isLoggedIn: _currentUser != null),
          Expanded(
            child: FutureBuilder<Cart>(
              future: _cartFuture,
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final cart = snap.data!;
                return FutureBuilder<double>(
                  future: _calculateSubtotal(cart.items),
                  builder: (context, subSnap) {
                    if (!subSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final subtotal = subSnap.data!;
                    final total = subtotal + _shipping + _vat - _discount;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (cart.items.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _selectAll,
                                              onChanged: (value) => _toggleSelectAll(value, cart),
                                              activeColor: const Color(0xFF2E2E2E),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Chọn Tất Cả',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF333333),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Visibility(
                                          visible: _selectedItemIds.isNotEmpty,
                                          child: ElevatedButton(
                                            onPressed: () => _deleteSelectedItems(cart),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF2E2E2E),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: const Text(
                                              'Xóa Tất Cả Đã Chọn',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: cart.items.length,
                                    itemBuilder: (_, i) {
                                      final item = cart.items[i];
                                      final product = _productsById[item.productId];
                                      final variants = product?.variants ?? [];
                                      return CartItemWidget(
                                        item: item,
                                        product: product!,
                                        isEditing: isEditing,
                                        variants: variants,
                                        onVariantChanged: (String? newVariantId) async {
                                          if (newVariantId == null) return;
                                          await _api.upsertCartItem(
                                            cart.id,
                                            CartItem(
                                              productId: item.productId,
                                              productVariantId: newVariantId,
                                              quantity: item.quantity,
                                            ),
                                          );
                                          await _refresh();
                                        },
                                        onDelete: () async {
                                          final idToRemove = item.productVariantId ?? item.productId;
                                          await _api.removeCartItem(cart.id, idToRemove);
                                          await _refresh();
                                        },
                                        onQuantityChanged: (qty) async {
                                          await _api.upsertCartItem(
                                            cart.id,
                                            CartItem(
                                              productId: item.productId,
                                              productVariantId: item.productVariantId,
                                              quantity: qty,
                                            ),
                                          );
                                          await _refresh();
                                        },
                                        isMobile: false,
                                        onSelectionChanged: (selected) {
                                          setState(() {
                                            final itemId = item.productVariantId ?? item.productId;
                                            if (selected) {
                                              _selectedItemIds.add(itemId);
                                            } else {
                                              _selectedItemIds.remove(itemId);
                                            }
                                            _selectAll = _selectedItemIds.length == cart.items.length;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 2,
                            child: OrderSummaryWidget(
                              subtotal: subtotal,
                              vat: _vat,
                              shipping: _shipping,
                              discount: _discount,
                              total: total,
                              discountController: _discountController,
                              onApplyCoupon: _applyCoupon,
                              applyingCoupon: _applyingCoupon,
                              errorCoupon: _errorCoupon,
                              loyaltyPointsAvailable: _currentUser?.loyaltyPoints ?? 0,
                              loyaltyPointsToUse: _loyaltyPointsToUse,
                              loyaltyController: _loyaltyController,
                              onLoyaltyChanged: _onLoyaltyChanged,
                              onCheckout: () => _onCheckout(cart),
                              couponDiscountValue: _couponDiscountAmount,
                              couponApplied: _appliedCoupon != null,
                              onRemoveCoupon: () {
                                setState(() {
                                  _appliedCoupon = null;
                                  _couponDiscountAmount = 0;
                                  _discountController.clear();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}