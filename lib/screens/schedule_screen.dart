import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<DaySchedule>> _futureSchedules;

  @override
  void initState() {
    super.initState();
    _futureSchedules = _loadEventsFromCsv();
  }

  Future<List<DaySchedule>> _loadEventsFromCsv() async {
    try {
      final csvString = await rootBundle.loadString('assets/rimun_calendario_prova.csv');

      final lines = csvString
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (lines.isEmpty) return [];

      final Map<String, List<EventEntry>> byDay = {};

      // salta header se presente
      int startIndex = 0;
      if (lines[0].toLowerCase().contains('day') &&
          lines[0].toLowerCase().contains('starting')) {
        startIndex = 1;
      }

      for (var i = startIndex; i < lines.length; i++) {
        final line = lines[i];
        final parts = line.split(',');
        if (parts.length < 5) {
          debugPrint('CSV: riga malformata "$line"');
          continue;
        }

        final dayStr = parts[0].trim();
        final startStr = parts[1].trim();
        final endStr = parts[2].trim();
        final description = parts[3].trim();
        final location = parts.sublist(4).join(',').trim();

        final startMinutes = _parseTimeToMinutes(startStr);
        final endMinutes = _parseTimeToMinutes(endStr);

        final entry = EventEntry(
          dayLabel: dayStr,
          startTimeLabel: startStr,
          endTimeLabel: endStr,
          startMinutes: startMinutes,
          endMinutes: endMinutes,
          description: description,
          location: location,
        );

        byDay.putIfAbsent(dayStr, () => []).add(entry);
      }

      final List<DaySchedule> result = [];
      byDay.forEach((day, events) {
        events.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
        result.add(DaySchedule(dayLabel: day, events: events));
      });

      return result;
    } catch (e, st) {
      debugPrint('ERRORE CSV: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  int _parseTimeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DaySchedule>>(
      future: _futureSchedules,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading schedule.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final days = snapshot.data ?? [];

        if (days.isEmpty) {
          return const Center(
            child: Text('No events scheduled.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 4,
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  'Day ${day.dayLabel}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${day.events.length} event${day.events.length == 1 ? '' : 's'}',
                ),
                childrenPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: day.events.map((event) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _EventCard(event: event),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}

class DaySchedule {
  final String dayLabel; // es. "28/10"
  final List<EventEntry> events;

  DaySchedule({
    required this.dayLabel,
    required this.events,
  });
}

class EventEntry {
  final String dayLabel;
  final String startTimeLabel;
  final String endTimeLabel;
  final int startMinutes;
  final int endMinutes;
  final String description;
  final String location;

  EventEntry({
    required this.dayLabel,
    required this.startTimeLabel,
    required this.endTimeLabel,
    required this.startMinutes,
    required this.endMinutes,
    required this.description,
    required this.location,
  });
}

class _EventCard extends StatelessWidget {
  final EventEntry event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.06),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Orario
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${event.startTimeLabel} - ${event.endTimeLabel}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
          const SizedBox(width: 12),
          // Descrizione + location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      child: Text(
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
          ),
        ],
      ),
    );
  }
}
