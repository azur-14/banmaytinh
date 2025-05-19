import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:visibility_detector/visibility_detector.dart';

class AnimatedPieChart extends StatefulWidget {
  const AnimatedPieChart({Key? key}) : super(key: key);

  @override
  _AnimatedPieChartState createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<AnimatedPieChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool _visibleTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: -360, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _startAnimation() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key("pie_chart_rotation"),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5 && !_visibleTriggered) {
          _visibleTriggered = true;
          _startAnimation();
        } else if (info.visibleFraction == 0) {
          _visibleTriggered = false;
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Các phương thức đăng nhập",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 140,
                child: AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return PieChart(
                      PieChartData(
                        startDegreeOffset: _rotationAnimation.value,
                        sections: [
                          PieChartSectionData(
                            value: 30,
                            color: Colors.green,
                            title: 'Direct',
                            radius: 35,
                            titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          PieChartSectionData(
                            value: 20,
                            color: Colors.blue,
                            title: 'Affiliate',
                            radius: 35,
                            titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          PieChartSectionData(
                            value: 15,
                            color: Colors.orange,
                            title: 'Sponsored',
                            radius: 35,
                            titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          PieChartSectionData(
                            value: 10,
                            color: Colors.yellow,
                            title: 'Email',
                            radius: 35,
                            titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                        borderData: FlBorderData(show: false),
                        centerSpaceRadius: 30,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
