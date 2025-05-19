import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:danentang/models/User.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Change Password'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                context.go('/account/change-password');
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
            ListTile(
              title: const Text('Đổi Theme'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implement theme change logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme change feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}