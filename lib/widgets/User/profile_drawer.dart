import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFFFFFF),
      elevation: 8.0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Image.asset('assets/images/logoapbar.jpg', width: 180),
            ),
          ),
          _buildDrawerItem(context, 'Hồ sơ của bạn', Icons.person, '/personal-info'),
          _buildDrawerItem(context, 'Đơn hàng của tui', Icons.receipt, '/my-orders'),
          _buildDrawerItem(context, 'Đổi mật khẩu', Icons.lock, '/password-change'),
          _buildDrawerItem(context, 'Đăng xuất', Icons.logout, '/login', isLogout: true),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context,
      String title,
      IconData icon,
      String route, {
        bool isLogout = false,
      }) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    return _DrawerItem(
      title: title,
      icon: icon,
      route: route,
      isLogout: isLogout,
      selected: currentRoute == route,
      onTap: () async {
        // 1. Trên mobile: đóng drawer; trên web thì không pop
        if (!kIsWeb) {
          Navigator.of(context).pop();
        }

        // 2. Nếu là logout thì xóa token
        if (isLogout) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.remove('userId');
        }

        // 3. Điều hướng
        context.go(route);
      },
    );
  }
}

class _DrawerItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final String route;
  final bool isLogout;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.isLogout,
    required this.selected,
    required this.onTap,
  });

  @override
  _DrawerItemState createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        onHighlightChanged: (isHighlighted) {
          setState(() => _isPressed = isHighlighted);
        },
        onHover: (isHovered) {
          setState(() => _isHovered = isHovered);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: _isPressed
                ? (widget.isLogout ? const Color(0xFFFFE4E6) : const Color(0xFFD1E7FF))
                : _isHovered
                ? (widget.isLogout ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF))
                : widget.selected
                ? const Color(0xFFEFF6FF)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.selected || _isHovered || _isPressed
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.isLogout ? const Color(0xFFF87171) : const Color(0xFF4B5EFC),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.isLogout ? const Color(0xFFF87171) : const Color(0xFF1E293B),
                    fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
