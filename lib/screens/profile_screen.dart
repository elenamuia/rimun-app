import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../services/rimun_api_service.dart';
import '../api/models.dart';

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}
class ProfileScreen extends StatelessWidget {
  final ApiService api;
  final Future<void> Function() onLogout;

  const ProfileScreen({
    super.key,
    required this.api,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileData>(
      future: api.getMyProfile(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Failed to load profile: ${snap.error}'));
        }

        final p = snap.data!;
        final roleIcon = p.isSecretariat ? Icons.admin_panel_settings : Icons.badge;

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
                      const CircleAvatar(radius: 45, child: Icon(Icons.person, size: 50)),
                      const SizedBox(height: 16),
                      Text(
                        p.fullName.isNotEmpty ? p.fullName : 'Unknown user',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(p.email, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      _InfoRow(icon: roleIcon, text: 'Role: ${p.role.isNotEmpty ? p.role : p.group}'),
                      const Divider(height: 32),
                      _InfoRow(icon: Icons.school, text: p.school.isNotEmpty ? p.school : 'School not specified'),
                      const SizedBox(height: 12),
                      _InfoRow(icon: Icons.public, text: p.country.isNotEmpty ? p.country : 'Country not specified'),
                      const SizedBox(height: 12),
                      _InfoRow(icon: Icons.flag, text: p.delegation.isNotEmpty ? 'Delegation: ${p.delegation}' : 'Delegation not specified'),
                      const SizedBox(height: 12),
                      _InfoRow(icon: Icons.people, text: p.committee.isNotEmpty ? 'Committee: ${p.committee}' : 'Committee not specified'),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: () async => onLogout(),
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
      },
    );
  }
}