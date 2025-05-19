import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Dùng kIsWeb để kiểm tra nền tảng
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:danentang/models/User.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý trang cá nhân'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/account-settings');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (kIsWeb) {
                      context.go('/personal-info');
                    } else {
                      context.push('/personal-info');
                    }
                  },
                  child: const Icon(Icons.edit, size: 20, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Phương thức thanh toán'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment methods feature coming soon!')),
                );
              },
            ),
            ListTile(
              title: const Text('Đơn hàng của tôi'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Điều hướng đến MyOrdersScreen qua route /my-orders
                if (kIsWeb) {
                  context.go('/my-orders');
                } else {
                  context.push('/my-orders');
                }
              },
            ),
            ListTile(
              title: const Text('Cài đặt'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                context.push('/account-settings');
              },
            ),
            ListTile(
              title: const Text('Logout'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('token');
                await prefs.remove('email');
                await prefs.remove('userId');
                // hoặc clear hết tất cả: await prefs.clear();

                // Chuyển về màn hình Login, reset stack
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}