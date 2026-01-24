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

  // ---------- STYLE HELPERS ----------
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
        return Icons.warning_amber_rounded; // attenzione
      case 'info':
        return Icons.info_outline; // info
      case 'ordinary':
      default:
        return Icons.event; // calendario
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

    // ✅ NEW: type
    String selectedType =
        (notice.type == 'alert' || notice.type == 'info' || notice.type == 'ordinary')
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
                // ✅ Type selector (solo secretariat vede l'edit comunque)
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
                  onChanged: (v) => setState(() => selectedType = v ?? 'ordinary'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ordinary'),
                  secondary: const Icon(Icons.event),
                ),
                RadioListTile<String>(
                  value: 'alert',
                  groupValue: selectedType,
                  onChanged: (v) => setState(() => selectedType = v ?? 'ordinary'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Alert'),
                  secondary: const Icon(Icons.warning_amber_rounded),
                ),
                RadioListTile<String>(
                  value: 'info',
                  groupValue: selectedType,
                  onChanged: (v) => setState(() => selectedType = v ?? 'ordinary'),
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
      type: selectedType, // ✅ NEW
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
              color: _noticeCardColor(notice.type),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                // ✅ Icona a sinistra
                leading: Icon(
                  _noticeIcon(notice.type),
                  color: Colors.white,
                ),

                title: Text(
                  notice.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                // (opzionale ma carino): label tipo sotto al titolo
                subtitle: student.isSecretariat
                ? Text(
                    _noticeTypeLabel(notice.type),
                    style: const TextStyle(color: Colors.white70),
                  )
                : null,


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
