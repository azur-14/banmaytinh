import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:danentang/service/user_service.dart';
import 'package:danentang/models/user.dart';

class MobileHeader extends StatefulWidget implements PreferredSizeWidget {
  final bool isLoggedIn;
  const MobileHeader({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  State<MobileHeader> createState() => _MobileHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _MobileHeaderState extends State<MobileHeader> {
  String? fullName;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadFullName();
    }
  }

  Future<void> _loadFullName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email != null) {
        final user = await UserService().fetchUserByEmail(email);
        setState(() {
          fullName = user.fullName;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi lấy user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.diamond, color: Colors.purple, size: 20),
          const SizedBox(width: 8),
          Text(
            widget.isLoggedIn
                ? (fullName != null ? 'Hello $fullName' : 'Hello...')
                : 'Hoalahe',
            style: const TextStyle(color: Colors.black, fontSize: 18),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.black),
              onPressed: () => context.go('/checkout', extra: widget.isLoggedIn),
            ),
            const Positioned(right: 8, top: 8, child: _Badge(count: 1)),
          ],
        ),
        const SizedBox(width: 8),
        if (widget.isLoggedIn) ...[
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.message, color: Colors.black),
                onPressed: () => context.go('/chat'),
              ),
              const Positioned(right: 8, top: 8, child: _Badge(count: 1)),
            ],
          ),
        ] else ...[
          TextButton(
            onPressed: () => context.go('/login-signup'),
            child: const Text(
              'Đăng nhập',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({Key? key, required this.count}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(
        '$count',
        style: const TextStyle(color: Colors.white, fontSize: 10),
        textAlign: TextAlign.center,
      ),
    );
  }
}
