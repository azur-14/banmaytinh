import 'package:danentang/Screens/Manager/Order/order_detail_screen.dart';
import 'package:danentang/Screens/Manager/Product/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens - Customer
import 'package:danentang/Screens/Customer/Home/home_screen.dart';
import 'package:danentang/Screens/Customer/Home/product_list_screen.dart';
import 'package:danentang/Screens/Customer/Home/sentiment_screen.dart';
import 'package:danentang/Screens/Customer/CheckOut/cart_screen.dart';
import 'package:danentang/Screens/Customer/Login/Login_Screen.dart';
import 'package:danentang/Screens/Customer/Login/Login_SignUp_Screen.dart';
import 'package:danentang/Screens/Customer/Login/SignUp.dart';
import 'package:danentang/Screens/Customer/Login/ChangePassword.dart';
import 'package:danentang/Screens/Customer/Login/Intro.dart';
import 'package:danentang/Screens/Customer/Search/search_v2.dart';
import 'package:danentang/Screens/Customer/User/profile_page.dart';
import 'package:danentang/Screens/Customer/User/personal_info_screen.dart';
import 'package:danentang/Screens/Customer/User/account_settings_screen.dart';
import 'package:danentang/Screens/Customer/Order/MyOrdersScreen.dart';
import 'package:danentang/Screens/Customer/Order/OrderDetailsScreen.dart';
import 'package:danentang/Screens/Customer/Payment/order_success_screen.dart';
import 'package:danentang/Screens/Customer/Payment/payment_method_screen.dart';
import 'package:danentang/Screens/Customer/Payment/add_card_screen.dart';

// Screens - Manager
import 'package:danentang/Screens/Manager/DashBoard/MobileDashboard.dart';
import 'package:danentang/Screens/Manager/DashBoard/WebDashboard.dart';
import 'package:danentang/Screens/Manager/Support/customer_support.dart';
import 'package:danentang/Screens/Manager/Support/customer_service.dart';
import 'package:danentang/Screens/Manager/User/user_list.dart';
import 'package:danentang/Screens/Manager/Product/product_management.dart';
import 'package:danentang/Screens/Manager/Product/add_product.dart';
import 'package:danentang/Screens/Manager/Product/delete_product.dart';
import 'package:danentang/Screens/Manager/Coupon/coupon_management.dart';
import 'package:danentang/Screens/Manager/Category/categories_management.dart';
import 'package:danentang/Screens/Manager/Order/order_list.dart';
import 'package:danentang/Screens/Manager/Report/oders_report.dart';
import 'package:danentang/Screens/Manager/Report/revenue_report.dart';
import 'package:danentang/Screens/Manager/Report/user_report.dart';
import 'package:danentang/Screens/Manager/Order/order_detail_screen.dart';

// Models & Data
import 'package:danentang/models/product.dart';
import 'package:danentang/models/card_info.dart';
import 'package:danentang/models/ship.dart';
import 'package:danentang/models/voucher.dart';
import 'package:danentang/models/Address.dart';
import 'package:danentang/models/Order.dart';
import 'Screens/Customer/Product/ProductCatalogPage.dart';
import 'Screens/Customer/Product/test_product_details.dart';
import 'Screens/Customer/User/change_password.dart';

