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
    final roleText = student.role; // Delegate / Secretariat
    final roleIcon =
        student.isSecretariat ? Icons.admin_panel_settings : Icons.badge;

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
                  // 🔹 Avatar
                  const CircleAvatar(
                    radius: 45,
                    child: Icon(Icons.person, size: 50),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Nome
                  Text(
                    '${student.name} ${student.surname}'.trim(),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // 🔹 Email
                  Text(
                    student.email,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // ✅ Role (con icona)
                  _InfoRow(
                    icon: roleIcon,
                    text: 'Role: $roleText',
                  ),

                  const Divider(height: 32),

                  // 🔹 School
                  _InfoRow(
                    icon: Icons.school,
                    text: student.school.isNotEmpty
                        ? student.school
                        : 'School not specified',
                  ),

                  const SizedBox(height: 12),

                  // 🔹 Country
                  _InfoRow(
                    icon: Icons.public,
                    text: student.country.isNotEmpty
                        ? student.country
                        : 'Country not specified',
                  ),

                  const SizedBox(height: 12),

                  // 🔹 Delegation
                  _InfoRow(
                    icon: Icons.flag,
                    text: student.delegation.isNotEmpty
                        ? 'Delegation: ${student.delegation}'
                        : 'Delegation not specified',
                  ),

                  const SizedBox(height: 12),

                  // 🔹 Committee
                  _InfoRow(
                    icon: Icons.people,
                    text: student.committee.isNotEmpty
                        ? 'Committee: ${student.committee}'
                        : 'Committee not specified',
                  ),

                  const SizedBox(height: 28),

                  // 🔹 Logout button
                  FilledButton.icon(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Do you want to disconnect?'),
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
