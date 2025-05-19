import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import 'package:danentang/Service/user_service.dart';
import '../Login/Login_Screen.dart';

class Signup extends StatefulWidget {
  final String email;
  const Signup({required this.email, super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final addressController = TextEditingController();
  final receiverController = TextEditingController();
  final phoneController = TextEditingController();
  final communeController = TextEditingController();
  final districtController = TextEditingController();
  final cityController = TextEditingController();
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    receiverController.dispose();
    phoneController.dispose();
    communeController.dispose();
    districtController.dispose();
    cityController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!isValidEmail(widget.email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email không hợp lệ')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await _userService.register(
        email: widget.email,
        fullName: nameController.text.trim(),
        password: passwordController.text,
        addressLine: addressController.text.trim(),
        receiverName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        commune: communeController.text.trim(),
        district: districtController.text.trim(),
        city: cityController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công!')),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(email: widget.email),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng ký thất bại: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  bool isValidPhone(String phone) {
    final regex = RegExp(r'^\d{10}$');
    return regex.hasMatch(phone);
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        bool isPassword = false,
        bool isConfirm = false,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword
          ? (isConfirm ? !showConfirmPassword : !showPassword)
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
            (isConfirm ? showConfirmPassword : showPassword)
                ? Icons.visibility
                : Icons.visibility_off,
            color: Colors.black26,
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
    );
  }

  Widget _buildFormContent(double h, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Đăng ký",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          "Tên của bạn *",
          nameController,
          validator: (value) =>
          value == null || value.trim().isEmpty ? 'Vui lòng nhập tên' : null,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          "Mật khẩu *",
          passwordController,
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập mật khẩu';
            }
            if (value.length < 6) {
              return 'Mật khẩu phải có ít nhất 6 ký tự';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        _buildTextField(
          "Xác nhận mật khẩu *",
          confirmPasswordController,
          isPassword: true,
          isConfirm: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng xác nhận mật khẩu';
            }
            if (value != passwordController.text) {
              return 'Mật khẩu không khớp';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        _buildTextField(
          "Số điện thoại *",
          phoneController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập số điện thoại';
            }
            if (!isValidPhone(value.trim())) {
              return 'Số điện thoại phải có 10 chữ số';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        _buildTextField(
          "Địa chỉ *",
          addressController,
          validator: (value) =>
          value == null || value.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          "Xã/Phường *",
          communeController,
          validator: (value) =>
          value == null || value.trim().isEmpty ? 'Vui lòng nhập xã/phường' : null,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          "Quận/Huyện *",
          districtController,
          validator: (value) =>
          value == null || value.trim().isEmpty ? 'Vui lòng nhập quận/huyện' : null,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          "Thành phố *",
          cityController,
          validator: (value) =>
          value == null || value.trim().isEmpty ? 'Vui lòng nhập thành phố' : null,
        ),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          height: h * 0.07,
          child: ElevatedButton(
            onPressed: isLoading ? null : registerUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
              "Đăng ký",
              style: TextStyle(fontSize: w * 0.05, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen(email: widget.email))),
            child: const Text.rich(
              TextSpan(
                style: TextStyle(color: Colors.black54),
                children: [
                  TextSpan(text: "Đã có tài khoản? "),
                  TextSpan(text: "Đăng nhập ngay.", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
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
                      "Chào mừng đến với ứng dụng mua sắm",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Khám phá các ưu đãi độc quyền và trải nghiệm mua sắm trực tuyến mới.",
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