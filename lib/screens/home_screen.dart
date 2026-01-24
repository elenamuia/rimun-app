import 'package:flutter/material.dart';
import '../models.dart';
import '../services.dart';
import '../services/committee_service.dart';

import 'today_screen.dart';
import 'map_screen.dart';
import 'notice_board_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';

class HomeScreen extends StatefulWidget {
  final Student student;
  final Future<void> Function() onLogout;

  const HomeScreen({
    super.key,
    required this.student,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _scheduleService = ScheduleService();
  final _noticeService = NoticeService();

  // 🔹 Committees/rooms dal CSV (una sola lettura)
  final _committeeService = CommitteeService();
  late final Future<CommitteeData> _futureCommittees;

  @override
  void initState() {
    super.initState();
    _futureCommittees = _committeeService.loadCommittees();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayScreen(
        student: widget.student,
        scheduleService: _scheduleService,
      ),
      const ScheduleScreen(),
      const MapScreen(),
      NoticeBoardScreen(
        student: widget.student,
        noticeService: _noticeService,
        noticeStream: _noticeService.listenNoticesForStudent(widget.student),
      ),
      ProfileScreen(
        student: widget.student,
        onLogout: widget.onLogout,
      ),
    ];

    final bool canCreateNews =
        widget.student.isSecretariat && (_index == 0 || _index == 3);

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

      // 🔹 FAB "+" solo per segretariato in Today e News
      floatingActionButton: canCreateNews
          ? FloatingActionButton(
              onPressed: _openCreateNoticeDialog,
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
            icon: ImageIcon(
              AssetImage('assets/logo_frase.png'),
              size: 26,
            ),
            selectedIcon: ImageIcon(
              AssetImage('assets/logo_frase.png'),
              size: 28,
            ),
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
  }

  Future<void> _openCreateNoticeDialog() async {
    // 🔹 Prendo le opzioni destinatari dal CSV (sincronizzate con MapScreen)
    final committeeData = await _futureCommittees;
    final recipientOptions = committeeData.options;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final Set<String> selectedRecipients = {};

    // ✅ NEW: tipo news
    String selectedType = 'ordinary';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Create news'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ Tipo news
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
                      onChanged: (v) =>
                          setState(() => selectedType = v ?? 'ordinary'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ordinary'),
                      secondary: const Icon(Icons.event),
                    ),
                    RadioListTile<String>(
                      value: 'alert',
                      groupValue: selectedType,
                      onChanged: (v) =>
                          setState(() => selectedType = v ?? 'ordinary'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Alert'),
                      secondary: const Icon(Icons.warning_amber_rounded),
                    ),
                    RadioListTile<String>(
                      value: 'info',
                      groupValue: selectedType,
                      onChanged: (v) =>
                          setState(() => selectedType = v ?? 'ordinary'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Info'),
                      secondary: const Icon(Icons.info_outline),
                    ),
                    const SizedBox(height: 12),

                    // Titolo
                    TextField(
                      controller: titleController,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Descrizione
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Destinatari (multi-selezione)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recipients',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (recipientOptions.isEmpty)
                      const Text('No recipients available (CSV empty).')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recipientOptions.map((r) {
                          final selected = selectedRecipients.contains(r);
                          return FilterChip(
                            label: Text(r),
                            selected: selected,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  selectedRecipients.add(r);
                                } else {
                                  selectedRecipients.remove(r);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Crea news'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final title = titleController.text.trim();
    final body = descriptionController.text.trim();
    final recipients = selectedRecipients.toList();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and description are required'),
        ),
      );
      return;
    }

    // 🔹 Banner giallo di conferma
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.amber,
        content: const Text('Sei sicuro di voler procedere?'),
        action: SnackBarAction(
          label: 'Conferma',
          textColor: Colors.black,
          onPressed: () async {
            await _noticeService.createNotice(
              author: widget.student,
              title: title,
              body: body,
              recipients: recipients,
              type: selectedType, // ✅ NEW
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('News creata'),
              ),
            );
          },
        ),
      ),
    );
  }
}
