import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rimun_app/api/models.dart';
import 'package:rimun_app/services/rimun_api_service.dart';

class ScheduleScreen extends StatefulWidget {
  final ApiService apiService;

  const ScheduleScreen({super.key, required this.apiService});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<DaySchedule>> _futureSchedules;

  @override
  void initState() {
    super.initState();
    _futureSchedules = _loadEvents();
  }

  void _reload() {
    setState(() {
      _futureSchedules = _loadEvents();
    });
  }

  Future<List<DaySchedule>> _loadEvents() async {
    final events = await widget.apiService.listTimelineEvents();

    // Group by calendar day
    final Map<String, List<TimelineEvent>> byDay = {};
    final dateKeyFmt = DateFormat('yyyy-MM-dd');
    for (final e in events) {
      final dt = DateTime.tryParse(e.date);
      final key = dt != null ? dateKeyFmt.format(dt) : 'Unknown';
      byDay.putIfAbsent(key, () => []).add(e);
    }

    // Sort events within each day by date, then build DaySchedule list
    final result = <DaySchedule>[];
    final sortedKeys = byDay.keys.toList()..sort();

    final displayFmt = DateFormat('EEEE dd/MM/yyyy'); // e.g. "Friday 24/01/2026"

    for (final key in sortedKeys) {
      final dayEvents = byDay[key]!
        ..sort((a, b) => a.date.compareTo(b.date));

      // Pretty label from the date key
      final dt = DateTime.tryParse(key);
      final label = dt != null ? displayFmt.format(dt) : key;

      result.add(DaySchedule(dayLabel: label, dateKey: key, events: dayEvents));
    }

    return result;
  }

  bool _isToday(String dateKey) {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    return dateKey == todayKey;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DaySchedule>>(
      future: _futureSchedules,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
          return const Center(child: Text('No events scheduled.'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _futureSchedules;
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final isToday = _isToday(day.dateKey);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isToday ? 6 : 4,
                color: isToday
                    ? Colors.indigo.withOpacity(0.35)
                    : null,
                child: ExpansionTile(
                  key: PageStorageKey('day_${day.dateKey}'),
                  initiallyExpanded: isToday,
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    day.dayLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    '${day.events.length} event${day.events.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white70),
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
          ),
        );
      },
    );
  }
}

// ── Local grouping model ──────────────────────────────────────────────────

class DaySchedule {
  final String dayLabel; // display label, e.g. "Friday 24/01/2026"
  final String dateKey;  // sortable key, e.g. "2026-01-24"
  final List<TimelineEvent> events;

  DaySchedule({
    required this.dayLabel,
    required this.dateKey,
    required this.events,
  });
}

// ── Single event card ─────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final TimelineEvent event;

  const _EventCard({required this.event});

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'deadline':
        return Icons.timer_outlined;
      case 'ceremony':
        return Icons.celebration_outlined;
      case 'social':
        return Icons.groups_outlined;
      case 'session':
        return Icons.gavel_outlined;
      default:
        return Icons.event;
    }
  }

  Future<void> _openDocument(String path) async {
    final uri = Uri.tryParse(path);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract time from the date string
    final dt = DateTime.tryParse(event.date);
    final timeLabel = dt != null ? DateFormat('HH:mm').format(dt) : '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.06),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time + type icon
          Column(
            children: [
              Icon(_iconForType(event.type), size: 20, color: Colors.white70),
              if (timeLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 12),

          // Name + description + document link
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(fontSize: 16),
                ),
                if (event.description != null &&
                    event.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
                if (event.documentPath != null &&
                    event.documentPath!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _openDocument(event.documentPath!),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_file, size: 14, color: Colors.lightBlueAccent),
                        SizedBox(width: 4),
                        Text(
                          'View document',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.lightBlueAccent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}