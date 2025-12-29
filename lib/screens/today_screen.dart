import 'package:flutter/material.dart';
import '../models.dart';
import '../services.dart';

class TodayScreen extends StatelessWidget {
  final Student student;
  final ScheduleService scheduleService;

  const TodayScreen({
    super.key,
    required this.student,
    required this.scheduleService,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Welcome, ${student.name}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Have a great conference!',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
