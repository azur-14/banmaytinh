import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2962FF);
  static const Color primaryDark = Color(0xFF0039CB);
  static const Color primaryLight = Color(0xFF768FFF);
  static const Color accent = Color(0xFF00BFA5);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);

  // Màu chính (Primary Color) - dùng cho nền Card
  static const Color brandPrimary = Color(0xFF211463);

  // Màu phụ (Secondary Color)
  static const Color brandSecondary = Color(0xFF642FBF);

  // Màu nhấn (Accent Color)
  static const Color brandAccent = Color(0xFF211463);

  // Một số màu phụ trợ khác nếu cần
  static const Color brandLight = Color(0xFFF2E7FE);
  static const Color brandDark = Color(0xFF1C0D4F);

  static const Color scaffoldBackground = Color(0xFAFAFA);
  static const Color primaryPurple = Color(0xFF8204FF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color discountBadge = Colors.purple;
  static const Color bannerGradientStart = Colors.purple;
  static const Color bannerGradientEnd = Color(0xFFE1BEE7);

  static const Color purpleButton = Color(0xFF642FBF);
  static const Color greyText = Colors.grey;
  static const Color avatarBackground = Colors.grey;
  static const Color cameraIconBackground = Colors.blue;
  static const Color whiteIcon = Colors.white;

  static const String purple = '#8204FF'; // Colors.purple
  static const String white = '#FFFFFF'; // Colors.white
  static const String grey = '#9E9E9E'; // Colors.grey
  static const String grey300 = '#E0E0E0'; // Colors.grey.shade300
  static const String yellow = '#FFFF00'; // Colors.yellow (for star rating)
  static const String black = '#000000'; // Colors.black (for text)


  // Utility function to convert hex string to Color
  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add alpha value if not present
    }
    return Color(int.parse(hex, radix: 16));
  }
}