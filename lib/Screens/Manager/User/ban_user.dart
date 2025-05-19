// lib/screens/manager/user/ban_user_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:danentang/Service/user_service.dart';
import 'package:danentang/widgets/footer/mobile_navigation_bar.dart';

class BanUserScreen extends StatefulWidget {
  final String userId;
  const BanUserScreen({super.key, required this.userId});

  @override
  State<BanUserScreen> createState() => _BanUserScreenState();
}

class _BanUserScreenState extends State<BanUserScreen>
    with SingleTickerProviderStateMixin {
  final _svc = UserService();
  late final AnimationController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _banUser();
  }

  Future<void> _banUser() async {
    try {
      await _svc.banUser(widget.userId);
      // play animation and then navigate to success screen
      await _controller.forward();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const BannedSuccessScreen(),
          ),
          transitionsBuilder: (_, animation, __, child) => ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: FadeTransition(opacity: animation, child: child),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // While banning in progress
    if (_isLoading && _error == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // On error
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lỗi'),
          backgroundColor: Colors.redAccent,
        ),
        body: Center(
          child: Text('Không thể ban user: $_error'),
        ),
      );
    }

    // This point won't normally be reached because we navigate on success
    return const SizedBox.shrink();
  }
}

class BannedSuccessScreen extends StatelessWidget {
  const BannedSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            tween: Tween<double>(begin: 0.8, end: 1),
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'ban-icon',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.block, color: Colors.white, size: 48),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'User đã bị ban thành công!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Người dùng sẽ không thể truy cập hệ thống nữa.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Quay lại"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: MobileNavigationBar(
        selectedIndex: 1,
        onItemTapped: (index) => Navigator.of(context).popUntil((_) => false),
        isLoggedIn: true,
        role: 'manager',
      ),
    );
  }
}
