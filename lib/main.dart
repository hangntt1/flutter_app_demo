import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'navigate/leave_navigator.dart';
import 'screens/dashboard_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'dart:ui';

void main() async  {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: AppScrollBehavior(),
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo App',
      theme: AppTheme.darkTheme, 
      home: const LoginScreen(),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final GlobalKey<NavigatorState> _leaveNavKey =
      GlobalKey<NavigatorState>();


  late final List<Widget> _pages = [
    DashboardScreen(
      onOpenLeave: _openLeaveList,
    ),
    LeaveNavigator(navigatorKey: _leaveNavKey),
    NotificationScreen(
      onOpenLeave: _openLeaveFromNoti,
    ),
  ];

  void _openLeaveList() {
    setState(() => _currentIndex = 1);

    // reset stack của Leave về List
    _leaveNavKey.currentState
        ?.popUntil((route) => route.isFirst);
  }

  void _openLeaveFromNoti(String leaveId) {
    setState(() => _currentIndex = 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = _leaveNavKey.currentState;
      if (nav == null) return;

      nav.popUntil((route) => route.isFirst);
      nav.pushNamed(
        '/update',
        arguments: leaveId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            iconSize: 20, // 👈 nhỏ hơn (mặc định 24)
            selectedFontSize: 11,
            unselectedFontSize: 10,
            showUnselectedLabels: true,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Tổng quan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Đơn nghỉ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                label: 'Thông báo',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
