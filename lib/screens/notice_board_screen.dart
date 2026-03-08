import 'package:flutter/material.dart';
import 'package:rimun_app/api/models.dart';
import 'package:rimun_app/services/rimun_api_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class NoticeBoardScreen extends StatefulWidget {
  final ApiService apiService;
  final bool canManagePosts;

  const NoticeBoardScreen({
    super.key,
    required this.apiService,
    required this.canManagePosts,
  });

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  late Future<List<PostWithAuthor>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = widget.apiService.listPosts();
  }

  void _reload() {
    setState(() {
      _postsFuture = widget.apiService.listPosts();
    });
  }

  // ---------- DELETE ----------
  Future<void> _confirmAndDelete(BuildContext context, PostWithAuthor post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete news?'),
        content: Text('"${post.title}" will be permanently deleted.'),
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

    await widget.apiService.deletePost(post.id);
    _reload();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('News deleted')),
      );
    }
  }

  // ---------- EDIT ----------
  Future<void> _openEditDialog(BuildContext context, PostWithAuthor post) async {
    final titleCtrl = TextEditingController(text: post.title);
    final bodyCtrl = TextEditingController(text: post.body);
    bool isForPersons = post.isForPersons;
    bool isForSchools = post.isForSchools;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
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
                CheckboxListTile(
                  value: isForPersons,
                  onChanged: (v) => setState(() => isForPersons = v ?? false),
                  title: const Text('Visible to persons'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: isForSchools,
                  onChanged: (v) => setState(() => isForSchools = v ?? false),
                  title: const Text('Visible to schools'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
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

    if (title.isEmpty || body.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title and body cannot be empty')),
        );
      }
      return;
    }

    await widget.apiService.updatePost(
      postId: post.id,
      title: title,
      body: body,
      isForPersons: isForPersons,
      isForSchools: isForSchools,
    );
    _reload();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('News updated')),
      );
    }
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PostWithAuthor>>(
      future: _postsFuture,
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

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return const Center(child: Text('No news available.'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            // wait for the new future to finish so the spinner dismisses
            await _postsFuture;
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];

              // Build author line, e.g. "Jane Doe · Secretariat"
              String authorLine = '';
              if (post.authorName != null) {
                authorLine = post.authorName!;
                if (post.authorRole != null) {
                  authorLine += ' · ${post.authorRole}';
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white.withOpacity(0.06),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                  leading: const Icon(Icons.article_outlined, color: Colors.white),

                  title: Text(
                    post.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: authorLine.isNotEmpty
                      ? Text(authorLine, style: const TextStyle(color: Colors.white70))
                      : null,

                  // edit + delete only for users with permission
                  trailing: widget.canManagePosts
                      ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openEditDialog(context, post);
                            } else if (value == 'delete') {
                              _confirmAndDelete(context, post);
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
                      child: MarkdownBody(
                        data: post.body,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: const TextStyle(fontSize: 14, color: Colors.white),
                          a: const TextStyle(
                            color: Colors.lightBlueAccent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        onTapLink: (text, href, title) async {
                          if (href == null) return;
                          final uri = Uri.tryParse(href);
                          if (uri == null) return;
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                      ),
                    ),

                    // Audience tags visible to managers
                    if (widget.canManagePosts) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 6,
                          children: [
                            if (post.isForPersons)
                              const Chip(
                                label: Text('Persons', style: TextStyle(fontSize: 12)),
                                visualDensity: VisualDensity.compact,
                              ),
                            if (post.isForSchools)
                              const Chip(
                                label: Text('Schools', style: TextStyle(fontSize: 12)),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}