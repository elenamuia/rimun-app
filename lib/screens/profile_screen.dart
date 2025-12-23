import 'package:flutter/material.dart';
import '../models.dart';

class ProfileScreen extends StatelessWidget {
  final Student student;
  final Future<void> Function() onLogout;

  const ProfileScreen({
    super.key,
    required this.student,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 45,
                    child: Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '${student.name} ${student.surname}'.trim(),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    student.email,
                    textAlign: TextAlign.center,
                  ),

                  const Divider(height: 32),

                  _InfoRow(
                    icon: Icons.school,
                    text: student.school.isNotEmpty
                        ? student.school
                        : 'School not specified',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.public,
                    text: student.country.isNotEmpty
                        ? student.country
                        : 'Country not specified',
                  ),

                  const SizedBox(height: 28),

                  FilledButton.icon(
                    onPressed: () async {
                      // (opzionale) conferma logout
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Do you want to disonnect?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (ok == true) {
                        await onLogout();
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
