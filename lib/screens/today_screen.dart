import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../services/rimun_api_service.dart';
import '../api/models.dart';

class TodayScreen extends StatefulWidget {
  final ApiService apiService;

  const TodayScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late Future<_TodayData> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _loadAll();
  }

  /// Load profile, timeline events, and posts in parallel.
  Future<_TodayData> _loadAll() async {
    final results = await Future.wait([
      widget.apiService.getMyPersonProfile(),
      widget.apiService.listTimelineEvents(),
      widget.apiService.listPosts(),
    ]);

    return _TodayData(
      profile: results[0] as PersonProfileDTO,
      events: results[1] as List<TimelineEvent>,
      posts: results[2] as List<PostWithAuthor>,
    );
  }

  void _refresh() {
    setState(() {
      _futureData = _loadAll();
    });
  }

  // ---------- GREETING HELPERS ----------
  static const Map<String, List<String>> _messagesByGreeting = {
    "Goodmorning": [
      "Goodmorning, [Nome]! Ready to craft resolutions and make global change today?",
      "Goodmorning, [Nome]! New debates are waiting — time to represent your delegation!",
      "Goodmorning, [Nome]! Grab your notes and let's start with purpose.",
      "Goodmorning, [Nome]! Let the diplomacy begin!",
    ],
    "GoodAfternoon": [
      "GoodAfternoon, [Nome]! How's your committee strategy looking?",
      "GoodAfternoon, [Nome]! Keep your speeches sharp and ideas sharper.",
      "GoodAfternoon, [Nome]! Time for alliances and breakthrough solutions.",
    ],
    "GoodEvening": [
      "GoodEvening, [Nome]! Great work so far, let's refine your final arguments.",
      "GoodEvening, [Nome]! A round of applause for today's debates — rest up.",
      "GoodEvening, [Nome]! Reflect on today's diplomacy and recharge for tomorrow.",
      "GoodEvening, [Nome]! Ready for tomorrow's challenge?",
    ],
    "Goodnight": [
      "Goodnight, [Nome]! Even diplomats need rest — tomorrow brings new sessions.",
      "Goodnight, [Nome]! Put your phone down — tomorrow's resolutions await!",
      "Goodnight, [Nome]! Peaceful dreams of global solutions.",
      "Goodnight, [Nome]! Recharge your energy for decisive debates ahead.",
    ],
  };

  String _greetingLabel(DateTime now) {
    final h = now.hour;
    final m = now.minute;
    bool atOrAfter(int hh, int mm) => (h > hh) || (h == hh && m >= mm);
    bool atOrBefore(int hh, int mm) => (h < hh) || (h == hh && m <= mm);
    if (atOrAfter(6, 0) && atOrBefore(12, 0)) return "Goodmorning";
    if (atOrAfter(12, 1) && atOrBefore(18, 0)) return "GoodAfternoon";
    if (atOrAfter(18, 1) && atOrBefore(22, 0)) return "GoodEvening";
    return "Goodnight";
  }

  int _dayOfYear(DateTime d) {
    final start = DateTime(d.year, 1, 1);
    return d.difference(start).inDays + 1;
  }

  String _pickDailyFullMessage({
    required String userName,
    required int stableSalt,
    required DateTime now,
  }) {
    final greeting = _greetingLabel(now);
    final list = _messagesByGreeting[greeting] ?? const <String>["Hi, [Nome]!"];
    final seed = (_dayOfYear(now) * 1000) ^ greeting.hashCode ^ stableSalt;
    final idx = seed.abs() % list.length;
    return list[idx].replaceAll("[Nome]", userName);
  }

  String _extractSubMessage({
    required String fullMessage,
    required String greeting,
    required String userName,
  }) {
    final prefix = "$greeting, $userName!";
    if (fullMessage.startsWith(prefix)) {
      final rest = fullMessage.substring(prefix.length).trimLeft();
      return rest.isEmpty ? "" : rest;
    }
    return fullMessage;
  }

  // ---------- EDIT / DELETE POST ----------
  void _wrapSelection(TextEditingController c, String left, String right) {
    final text = c.text;
    final sel = c.selection;
    if (!sel.isValid) return;
    final start = sel.start < 0 ? 0 : sel.start;
    final end = sel.end < 0 ? 0 : sel.end;
    final selected = text.substring(start, end);
    final replaced = "$left$selected$right";
    final newText = text.replaceRange(start, end, replaced);
    c.value = c.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + replaced.length),
    );
  }

  void _insertLinkTemplate(TextEditingController c) {
    final text = c.text;
    final sel = c.selection;
    final insertAt = sel.isValid ? sel.start : text.length;
    const template = "[Link text](https://example.com)";
    final newText = text.replaceRange(insertAt, insertAt, template);
    c.value = c.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: insertAt + template.length),
    );
  }

  Future<void> _openEditDialog(BuildContext context, PostWithAuthor post) async {
    final titleCtrl = TextEditingController(text: post.title);
    final bodyCtrl = TextEditingController(text: post.body);
    bool isForPersons = post.isForPersons;
    bool isForSchools = post.isForSchools;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Edit post'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
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
                  CheckboxListTile(
                    title: const Text('Visible to persons'),
                    value: isForPersons,
                    onChanged: (v) => setSt(() => isForPersons = v ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Visible to schools'),
                    value: isForSchools,
                    onChanged: (v) => setSt(() => isForSchools = v ?? false),
                  ),
                ],
              ),
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
    if (title.isEmpty || body.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title and body cannot be empty')),
        );
      }
      return;
    }

    try {
      await widget.apiService.updatePost(
        postId: post.id,
        title: title,
        body: body,
        isForPersons: isForPersons,
        isForSchools: isForSchools,
      );
      _refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post updated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating post: $e')),
        );
      }
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, PostWithAuthor post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This action cannot be undone.'),
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

    try {
      await widget.apiService.deletePost(post.id);
      _refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: $e')),
        );
      }
    }
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TodayData>(
      future: _futureData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading data.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final data = snapshot.data!;
        final profile = data.profile;
        final events = data.events;
        final posts = data.posts;
        final now = DateTime.now();
        
        
        TimelineEvent? upcoming;
        for (final e in events) {
          final dt = e.dateTime;
          if (dt != null && dt.isAfter(now)) {
            final upDt = upcoming?.dateTime;
            if (upDt == null || dt.isBefore(upDt)) {
              upcoming = e;
            }
          }
        }
        // Fallback: show the most recent past event
        upcoming ??= events.isNotEmpty ? events.last : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),

              // Greeting
              Builder(
                builder: (context) {
                  final nowLocal = DateTime.now();
                  final greeting = _greetingLabel(nowLocal);
                  final full = _pickDailyFullMessage(
                    userName: profile.name,
                    stableSalt: profile.id,
                    now: nowLocal,
                  );
                  final sub = _extractSubMessage(
                    fullMessage: full,
                    greeting: greeting,
                    userName: profile.name,
                  );
                  return Column(
                    children: [
                      Text(
                        '$greeting, ${profile.name}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sub,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Next event
              const _SectionTitle(title: 'Next Event'),
              const SizedBox(height: 8),
              if (upcoming != null)
                _TimelineEventCard(event: upcoming)
              else
                const _EmptyCard(message: 'No upcoming events'),

              const SizedBox(height: 24),

              // Posts / Announcements
              const _SectionTitle(title: 'Announcements'),
              const SizedBox(height: 8),
              if (posts.isEmpty)
                const _EmptyCard(message: 'No announcements')
              else
                ListView.builder(
                  itemCount: posts.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.white.withOpacity(0.06),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: const Icon(Icons.campaign_outlined,
                            color: Colors.white),
                        title: Text(
                          post.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        subtitle: post.authorName != null
                            ? Text(
                                '${post.authorName!}'
                                '${post.authorRole != null ? ' • ${post.authorRole}' : ''}',
                                style: const TextStyle(color: Colors.white70),
                              )
                            : null,
                        trailing: profile.canManagePosts
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openEditDialog(context, post);
                                  } else if (value == 'delete') {
                                    _confirmAndDelete(context, post);
                                  }
                                },
                                itemBuilder: (ctx) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(children: [
                                      Icon(Icons.edit_outlined),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(children: [
                                      Icon(Icons.delete_outline),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ]),
                                  ),
                                ],
                              )
                            : null,
                        childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: MarkdownBody(
                              data: post.body,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                      Theme.of(context))
                                  .copyWith(
                                p: const TextStyle(
                                    fontSize: 14, color: Colors.white),
                                a: const TextStyle(
                                  color: Colors.lightBlueAccent,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              onTapLink: (text, href, title) async {
                                if (href == null) return;
                                final uri = Uri.tryParse(href);
                                if (uri == null) return;
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              },
                            ),
                          ),
                        ],
                      ),
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

// ---------- HELPER CLASSES ----------

class _TodayData {
  final PersonProfileDTO profile;
  final List<TimelineEvent> events;
  final List<PostWithAuthor> posts;

  _TodayData({
    required this.profile,
    required this.events,
    required this.posts,
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
        color: Colors.white,
      ),
    );
  }
}

class _TimelineEventCard extends StatelessWidget {
  final TimelineEvent event;
  const _TimelineEventCard({required this.event});

  String _formatDate(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year} • $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
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
            _formatDate(DateTime.tryParse(event.date) ?? DateTime.now()),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            event.name,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event.description!,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              event.type,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
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
        style: const TextStyle(fontSize: 14, color: Colors.white70),
      ),
    );
  }
}