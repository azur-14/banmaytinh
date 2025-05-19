import 'package:flutter/material.dart';

class PlaceOrderButton extends StatelessWidget {
  final bool isHovered;
  final Function(bool) onHover;
  final VoidCallback onPressed;
  final double cardMaxWidth;

  const PlaceOrderButton({
    super.key,
    required this.isHovered,
    required this.onHover,
    required this.onPressed,
    required this.cardMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: cardMaxWidth),
        child: MouseRegion(
          onEnter: (_) => onHover(true),
          onExit: (_) => onHover(false),
          child: AnimatedScale(
            scale: isHovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A4FCF),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: isHovered ? 8 : 4,
                ),
                child: const Text(
                  'Đặt hàng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}