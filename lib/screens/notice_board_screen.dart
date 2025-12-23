// lib/screens/notice_board_screen.dart
import 'package:flutter/material.dart';
import '../models.dart';

class NoticeBoardScreen extends StatelessWidget {
  final Stream<List<Notice>> noticeStream;

  const NoticeBoardScreen({super.key, required this.noticeStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Notice>>(
      stream: noticeStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final notices = snapshot.data!;
        if (notices.isEmpty) {
          return const Center(child: Text('No news available!'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notices.length,
          itemBuilder: (context, i) {
            final n = notices[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(n.title),
                subtitle: Text(n.body),
                trailing: Text(
                  '${n.createdAt.day.toString().padLeft(2, '0')}/'
                  '${n.createdAt.month.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
