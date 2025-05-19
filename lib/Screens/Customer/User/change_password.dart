import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:danentang/Service/user_service.dart';
import 'package:danentang/constants/colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  bool showCurrentPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;

  Future<String?> _getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    print('Form validation started');
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng kiểm tra lại các trường nhập')),
      );
      return;
    }

    print('Retrieving email');
    final email = await _getEmail();
    if (email == null) {
      print('Email not found');
      setState(() => _error = 'Không xác định được tài khoản.');
      return;
    }
    print('Email retrieved: $email');

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('Calling UserService.changePassword');
      await UserService().changePassword(
        email: email,
        currentPassword: _currentPwCtrl.text,
        newPassword: _newPwCtrl.text,
      );
      print('Password change successful');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thành công!')),
      );
      context.go('/profile');
    } catch (e) {
      print('Error during password change: $e');
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      print('Setting loading to false');
      setState(() => _loading = false);
    }
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        bool isPassword = false,
        bool isCurrent = false,
        bool isConfirm = false,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword
          ? (isCurrent
          ? !showCurrentPassword
          : isConfirm
          ? !showConfirmPassword
          : !showNewPassword)
          : false,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
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
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            (isCurrent
                ? showCurrentPassword
                : isConfirm
                ? showConfirmPassword
                : showNewPassword)
                ? Icons.visibility
                : Icons.visibility_off,
            color: Colors.black26,
          ),
          onPressed: () {
            setState(() {
              if (isCurrent) {
                showCurrentPassword = !showCurrentPassword;
              } else if (isConfirm) {
                showConfirmPassword = !showConfirmPassword;
              } else {
                showNewPassword = !showNewPassword;
              }
            });
          },
        )
            : null,
      ),
    );
  }

  Widget _buildFormContent(double h, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Đổi mật khẩu",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 20),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        _buildTextField(
          "Mật khẩu hiện tại *",
          _currentPwCtrl,
          isPassword: true,
          isCurrent: true,
          validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          "Mật khẩu mới *",
          _newPwCtrl,
          isPassword: true,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
            if (v.length < 6) return 'Mật khẩu phải ít nhất 6 ký tự';
            return null;
          },
        ),
        const SizedBox(height: 15),
        _buildTextField(
          "Xác nhận mật khẩu mới *",
          _confirmPwCtrl,
          isPassword: true,
          isConfirm: true,
          validator: (v) {
            if (v != _newPwCtrl.text) return 'Không khớp mật khẩu mới';
            return null;
          },
        ),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          height: h * 0.07,
          child: ElevatedButton(
            onPressed: _loading ? null : _onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
              "Xác nhận",
              style: TextStyle(fontSize: w * 0.05, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => context.go('/profile'),
            child: const Text(
              "Quay lại hồ sơ",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.hexToColor('#211463'), // Blue background
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
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: _buildFormContent(h, w),
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
          Expanded(
            flex: 1,
            child: Container(
              color: AppColors.brandPrimary,
              padding: const EdgeInsets.all(60),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/Logo.png', width: 250),
                    const SizedBox(height: 30),
                    const Text(
                      "Quản lý tài khoản của bạn",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Cập nhật thông tin và bảo mật tài khoản dễ dàng.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, color: Colors.white70, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(60),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Form(
                      key: _formKey,
                      child: _buildFormContent(700, 500),
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
    final w = MediaQuery.of(context).size.width;
    return w > 800 ? _buildWebLayout() : _buildMobileLayout();
  }
}