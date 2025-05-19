import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../Report/revenue_report.dart';

class RevenueChartWidget extends StatefulWidget {
  final List<FlSpot> spots;
  final Color lineColor;

  const RevenueChartWidget({
    Key? key,
    required this.spots,
    required this.lineColor,
  }) : super(key: key);

  @override
  _RevenueChartWidgetState createState() => _RevenueChartWidgetState();
}

class _RevenueChartWidgetState extends State<RevenueChartWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant RevenueChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spots != widget.spots) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<FlSpot> getAnimatedSpots() {
    final length = widget.spots.length;
    final progress = _animation.value * length;

    List<FlSpot> animatedSpots = [];
    for (int i = 0; i < progress.floor(); i++) {
      animatedSpots.add(widget.spots[i]);
    }

    if (progress < length && progress > 0) {
      final nextIndex = progress.floor();
      final ratio = progress - nextIndex;

      if (nextIndex < widget.spots.length) {
        final current = widget.spots[nextIndex];
        final partialY = current.y * ratio;
        animatedSpots.add(FlSpot(current.x, partialY));
      }
    }

    return animatedSpots;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Doanh thu theo tháng",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        drawHorizontalLine: true,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey,
                          strokeWidth: 0.5,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.grey,
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value >= 0 && value <= 11) {
                                return Text('${value.toInt() + 1}');
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: getAnimatedSpots(),
                          isCurved: true,
                          color: widget.lineColor,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: false),
                          dotData: FlDotData(show: true),
                        ),
                      ],
                      minX: -0.8,
                      maxX: 11,
                      minY: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => RevenueReport()));
                    },
                    child: const Text(
                      "Xem chi tiết",
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}