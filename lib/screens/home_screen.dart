import 'package:flutter/material.dart';
import 'package:rimun_app/api/models.dart';
import 'package:rimun_app/services/rimun_api_service.dart';

import 'today_screen.dart';
import 'map_screen.dart';
import 'notice_board_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;
  final Future<void> Function() onLogout;

  const HomeScreen({
    super.key,
    required this.apiService,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  late final Future<PersonProfileDTO> _futureProfile;

  @override
  void initState() {
    super.initState();
    _futureProfile = widget.apiService.getMyPersonProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PersonProfileDTO>(
      future: _futureProfile,
      builder: (context, profileSnap) {
        if (profileSnap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F245B),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (profileSnap.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F245B),
            body: Center(
              child: Text(
                'Failed to load profile:\n${profileSnap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final profile = profileSnap.data!;
        final canManagePosts = profile.canManagePosts;

        final pages = [
          TodayScreen(apiService: widget.apiService),
          ScheduleScreen(apiService: widget.apiService,),
          const MapScreen(),
          NoticeBoardScreen(
            apiService: widget.apiService,
            canManagePosts: canManagePosts,
          ),
          ProfileScreen(
            api: widget.apiService,
            onLogout: widget.onLogout,
          ),
        ];

        final bool showFab = canManagePosts && (_index == 0 || _index == 3);

        return Scaffold(
          backgroundColor: const Color(0xFF0F245B),
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo_frase.png',
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                const Text(
                  'RIMUN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          body: IndexedStack(
            index: _index,
            children: pages,
          ),
          floatingActionButton: showFab
              ? FloatingActionButton(
                  onPressed: _openCreatePostDialog,
                  backgroundColor: Colors.lightBlueAccent,
                  child: const Icon(Icons.add),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: ImageIcon(AssetImage('assets/logo_frase.png'), size: 26),
                selectedIcon: ImageIcon(AssetImage('assets/logo_frase.png'), size: 28),
                label: 'Today',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_outlined),
                selectedIcon: Icon(Icons.event),
                label: 'Schedule',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: 'News',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCreatePostDialog() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    bool isForPersons = true;
    bool isForSchools = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              title: const Text('Create news'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        maxLength: 100,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: bodyController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Body (Markdown supported)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Visible to',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      CheckboxListTile(
                        title: const Text('Persons (delegates, staff, etc.)'),
                        value: isForPersons,
                        onChanged: (v) => setSt(() => isForPersons = v ?? true),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text('Schools'),
                        value: isForSchools,
                        onChanged: (v) => setSt(() => isForSchools = v ?? false),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
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
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title and body are required')),
        );
      }
      return;
    }

    // Confirmation dialog
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.amber,
        title: const Text('Confirm', style: TextStyle(color: Colors.black)),
        content: const Text(
          'Are you sure you want to create this post?',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.amber,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await widget.apiService.createPost(
        title: title,
        body: body,
        isForPersons: isForPersons,
        isForSchools: isForSchools,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    }
  }
}