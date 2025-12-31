import 'package:flutter/material.dart';
import 'package:flutter_app_demo/screens/update_leave_screen.dart';

import '../screens/add_leave_screen.dart';
import '../screens/leave_list_screen.dart';

class LeaveNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const LeaveNavigator({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/add':
            return MaterialPageRoute(
              builder: (_) => const AddLeaveScreen(),
            );
          case '/update':
            final leaveId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => UpdateLeaveScreen(
                leaveId: leaveId,
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const LeaveListScreen(),
            );
        }
      },
    );
  }
}

