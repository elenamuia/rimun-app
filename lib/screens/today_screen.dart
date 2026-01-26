import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models.dart';
import '../services.dart';

class TodayScreen extends StatefulWidget {
  final Student student;
  final ScheduleService scheduleService;

  // ✅ News per HOME (alert/info)
  final NoticeService noticeService;
  final Stream<List<Notice>> homeNoticeStream;

  const TodayScreen({
    super.key,
    required this.student,
    required this.scheduleService,
    required this.noticeService,
    required this.homeNoticeStream,
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

  // ---------- NEWS HELPERS ----------
  Color _noticeCardColor(String type) {
    switch (type) {
      case 'alert':
        return Colors.red.withOpacity(0.22);
      case 'info':
        return Colors.lightBlueAccent.withOpacity(0.20);
      case 'ordinary':
      default:
        return Colors.white.withOpacity(0.06);
    }
  }

  IconData _noticeIcon(String type) {
    switch (type) {
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'info':
        return Icons.info_outline;
      case 'ordinary':
      default:
        return Icons.event;
    }
  }

  String _noticeTypeLabel(String type) {
    switch (type) {
      case 'alert':
        return 'Alert';
      case 'info':
        return 'Info';
      case 'ordinary':
      default:
        return 'Ordinary';
    }
  }

  // Toolbar helpers (bold/italic/link) for TextEditingController
  void _wrapSelection(TextEditingController c, String left, String right) {
    final text = c.text;
    final sel = c.selection;

    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;

    if (start == end) {
      final insert = '${left}testo${right}';
      c.text = text.replaceRange(start, end, insert);
      c.selection = TextSelection(
        baseOffset: start + left.length,
        extentOffset: start + left.length + 5,
      );
      return;
    }

    final selected = text.substring(start, end);
    final replaced = '$left$selected$right';
    c.text = text.replaceRange(start, end, replaced);
    c.selection =
        TextSelection(baseOffset: start, extentOffset: start + replaced.length);
  }

  void _insertLinkTemplate(TextEditingController c) {
    final text = c.text;
    final sel = c.selection;
    final pos = sel.isValid ? sel.start : text.length;

    const insert = '[testo](https://example.com)';
    c.text = text.replaceRange(pos, pos, insert);
    c.selection = TextSelection.collapsed(offset: pos + 1);
  }

  Future<void> _confirmAndDelete(BuildContext context, Notice notice) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete news?'),
        content: Text('“${notice.title}” will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await widget.noticeService.deleteNotice(notice.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('News deleted')),
      );
    }
  }

