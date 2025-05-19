import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/Footer/mobile_navigation_bar.dart';
import '../User/user_list.dart';

class UserReportScreen extends StatefulWidget {
  const UserReportScreen({super.key});

  @override
  State<UserReportScreen> createState() => _UserReportScreenState();
}

class _UserReportScreenState extends State<UserReportScreen>
    with SingleTickerProviderStateMixin {
  String _selectedPeriod = "Tháng";
  late AnimationController _controller;
  late Animation<double> _animation;

  // Mock data for the line chart (user growth over months)
  final List<FlSpot> _spots = [
    FlSpot(1, 10),
    FlSpot(2, 15),
    FlSpot(3, 12),
    FlSpot(4, 20),
    FlSpot(5, 18),
    FlSpot(6, 25),
    FlSpot(7, 30),
    FlSpot(8, 28),
    FlSpot(9, 35),
    FlSpot(10, 40),
    FlSpot(11, 38),
    FlSpot(12, 45),
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<FlSpot> _animatedSpots() {
    final double progress = _animation.value;
    return _spots
        .map((spot) => FlSpot(spot.x, spot.y * progress))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Báo cáo Người dùng",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isMobile
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        )
            : null,
      ),
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSegmentedControl(isMobile),
                const SizedBox(height: 16),
                _buildLineChart(isMobile),
                const SizedBox(height: 16),
                _buildDetailButton(context, isMobile),
                const SizedBox(height: 16),
                _buildUserSection(
                  title: "Người dùng mới",
                  users: [
                    {
                      "name": "Nguyễn Văn An",
                      "date": "17/05/2025",
                      "avatar": "assets/Manager/Avatar/avatar01.jpg"
                    },
                    {
                      "name": "Trần Thị Bình",
                      "date": "15/05/2025",
                      "avatar": "assets/Manager/Avatar/avatar02.jpg"
                    },
                    {
                      "name": "Lê Minh Châu",
                      "date": "14/05/2025",
                      "avatar": "assets/Manager/Avatar/avatar03.jpg"
                    },
                    {
                      "name": "Phạm Quốc Đạt",
                      "date": "13/05/2025",
                      "avatar": "assets/Manager/Avatar/avatar04.jpg"
                    },
                    {
                      "name": "Hoàng Thu Hà",
                      "date": "12/05/2025",
                      "avatar": "assets/Manager/Avatar/avatar05.jpg"
                    },
                  ],
                ),
                const SizedBox(height: 16),
                _buildUserSection(
                  title: "Người dùng hoạt động",
                  users: [
                    {
                      "name": "Đỗ Văn Khánh",
                      "date": "17/05/2025",
                      "avatar": "assets/Manager/Avatar/avatar06.jpg"
                    },
                    {
                      "name": "Vũ Thị Linh",
                      "date": "16/05/2025",
                      "avatar": "assets/Manager/Avatar/avatar07.jpg"
                    },
                  ],
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: isMobile
          ? MobileNavigationBar(
        selectedIndex: 0,
        onItemTapped: (index) {},
        isLoggedIn: true,
        role: 'manager',
      )
          : null,
    );
  }

  Widget _buildSegmentedControl(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ["Ngày", "Tuần", "Tháng"].map((label) {
        return Expanded(
          child: _buildSegmentButton(label, isMobile),
        );
      }).toList(),
    );
  }

  Widget _buildSegmentButton(String text, bool isMobile) {
    final bool isSelected = _selectedPeriod == text;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = text),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 10 : 12,
          horizontal: isMobile ? 16 : 20,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: Colors.black, width: 1.5) : null,
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
            color: isSelected ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double chartHeight = isMobile ? 250.0 : 300.0;
          return SizedBox(
            height: chartHeight,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 10,
                  verticalInterval: 1,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value >= 1 && value <= 12) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'T${value.toInt()}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _animatedSpots(),
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.3),
                          Colors.purple.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 50,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserSection({
    required String title,
    required List<Map<String, String>> users,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        ...users.map(_buildUserItem).toList(),
      ],
    );
  }

  Widget _buildUserItem(Map<String, String> user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(user["avatar"]!),
            radius: 24,
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user["name"]!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user["date"]!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailButton(BuildContext context, bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.push('/manager/users');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 16 : 18,
            horizontal: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          "Xem Chi Tiết",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}