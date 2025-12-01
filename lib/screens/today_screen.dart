// lib/screens/today_screen.dart
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
    return FutureBuilder<List<EventItem>>(
      future: scheduleService.getTodayEventsForStudent(student.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Errore nel caricare il programma.'));
        }
        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return const Center(
            child: Text('Oggi non ci sono eventi assegnati.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final e = events[index];
            final start = TimeOfDay.fromDateTime(e.startTime);
            final end = TimeOfDay.fromDateTime(e.endTime);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(e.title),
                subtitle: Text(
                  '${e.location}\n${start.format(context)} - ${end.format(context)}',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
