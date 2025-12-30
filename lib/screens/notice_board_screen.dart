import 'package:flutter/material.dart';
import '../models.dart';

class NoticeBoardScreen extends StatelessWidget {
  final Stream<List<Notice>> noticeStream;

  const NoticeBoardScreen({
    super.key,
    required this.noticeStream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Notice>>(
      stream: noticeStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
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
          return const Center(
            child: Text('No news available.'),
          );
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  if (notice.recipients.isNotEmpty) ...[
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
