import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../constants/colors.dart';
import 'Login_Screen.dart';
import 'SignUp.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;

  // Hàm gọi API và điều hướng sang Login/Signup
  void checkEmailAndNavigate(BuildContext context, String email) async {
    final url = Uri.parse('https://usermanagementservice-production-697c.up.railway.app/api/auth/check-email?email=$email');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final exists = jsonData['exists'] as bool;
        final isVerified = jsonData['isEmailVerified'] as bool;

        if (exists && isVerified) {
          // chuyển sang màn login, truyền extra = email
          context.go('/login', extra: email);
          // hoặc: context.goNamed('login', extra: email);
        } else {
          // chuyển sang màn signup, truyền extra = email
          context.go('/signup', extra: email);
          // hoặc: context.goNamed('signup', extra: email);
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi kiểm tra email: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e')),
      );
    }
  }


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _cardFadeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.brandPrimary,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(child: Image.asset('assets/Logo.png', width: 180)),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Đăng nhập - Đăng ký",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập email';
                          }
                          if (!_isValidEmail(value.trim())) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "Email *",
                          labelStyle: const TextStyle(color: Colors.grey),
                          floatingLabelStyle: TextStyle(
                            color: AppColors.brandSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.brandSecondary),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        children: [
                          const Text("Bằng cách tiếp tục, tôi đồng ý với ", style: TextStyle(color: Colors.black54)),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              "Điều khoản sử dụng",
                              style: TextStyle(color: AppColors.brandAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Text(" & "),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              "Chính sách bảo mật",
                              style: TextStyle(color: AppColors.brandAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandSecondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final email = emailController.text.trim();
                              checkEmailAndNavigate(context, email);
                            }
                          },
                          child: const Text(
                            "Tiếp tục",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Bên trái: hiển thị logo & slogan
          Expanded(
            flex: 1,
            child: Container(
              color: AppColors.brandPrimary,
              padding: const EdgeInsets.all(60),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/Logo.png', width: 200),
                    const SizedBox(height: 30),
                    const Text(
                      "Chào mừng đến với Hoalahe",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Trải nghiệm giải pháp số đột phá\nvà tận hưởng những lợi ích độc quyền.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, color: Colors.white70, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bên phải: card chứa form với hiệu ứng Fade & Slide
          Expanded(
            flex: 1,
            child: Center(
              child: SlideTransition(
                position: _cardSlideAnimation,
                child: FadeTransition(
                  opacity: _cardFadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.all(60),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 30),
                              const Text(
                                "Đăng nhập - Đăng ký",
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập email';
                                  }
                                  if (!_isValidEmail(value.trim())) {
                                    return 'Email không hợp lệ';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: "Email *",
                                  labelStyle: const TextStyle(color: Colors.grey),
                                  floatingLabelStyle: TextStyle(
                                    color: AppColors.brandSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade200,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: AppColors.brandSecondary),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.red),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.red),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Wrap(
                                children: [
                                  const Text("Bằng cách tiếp tục, tôi đồng ý với ", style: TextStyle(color: Colors.black54)),
                                  GestureDetector(
                                    onTap: () {},
                                    child: const Text(
                                      "Điều khoản sử dụng",
                                      style: TextStyle(color: AppColors.brandAccent, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Text(" & "),
                                  GestureDetector(
                                    onTap: () {},
                                    child: const Text(
                                      "Chính sách bảo mật",
                                      style: TextStyle(color: AppColors.brandAccent, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brandSecondary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      final email = emailController.text.trim();
                                      checkEmailAndNavigate(context, email);
                                    }
                                  },
                                  child: const Text(
                                    "Tiếp tục",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 800 ? _buildWebLayout() : _buildMobileLayout();
  }
}