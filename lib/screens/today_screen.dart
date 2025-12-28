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
    // Pagina "vuota" per ora
    return const Center(
      child: Text(
        'Today page coming soon',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
