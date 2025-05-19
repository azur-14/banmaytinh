import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:danentang/constants/colors.dart';

class WebSearchBar extends StatelessWidget {
  final bool isLoggedIn;

  const WebSearchBar({required this.isLoggedIn, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF6FAFF),
            Color(0xFFF5F9FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Text(
            "HoaLaHe",
            style: TextStyle(
              color: Color(0xFF190053),
              fontSize: 36,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(40),
              child: TextField(
                onTap: () {
                  context.go('/search'); // Chuyển hướng đến Searching
                },
                readOnly: true, // Ngăn nhập liệu, chỉ nhấn để chuyển
                decoration: InputDecoration(
                  hintText: "Tìm kiếm sản phẩm...",
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Transform.scale(
                      scale: 1.0,
                      child: Icon(
                        Icons.search_rounded,
                        color: Color(0xFFCFCFCF),
                        size: 24,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40),
                    borderSide: BorderSide(
                      color: Color(0xFFCFCFCF).withOpacity(0.2),
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40),
                    borderSide: BorderSide(
                      color: Color(0xFFCFCFCF),
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.95),
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
        ],
      ),
    );
  }
}