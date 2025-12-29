import 'package:flutter/material.dart';
import '../models.dart';
import '../services.dart';
import 'today_screen.dart';
import 'map_screen.dart';
import 'notice_board_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';

class HomeScreen extends StatefulWidget {
  final Student student;
  final Future<void> Function() onLogout;

  const HomeScreen({
    super.key,
    required this.student,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _scheduleService = ScheduleService();
  final _noticeService = NoticeService();

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayScreen(
        student: widget.student,
        scheduleService: _scheduleService,
      ),
      const ScheduleScreen(),
      const MapScreen(),
      NoticeBoardScreen(
        noticeStream: _noticeService.listenNotices(),
      ),
      ProfileScreen(
        student: widget.student,
        onLogout: widget.onLogout,
      ),
    ];

    /// 🔹 Titoli dinamici per AppBar
    final titles = [
      'Welcome to RIMUN XIX', // Today
      'Schedule',
      'Map',
      'News',
      'Profile',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F245B),

      appBar: AppBar(
        centerTitle: true,
        title: Text(
          titles[_index],
          textAlign: TextAlign.center,
        ),
      ),

      body: IndexedStack(
        index: _index,
        children: pages,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: ImageIcon(
              AssetImage('assets/logo_frase.png'),
              size: 26,
            ),
            selectedIcon: ImageIcon(
              AssetImage('assets/logo_frase.png'),
              size: 28,
            ),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'News',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