  Future<void> _openEditDialog(BuildContext context, Notice notice) async {
    final titleCtrl = TextEditingController(text: notice.title);
    final bodyCtrl = TextEditingController(text: notice.body);
    final recipientsCtrl =
        TextEditingController(text: notice.recipients.join(', '));

    String selectedType = (notice.type == 'alert' ||
            notice.type == 'info' ||
            notice.type == 'ordinary')
        ? notice.type
        : 'ordinary';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit news'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ type selector
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 6),
                RadioListTile<String>(
                  value: 'ordinary',
                  groupValue: selectedType,
                  onChanged: (v) =>
                      setState(() => selectedType = v ?? 'ordinary'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ordinary'),
                  secondary: const Icon(Icons.event),
                ),
                RadioListTile<String>(
                  value: 'alert',
                  groupValue: selectedType,
                  onChanged: (v) =>
                      setState(() => selectedType = v ?? 'ordinary'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Alert'),
                  secondary: const Icon(Icons.warning_amber_rounded),
                ),
                RadioListTile<String>(
                  value: 'info',
                  groupValue: selectedType,
                  onChanged: (v) =>
                      setState(() => selectedType = v ?? 'ordinary'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Info'),
                  secondary: const Icon(Icons.info_outline),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),

                // ✅ toolbar markdown
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Bold',
                      icon: const Icon(Icons.format_bold),
                      onPressed: () => _wrapSelection(bodyCtrl, '**', '**'),
                    ),
                    IconButton(
                      tooltip: 'Italic',
                      icon: const Icon(Icons.format_italic),
                      onPressed: () => _wrapSelection(bodyCtrl, '*', '*'),
                    ),
                    IconButton(
                      tooltip: 'Link',
                      icon: const Icon(Icons.link),
                      onPressed: () => _insertLinkTemplate(bodyCtrl),
                    ),
                  ],
                ),
                TextField(
                  controller: bodyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Body (Markdown supported)',
                  ),
                  maxLines: 6,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: recipientsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Recipients',
                    hintText: 'e.g. UNHRC, WHO, UNESCO (empty = everyone)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final title = titleCtrl.text.trim();
    final body = bodyCtrl.text.trim();
    final recipients = recipientsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (title.isEmpty || body.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title and body cannot be empty')),
        );
      }
      return;
    }

    await widget.noticeService.updateNotice(
      noticeId: notice.id,
      title: title,
      body: body,
      recipients: recipients,
      type: selectedType,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('News updated')),
      );
    }
  }

  // ---------- EVENTS (CSV) ----------
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

    int startIndex = 0;
    if (lines[0].toLowerCase().startsWith('day')) {
      startIndex = 1;
    }

    for (var i = startIndex; i < lines.length; i++) {
      final line = lines[i];
      final parts = line.split(',');
      if (parts.length < 6) continue;

      final dayStr = parts[0].trim();
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

    events.sort((a, b) => a.start.compareTo(b.start));
    return events;
  }

  DateTime? _parseDayToDate(String dayLabel) {
    try {
      if (dayLabel.contains('-') && !dayLabel.contains('/')) {
        return DateTime.parse(dayLabel);
      }

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
          return const Center(child: CircularProgressIndicator());
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
          for (final e in events) {
            if (!now.isBefore(e.start) && now.isBefore(e.end)) {
              ongoing = e;
              break;
            }
          }

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

          if (following == null && events.isNotEmpty) {
            following = events.first;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Welcome, ${widget.student.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              const _SectionTitle(title: 'Ongoing'),
              const SizedBox(height: 8),
              if (ongoing != null)
                _EventCardToday(event: ongoing)
              else
                const _EmptyCard(message: 'No event in progress'),

              const SizedBox(height: 24),

              const _SectionTitle(title: 'Following'),
              const SizedBox(height: 8),
              if (following != null)
                _EventCardToday(event: following)
              else
                const _EmptyCard(message: 'No upcoming event'),

              const SizedBox(height: 24),

              const _SectionTitle(title: 'Announcements'),
              const SizedBox(height: 8),

              StreamBuilder<List<Notice>>(
                stream: widget.homeNoticeStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snap.hasError) {
                    return Text(
                      'Error loading announcements.\n${snap.error}',
                      textAlign: TextAlign.center,
                    );
                  }

                  final notices = snap.data ?? [];
                  if (notices.isEmpty) {
                    return const _EmptyCard(message: 'No announcements');
                  }

                  return ListView.builder(
                    itemCount: notices.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final notice = notices[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: _noticeCardColor(notice.type),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Icon(
                            _noticeIcon(notice.type),
                            color: Colors.white,
                          ),
                          title: Text(
                            notice.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: widget.student.isSecretariat
                              ? Text(
                                  _noticeTypeLabel(notice.type),
                                  style: const TextStyle(color: Colors.white70),
                                )
                              : null,
                          trailing: widget.student.isSecretariat
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _openEditDialog(context, notice);
                                    } else if (value == 'delete') {
                                      _confirmAndDelete(context, notice);
                                    }
                                  },
                                  itemBuilder: (ctx) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                          childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: MarkdownBody(
                                data: notice.body,
                                selectable: true,
                                styleSheet: MarkdownStyleSheet.fromTheme(
                                  Theme.of(context),
                                ).copyWith(
                                  p: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  a: const TextStyle(
                                    color: Colors.lightBlueAccent,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                onTapLink: (text, href, title) async {
                                  if (href == null) return;
                                  final uri = Uri.tryParse(href);
                                  if (uri == null) return;
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                              ),
                            ),
                            if (widget.student.isSecretariat &&
                                notice.recipients.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Recipients: ${notice.recipients.join(', ')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            event.description,
            style: const TextStyle(fontSize: 16),
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
