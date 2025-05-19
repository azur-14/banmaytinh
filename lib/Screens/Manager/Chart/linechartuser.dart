import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../Report/user_report.dart';

class LineChartUser extends StatefulWidget {
  final List<FlSpot> spots;
  final Color lineColor;

  const LineChartUser({
    Key? key,
    required this.spots,
    required this.lineColor,
  }) : super(key: key);

  @override
  State<LineChartUser> createState() => _LineChartUserState();
}

class _LineChartUserState extends State<LineChartUser> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  List<FlSpot> get _filteredSpots =>
      widget.spots.where((spot) => spot.x >= 1).toList();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant LineChartUser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spots != widget.spots) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<FlSpot> _animatedSpots() {
    return _filteredSpots
        .map((spot) => FlSpot(spot.x, spot.y * _animation.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Báo cáo người dùng theo tháng",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: 250,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        final animatedSpots = _animatedSpots();
                        final maxY = _filteredSpots.isEmpty
                            ? 10
                            : _filteredSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2;

                        return FadeTransition(
                          opacity: _animation,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                drawHorizontalLine: true,
                                getDrawingHorizontalLine: (value) =>
                                    FlLine(color: Colors.grey, strokeWidth: 0.5),
                                getDrawingVerticalLine: (value) =>
                                    FlLine(color: Colors.grey, strokeWidth: 0.5),
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
                                      if (value >= 1 && value <= 12) {
                                        return Text('${value.toInt()}');
                                      }
                                      return const Text('');
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
                                  spots: animatedSpots,
                                  isCurved: true,
                                  color: widget.lineColor,
                                  barWidth: 3,
                                  belowBarData: BarAreaData(show: false),
                                  dotData: FlDotData(show: true),
                                ),
                              ],
                              minX: 0,
                              maxX: 13,
                              minY: 0,
                              maxY: maxY.toDouble(), // Fix here
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserReportScreen()),
                  );
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
  }
}