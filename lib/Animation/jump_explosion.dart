import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class JumpExplosion extends StatelessWidget {
  const JumpExplosion({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProductPage(),
    );
  }
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> with TickerProviderStateMixin {
  final GlobalKey _cartKey = GlobalKey();
  final GlobalKey _imageKey = GlobalKey();
  Offset startOffset = Offset.zero;
  Offset endOffset = Offset.zero;
  bool showFlying = false;
  int cartCount = 0;
  late AnimationController controller;
  late Animation<double> animation;
  bool explode = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOutQuad);
  }

  void _addToCart() async {
    final boxImage = _imageKey.currentContext!.findRenderObject() as RenderBox;
    final boxCart = _cartKey.currentContext!.findRenderObject() as RenderBox;

    setState(() {
      startOffset = boxImage.localToGlobal(Offset.zero);
      endOffset = boxCart.localToGlobal(Offset.zero);
      showFlying = true;
    });

    await controller.forward(from: 0);
    controller.stop();

    setState(() {
      showFlying = false;
      cartCount++;
    });

    if (cartCount >= 99 && !explode) {
      _triggerExplosionEffect();
    }
  }

  void _triggerExplosionEffect() async {
    setState(() {
      explode = true;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      explode = false;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Offset _getAnimatedOffset() {
    final dx = Tween<double>(begin: startOffset.dx, end: endOffset.dx).evaluate(animation);
    final midY = startOffset.dy - 150;
    final dy = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: startOffset.dy, end: midY)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: midY, end: endOffset.dy)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).evaluate(animation);

    return Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm'),
        actions: [
          Stack(
            children: [
              IconButton(
                key: _cartKey,
                icon: explode
                    ? Animate(
                        effects: const [
                          ScaleEffect(begin: Offset(1.0, 1.0), end: Offset(1.4, 1.4), duration: Duration(milliseconds: 300)),
                          ShakeEffect(hz: 5, curve: Curves.easeInOut),
                        ],
                        child: const Icon(Icons.shopping_cart_checkout),
                      )
                    : const Icon(Icons.shopping_cart),
                onPressed: () {},
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cartCount > 99 ? '99+' : '$cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  key: _imageKey,
                  width: 150,
                  height: 100,
                  color: Colors.grey[300],
                  child: const Icon(Icons.laptop_mac, size: 70),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _addToCart,
                child: const Text("Thêm vào giỏ hàng"),
              ),
            ],
          ),
          if (showFlying)
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final offset = _getAnimatedOffset();
                return Positioned(
                  left: offset.dx,
                  top: offset.dy,
                  child: child!,
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purple,
                ),
                child: const Icon(Icons.laptop_mac, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}
