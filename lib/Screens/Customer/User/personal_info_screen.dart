import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:danentang/widgets/User/profile_drawer.dart';
import 'package:danentang/widgets/User/profile_mobile_layout.dart';
import 'package:danentang/widgets/User/profile_web_layout.dart';

class ProfileManagementScreen extends StatelessWidget {
  const ProfileManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
        title: const Text('Hồ sơ của bạn'),
        backgroundColor: const Color(0xFF4B5EFC),
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF3B82F6)),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      )
          : null,
      drawer: isMobile ? const ProfileDrawer() : null,
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          if (!isMobile && kIsWeb)
            const SizedBox(width: 250, child: ProfileDrawer()),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: kIsWeb
                    ? const ProfileWebLayout()
                    : const ProfileMobileLayout(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
