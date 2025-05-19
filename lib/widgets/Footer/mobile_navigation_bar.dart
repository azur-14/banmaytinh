import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final bool isLoggedIn;
  final String role;

  const MobileNavigationBar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.isLoggedIn,
    required this.role,
  });

  List<BottomNavigationBarItem> get _navigationItems {
    if (role == 'manager') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Support'),
        BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Order'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: _navigationItems,
      currentIndex: selectedIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        onItemTapped(index);

        if (role == 'manager') {
          if (index == 0) {
            context.go('/manager-dashboard');
          } else if (index == 1) {
            context.go('/customer-service');
          } else if (index == 2) {
            context.go('/manager-profile');
          }
        } else {
          if (index == 0) {
            context.go('/');
          } else if (index == 1) {
            context.go('/checkout', extra: isLoggedIn);
          } else if (index == 2) {
            context.go('/profile');
          } else if (index == 3) {
            context.go('/my-orders');
          }
        }
      },
    );
  }
}