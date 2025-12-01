// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models.dart';
import '../services.dart';
import 'today_screen.dart';
import 'map_screen.dart';
import 'notice_board_screen.dart';

class HomeScreen extends StatefulWidget {
  final Student student;

  const HomeScreen({super.key, required this.student});

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
      MapScreen(),
      NoticeBoardScreen(
        noticeStream: _noticeService.listenNotices(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Buongiorno, ${widget.student.name}'),
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Oggi',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mappa',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Bacheca',
          ),
        ],
      ),
    );
  }
}
