import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:danentang/constants/colors.dart';
import 'package:danentang/Service/user_service.dart';
import 'package:danentang/models/User.dart';

class WebHeader extends StatefulWidget implements PreferredSizeWidget {
  final bool isLoggedIn;

  const WebHeader({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  _WebHeaderState createState() => _WebHeaderState();
}

class _WebHeaderState extends State<WebHeader> {
  User? _user;
  bool _loading = false;
  String? _error;
  final UserService _userService = UserService();
  String? _role;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      final role = prefs.getString('role') ?? 'customer';

      debugPrint('📦 Email from prefs: $email');

      if (email != null) {
        final user = await UserService().fetchUserByEmail(email);
        setState(() {
          _user = user;
          _role = role;
        });
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi lấy user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = widget.isLoggedIn;

    String title;
    if (!loggedIn) {
      title = 'Hoalahe';
    } else if (_loading) {
      title = 'Đang tải...';
    } else if (_user != null) {
      title = _user!.fullName;
    } else {
      title = 'Guest';
    }

    ImageProvider? avatarImg;
    if (_user?.avatarUrl != null && _user!.avatarUrl!.startsWith('data:image')) {
      try {
        final base64Data = _user!.avatarUrl!.split(',').last;
        avatarImg = MemoryImage(base64Decode(base64Data));
      } catch (_) {
        avatarImg = null;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Hoalahe",
                  style: TextStyle(
                    color: Color(0xFF171F32),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: " | Kênh người bán | Tải Ứng dụng | Kết nối",
                  style: TextStyle(
                    color: Color(0xFF171F32),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            "Tiếng Việt",
            style: TextStyle(
              color: Color(0xFF171F32),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          if (loggedIn) ...[
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(
                  Icons.message,
                  color: Color(0xFF4D72E4),
                  size: 24,
                ),
                onPressed: () {
                  if (_role == 'admin') {
                    context.go('/support');
                  } else {
                    context.go('/chat');
                  }
                },
                tooltip: 'Tin nhắn',
                hoverColor: Color(0xFF4D72E4).withOpacity(0.1),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(
                  Icons.shopping_cart,
                  color: Color(0xFF4D72E4),
                  size: 24,
                ),
                onPressed: () {
                  context.go('/checkout');
                },
                tooltip: 'Giỏ hàng',
                hoverColor: Color(0xFF4D72E4).withOpacity(0.1),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: avatarImg,
                    backgroundColor: Color(0xFFF3F0FF),
                    child: avatarImg == null && !_loading
                        ? const Icon(
                      Icons.person,
                      color: Color(0xFF4D72E4),
                      size: 20,
                    )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1A0056),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(
                  Icons.shopping_cart,
                  color: Color(0xFF4D72E4),
                  size: 24,
                ),
                onPressed: () {
                  context.go('/checkout');
                },
                tooltip: 'Giỏ hàng',
                hoverColor: Color(0xFF4D72E4).withOpacity(0.1),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6989E8),
                    Color(0xFF4D72E4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: TextButton(
                onPressed: () => context.go('/login-signup'),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF1A0056),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}