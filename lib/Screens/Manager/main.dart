import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'DashBoard/MobileDashboard.dart';
import 'DashBoard/WebDashboard.dart';

class DashboardResponsive extends StatelessWidget {
  const DashboardResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const WebDashboard();
    }
    else {
      return const MobileDashboard();
    }
  }
}
