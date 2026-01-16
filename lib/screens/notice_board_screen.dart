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

                // ✅ delete solo per secretariat
                trailing: student.isSecretariat
                    ? PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _confirmAndDelete(context, notice);
                          }
                        },
                        itemBuilder: (ctx) => const [
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
