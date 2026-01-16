import 'package:flutter/material.dart';
import '../models.dart';
import '../services.dart';

class NoticeBoardScreen extends StatelessWidget {
  final Student student;
  final NoticeService noticeService;
  final Stream<List<Notice>> noticeStream;

  const NoticeBoardScreen({
    super.key,
    required this.student,
    required this.noticeService,
    required this.noticeStream,
  });

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

    await noticeService.deleteNotice(notice.id);

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

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit news'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(labelText: 'Body'),
                maxLines: 5,
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

    await noticeService.updateNotice(
      noticeId: notice.id,
      title: title,
      body: body,
      recipients: recipients,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('News updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Notice>>(
      stream: noticeStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading news.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final notices = snapshot.data ?? [];

        if (notices.isEmpty) {
          return const Center(child: Text('No news available.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notices.length,
          itemBuilder: (context, index) {
            final notice = notices[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.white.withOpacity(0.06),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  notice.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                // ✅ edit + delete solo per secretariat
                trailing: student.isSecretariat
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

                childrenPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      notice.body,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  // ✅ Recipients visibili SOLO al secretariat
                  if (student.isSecretariat && notice.recipients.isNotEmpty) ...[
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
    );
  }
}
