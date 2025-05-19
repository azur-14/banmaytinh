import 'package:flutter/material.dart';

class AnimatedPaymentSuccess extends StatefulWidget {
  const AnimatedPaymentSuccess({super.key});

  @override
  State<AnimatedPaymentSuccess> createState() => _AnimatedPaymentSuccessState();
}

class _AnimatedPaymentSuccessState extends State<AnimatedPaymentSuccess> with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _buttonController;

  late Animation<double> _scaleAnimation;
  late Animation<Offset> _textOffset;
  late Animation<double> _textOpacity;
  late Animation<double> _buttonOpacity;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _textOffset = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_textController);

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_buttonController);

    // Chạy animation tuần tự
    _iconController.forward().then((_) {
      _textController.forward().then((_) {
        _buttonController.forward();
      });
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepPurple,
                  ),
                  child: const Icon(Icons.check, size: 60, color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),
              SlideTransition(
                position: _textOffset,
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: Column(
                    children: const [
                      Text(
                        'Hoàn tất thanh toán!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Cảm ơn bạn đã đặt hàng tại Hoalahe Shop.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              FadeTransition(
                opacity: _buttonOpacity,
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                      },
                      child: const Text('Xem đơn hàng', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
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
