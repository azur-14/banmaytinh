import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:danentang/constants/colors.dart';
import 'package:danentang/Service/user_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String email;
  const ForgotPasswordScreen({required this.email, Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController emailController;
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  String? _serverOtp;
  String? errorMessage;

  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.email);
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    try {
      final otp = await _userService.sendOtp(widget.email);
      debugPrint('sendOtp success, otp=$otp');
      setState(() {
        _serverOtp = otp;
        errorMessage = null;
      });
      _showSnackBar('Mã OTP đã gửi đến ${widget.email}');
    } catch (e) {
      debugPrint('Error in sendOtp(): $e');
      setState(() => errorMessage = e.toString());
      _showSnackBar('Lỗi gửi OTP: $e');
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (otpController.text.trim() != _serverOtp) {
      setState(() => errorMessage = 'OTP không đúng');
      _showSnackBar('OTP không đúng');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _userService.resetPassword(
        email: widget.email,
        newPassword: newPasswordController.text,
      );
      debugPrint('resetPassword success');
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Thành công'),
          content: const Text('Đổi mật khẩu thành công!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // đóng dialog
                context.go('/login', extra: widget.email);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error in resetPassword(): $e');
      setState(() => errorMessage = e.toString());
      _showSnackBar('Lỗi đổi mật khẩu: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildTextFormField({
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool isPassword = false,
    bool isConfirm = false,
    bool isNumeric = false,
  }) {
    final obscure = isPassword
        ? (isConfirm ? !showConfirmPassword : !showPassword)
        : false;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType:
      isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            (isConfirm ? showConfirmPassword : showPassword)
                ? Icons.visibility
                : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              if (isConfirm) {
                showConfirmPassword = !showConfirmPassword;
              } else {
                showPassword = !showPassword;
              }
            });
          },
        )
            : null,
      ),
      validator: validator,
    );
  }

  Widget _buildFormContent(double h, double w) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quên mật khẩu",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Email (readonly)
          TextFormField(
            controller: emailController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: "Email của bạn",
              filled: true,
              fillColor: Colors.grey.shade200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // OTP
          _buildTextFormField(
            hint: "Nhập mã OTP",
            controller: otpController,
            isNumeric: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập mã OTP';
              if (!RegExp(r'^\d{4,6}$').hasMatch(v)) {
                return 'OTP phải từ 4–6 chữ số';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),

          // Mật khẩu mới
          _buildTextFormField(
            hint: "Mật khẩu mới",
            controller: newPasswordController,
            isPassword: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
              if (v.length < 6) return 'Ít nhất 6 ký tự';
              return null;
            },
          ),
          const SizedBox(height: 15),

          // Xác nhận mật khẩu
          _buildTextFormField(
            hint: "Xác nhận mật khẩu",
            controller: confirmPasswordController,
            isPassword: true,
            isConfirm: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
              if (v != newPasswordController.text) return 'Mật khẩu không khớp';
              return null;
            },
          ),
          const SizedBox(height: 15),

          // Lỗi nếu có
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 15),
          ],

          // Nút Đặt lại mật khẩu
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: AppColors.brandSecondary,
                disabledBackgroundColor:
                AppColors.brandSecondary.withOpacity(0.5),
                elevation: 6,
                shadowColor: Colors.black26,
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : const Text("Đặt lại mật khẩu"),
            ),
          ),
          const SizedBox(height: 20),

          // Gửi lại OTP
          Center(
            child: TextButton(
              onPressed: _sendOtp,
              child: const Text(
                "Gửi lại mã OTP",
                style: TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quay về Login
          Center(
            child: TextButton(
              onPressed: () {
                context.go('/login', extra: widget.email);
              },
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "Nhớ mật khẩu? "),
                    TextSpan(
                      text: "Đăng nhập",
                      style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.brandPrimary,
      body: Column(
        children: [
          const SizedBox(height: 40),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 30),
                child: _buildFormContent(h, w),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Row(
        children: [
          // Bên trái: màu chủ đạo + tiêu đề
          Expanded(
            flex: 1,
            child: Container(
              color: AppColors.brandPrimary,
              padding: const EdgeInsets.all(60),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/Logo.png', width: 200),
                    const SizedBox(height: 30),
                    const Text(
                      "Quên mật khẩu",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Vui lòng nhập OTP và thiết lập mật khẩu mới",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bên phải: card trắng chứa form
          Expanded(
            flex: 1,
            child: Center(
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    child: _buildFormContent(h, w),
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
    return screenWidth > 800
        ? _buildWebLayout()
        : _buildMobileLayout();
  }
}
