import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../services.dart';

class TodayScreen extends StatefulWidget {
  final Student student;
  final ScheduleService scheduleService; // lo teniamo per compatibilità

  const TodayScreen({
    super.key,
    required this.student,
    required this.scheduleService,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late Future<List<_TodayEvent>> _futureEvents;

  @override
  void initState() {
    super.initState();
    _futureEvents = _loadEventsFromCsv();
  }

  Future<List<_TodayEvent>> _loadEventsFromCsv() async {
    final csvString =
        await rootBundle.loadString('assets/rimun_calendario_prova.csv');

    final lines = csvString
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    final List<_TodayEvent> events = [];

    // salta header se la prima riga è l'header
    int startIndex = 0;
    if (lines[0].toLowerCase().startsWith('day')) {
      startIndex = 1;
    }

    for (var i = startIndex; i < lines.length; i++) {
      final line = lines[i];
      final parts = line.split(',');
      if (parts.length < 6) {
        // ora ci aspettiamo: day, start, end, desc, location, link
        continue;
      }

      final dayStr = parts[0].trim(); // es "23/03/2026"
      final startStr = parts[1].trim();
      final endStr = parts[2].trim();
      final description = parts[3].trim();
      final location = parts[4].trim();
      final link = parts[5].trim();

      final date = _parseDayToDate(dayStr);
      if (date == null) continue;

      final startTime = _parseTime(startStr);
      final endTime = _parseTime(endStr);

      if (startTime == null || endTime == null) continue;

      final startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        startTime.hour,
        startTime.minute,
      );
      final endDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        endTime.hour,
        endTime.minute,
      );

      events.add(
        _TodayEvent(
          dayLabel: dayStr,
          start: startDateTime,
          end: endDateTime,
          startLabel: startStr,
          endLabel: endStr,
          description: description,
          location: location,
          link: link,
        ),
      );
    }

    // ordina tutti gli eventi per data/ora
    events.sort((a, b) => a.start.compareTo(b.start));
    return events;
  }

  DateTime? _parseDayToDate(String dayLabel) {
    try {
      // Caso 1: formato ISO "2026-03-23"
      if (dayLabel.contains('-')) {
        return DateTime.parse(dayLabel);
      }

      // Caso 2: formato "23/03/2026"
      if (dayLabel.contains('/')) {
        final parts = dayLabel.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  TimeOfDay? _parseTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return null;
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_TodayEvent>>(
      future: _futureEvents,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading today events.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final events = snapshot.data ?? [];
        final now = DateTime.now();

        _TodayEvent? ongoing;
        _TodayEvent? following;

        if (events.isNotEmpty) {
          // trova evento in corso
          for (final e in events) {
            if (!now.isBefore(e.start) && now.isBefore(e.end)) {
              ongoing = e;
              break;
            }
          }

          // trova evento successivo
          if (ongoing != null) {
            for (final e in events) {
              if (e.start.isAfter(ongoing.end)) {
                following = e;
                break;
              }
            }
          } else {
            for (final e in events) {
              if (e.start.isAfter(now)) {
                following = e;
                break;
              }
            }
          }

          // fallback: se non c'è nessun evento futuro, mostra almeno il primo
          if (following == null && events.isNotEmpty) {
            following = events.first;
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // 🔹 Welcome, Nome
              Text(
                'Welcome, ${widget.student.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // 🔹 Ongoing
              const _SectionTitle(title: 'Ongoing'),
              const SizedBox(height: 8),
              if (ongoing != null)
                _EventCardToday(event: ongoing)
              else
                const _EmptyCard(message: 'No event in progress'),

              const SizedBox(height: 24),

              // 🔹 Following
              const _SectionTitle(title: 'Following'),
              const SizedBox(height: 8),
              if (following != null)
                _EventCardToday(event: following)
              else
                const _EmptyCard(message: 'No upcoming event'),
            ],
          ),
        );
      },
    );
  }
}

class _TodayEvent {
  final String dayLabel;
  final DateTime start;
  final DateTime end;
  final String startLabel;
  final String endLabel;
  final String description;
  final String location;
  final String link;

  _TodayEvent({
    required this.dayLabel,
    required this.start,
    required this.end,
    required this.startLabel,
    required this.endLabel,
    required this.description,
    required this.location,
    required this.link,
  });
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _EventCardToday extends StatelessWidget {
  final _TodayEvent event;

  const _EventCardToday({required this.event});

  Future<void> _openLink() async {
    if (event.link.isEmpty) return;
    final uri = Uri.tryParse(event.link);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationText = Text(
      event.location,
      style: const TextStyle(
        fontSize: 13,
        color: Colors.white70,
        decoration: TextDecoration.underline,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.08),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${event.dayLabel} • ${event.startLabel} - ${event.endLabel}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            event.description,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.place, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: event.link.isNotEmpty
                    ? InkWell(
                        onTap: _openLink,
                        child: locationText,
                      )
                    : Text(
                        event.location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.04),
      ),
      padding: const EdgeInsets.all(12),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
    );
  }
}
