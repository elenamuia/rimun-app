import 'package:flutter/material.dart';
import '../models.dart';
import '../services.dart';
import 'today_screen.dart';
import 'map_screen.dart';
import 'notice_board_screen.dart';
import 'profile_screen.dart';

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
      const MapScreen(),
      NoticeBoardScreen(
        noticeStream: _noticeService.listenNotices(),
      ),
      ProfileScreen(
        student: widget.student,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F245B),
      appBar: AppBar(
        centerTitle: true,
        title: Text('Welcome, ${widget.student.name}'),
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
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
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