final GoRouter router = GoRouter(
  initialLocation: '/homepage',
  routes: [

    /// Splash / Intro
    GoRoute(
      path: '/intro',
      builder: (context, state) => const SplashScreen(),
    ),

    /// Home
    GoRoute(
      path: '/homepage',
      builder: (context, state) => const HomeScreen(),
    ),

    /// Login / Sign-Up
    GoRoute(
      path: '/login',
      name: 'login', // thêm name nếu muốn xài goNamed
      builder: (context, state) {
        final email = state.extra as String? ?? '';
        return LoginScreen(email: email);
      },
    ),
    GoRoute(
      path: '/login-signup',
      builder: (context, state) => const LoginSignupScreen(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',    // nếu bạn muốn dùng goNamed
      builder: (context, state) {
        final email = state.extra as String? ?? '';
        return Signup(email: email);
      },
    ),

    GoRoute(
      path: '/change_password',
      builder: (context, state) {
        final email = state.extra as String? ?? '';
        return ForgotPasswordScreen(email: email);
      },
    ),

    GoRoute(
      path: '/search',
      builder: (context, state) => const Searching(),
    ),

    GoRoute(
      path: '/sentiment',
      builder: (context, state) => const SentimentScreen(),
    ),

    /// Product listing & details
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductListScreen(
        title: 'All Products',
        products: [],
        isWeb: false,
      ),
    ),
    GoRoute(
      path: '/products/:title',
      builder: (context, state) {
        final title = state.pathParameters['title']!;
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ProductListScreen(
          title: title,
          products: extra['products'] as List<Product>? ?? [],
          isWeb: extra['isWeb'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      name: 'product',
      path: '/product/:id',
      builder: (ctx, state) {
        final id = state.pathParameters['id']!;
        return ProductDetailScreen(productId: id);
      },
    ),

    /// Cart / Checkout
    GoRoute(
      path: '/checkout',
      builder: (context, state) {
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final prefs = snap.data!;
            final token = prefs.getString('token');
            final isLoggedIn = token != null;
            final userId = isLoggedIn ? prefs.getString('userId') : null;
            return CartScreenCheckOut();
          },
        );
      },
    ),

    /// Payment Flow
    GoRoute(
      path: '/payment-method',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PaymentMethodScreen(
          initialPaymentMethod: extra?['initialPaymentMethod'] ?? 'Credit Card',
          initialCard: extra?['initialCard'] as CardInfo?,
          cards: extra?['cards'] as List<CardInfo>? ?? [],
        );
      },
    ),
    GoRoute(
      path: '/add-card',
      builder: (context, state) => const AddCardScreen(),
    ),
    GoRoute(
      path: '/order-success/:id',
      builder: (context, state) {
        final orderId = state.pathParameters['id']!;
        return OrderSuccessScreen(orderId: orderId);
      },
    ),


    GoRoute(
      path: '/chat',
      builder: (context, state) => const CustomerServiceScreen(), // customer
    ),
    // Thêm route cho ChangePasswordScreen
    GoRoute(
      path: '/password-change',
      builder: (ctx, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/chat/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'];
        return CustomerServiceScreen(userId: userId); // admin
      },
    ),

    /// Orders
    GoRoute(
      path: '/my-orders',
      builder: (context, state) => const MyOrdersScreen(),
    ),

    GoRoute(
      path: '/order-details/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return OrderDetailsScreen(orderId: orderId);
      },
    ),

    GoRoute(
      path: '/reorder/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return const Placeholder(); // Replace with ReorderScreen when implemented
      },
    ),
    GoRoute(
      path: '/return/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return const Placeholder(); // Replace with ReturnScreen when implemented
      },
    ),

    GoRoute(
      path: '/catalog',
      builder: (context, state) => ProductCatalogPage(
        categoryId: state.pathParameters['categoryId'],
      ),
      routes: [
        GoRoute(
          path: ':categoryId',
          builder: (context, state) => ProductCatalogPage(
            categoryId: state.pathParameters['categoryId'],
          ),
        ),
      ],
    ),

    /// User profile & settings
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileManagementScreen(),
    ),
    GoRoute(
      path: '/personal-info',
      builder: (context, state) => const ProfileManagementScreen(),
    ),
    GoRoute(
      path: '/account-settings',
      builder: (context, state) => const AccountSettingsScreen(),
    ),

    // Manager Routes
    GoRoute(
      path: '/manager',
      builder: (context, state) {
        final isWeb = MediaQuery.of(context).size.width >= 600;
        return isWeb ? const WebDashboard() : const MobileDashboard();
      },
      routes: [
        GoRoute(
          path: 'dashboard',
          builder: (context, state) {
            final isWeb = MediaQuery.of(context).size.width >= 600;
            return isWeb ? const WebDashboard() : const MobileDashboard();
          },
        ),
        GoRoute(
          path: 'products',
          builder: (context, state) => const ProductManagementScreen(),
        ),
        GoRoute(
          path: 'products/add',
          name: 'add-product',
          builder: (context, state) {
            final product = state.extra as Product?;
            return AddProductScreen(product: product);
          },
        ),
        GoRoute(
          path: 'products/delete/:id',
          name: 'delete-product',
          builder: (context, state) {
            final product = state.extra as Product;
            return DeleteProductScreen(product: product);
          },
        ),
        GoRoute(
          path: 'product/:id',
          name: 'manager-product-detail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ProductDetailScreene(productId: id);
          },
        ),
        GoRoute(
          path: 'coupons',
          builder: (context, state) => const CouponManagement(),
        ),
        GoRoute(
          path: 'categories',
          builder: (context, state) => const CategoriesManagement(),
        ),
        GoRoute(
          path: 'users',
          builder: (context, state) => const UserListScreen(),
        ),
        GoRoute(
          path: '/order-details/:orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            return OrderDetailsScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: 'orders',
          builder: (context, state) => const OrderListScreenMn(),
        ),
        GoRoute(
          path: 'orders/:orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            final extra = state.extra as Order?;
            return OrderDetailScreenMn(orderId: orderId, order: extra);
          },
        ),
        GoRoute(
          path: 'orders-report',
          builder: (context, state) => const OrdersReport(),
        ),
        GoRoute(
          path: 'revenue-report',
          builder: (context, state) => const RevenueReport(),
        ),
        GoRoute(
          path: 'user-report',
          builder: (context, state) => const UserReportScreen(),
        ),
        GoRoute(
          path: 'support',
          builder: (context, state) => const CustomerSupport(), // Manager's support dashboard
          routes: [
            GoRoute(
              path: ':userId',
              builder: (context, state) {
                final userId = state.pathParameters['userId'];
                return CustomerServiceScreen(userId: userId); // Chi tiết hỗ trợ cho user
              },
            ),
          ],
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfileManagementScreen(),
        ),

      ],
    ),
  ],
);