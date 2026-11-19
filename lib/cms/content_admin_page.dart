import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared/ui_kit.dart';
import '../theme.dart';
import '../widgets.dart';
import 'editable.dart';
import 'site_content.dart';

SiteContentStore get _store => SiteContentStore.instance;

/// Super admin: edit website text and photos, hide sections, and add or
/// remove extra pages.
class ContentAdminPage extends StatelessWidget {
  const ContentAdminPage({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) => PageWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            'Website content',
            eyebrow: 'Super admin',
            subtitle:
                'Change the words and photos on the website, hide sections you do not need, and add new pages. Changes go live as soon as you save.',
          ),
          if (_store.lastError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Tok.s4),
              child: Text(
                'Could not load saved content: ${_store.lastError}',
                style: const TextStyle(color: Tok.danger),
              ),
            ),
          ResponsiveGrid(
            children: [
              _StepCard(
                icon: Icons.edit_note_rounded,
                title: 'Edit text and photos',
                text:
                    'Open a page, tap “Edit this page” at the bottom left, then tap any gold-outlined text or “Change image”.',
                action: 'Edit the home page',
                onPressed: () {
                  _store.editing = true;
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                },
              ),
              _StepCard(
                icon: Icons.add_to_photos_outlined,
                title: 'Add a page',
                text:
                    'Create a simple page with a photo, heading, text and a button. It appears in the footer and the phone menu.',
                action: 'Add a page',
                onPressed: () => _editPage(context, null),
              ),
              _StepCard(
                icon: Icons.restart_alt_rounded,
                title: 'Undo all text and photo changes',
                text:
                    '${_store.texts.length} text and ${_store.images.length} photo changes, ${_store.hidden.length} hidden sections. Extra pages are kept.',
                action: 'Reset changes',
                onPressed:
                    _store.texts.isEmpty &&
                        _store.images.isEmpty &&
                        _store.hidden.isEmpty
                    ? null
                    : () => _confirmReset(context),
              ),
            ],
          ),
          const SizedBox(height: Tok.s6),
          DashboardPanel(
            title: 'Extra pages',
            icon: Icons.article_outlined,
            child: _store.pages.isEmpty
                ? const Text(
                    'No extra pages yet. Use “Add a page” to create one.',
                  )
                : Column(
                    children: [
                      for (final p in _store.pages)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(Tok.rSm),
                            child: Image(
                              image: siteImageProvider(p.image),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          ),
                          title: Text(p.title),
                          subtitle: Text(
                            [
                              p.route,
                              p.published ? 'Published' : 'Draft',
                              if (p.showInMenu) 'In menu',
                            ].join(' · '),
                          ),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                tooltip: 'Open ${p.title}',
                                icon: const Icon(Icons.open_in_new_rounded),
                                onPressed: () =>
                                    Navigator.pushNamed(context, p.route),
                              ),
                              IconButton(
                                tooltip: 'Edit ${p.title}',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _editPage(context, p),
                              ),
                              IconButton(
                                tooltip: 'Delete ${p.title}',
                                icon: const Icon(Icons.delete_outline),
                                color: Tok.danger,
                                onPressed: () => _confirmDelete(context, p),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: Tok.s5),
          DashboardPanel(
            title: 'Hidden sections',
            icon: Icons.visibility_off_outlined,
            child: _store.hidden.isEmpty
                ? const Text('Every section is visible.')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in _store.hidden)
                        InputChip(
                          label: Text(_sectionName(key)),
                          deleteIcon: const Icon(Icons.visibility_outlined),
                          deleteButtonTooltipMessage: 'Show again',
                          onDeleted: () => _store.setHidden(key, false),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: Tok.s8),
        ],
      ),
    ),
  );

  static String _sectionName(String key) {
    final last = key.split('.').last.replaceAll('-', ' ');
    return last.isEmpty ? key : last[0].toUpperCase() + last.substring(1);
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Undo all text and photo changes?'),
        content: const Text(
          'Every edited heading, paragraph and photo goes back to the original, and hidden sections show again. Extra pages stay. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Tok.danger),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Reset changes'),
          ),
        ],
      ),
    );
    if (ok == true) await _store.resetAllEdits();
  }

  Future<void> _confirmDelete(BuildContext context, SitePage p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete “${p.title}”?'),
        content: const Text(
          'The page and its menu link are removed for everyone. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Tok.danger),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete page'),
          ),
        ],
      ),
    );
    if (ok == true) await _store.deletePage(p.slug);
  }

  Future<void> _editPage(BuildContext context, SitePage? page) async {
    final saved = await showDialog<SitePage>(
      context: context,
      builder: (_) => _PageEditorDialog(page: page),
    );
    if (saved == null) return;
    await _store.savePage(saved);
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Saved “${saved.title}” at ${saved.route}.')),
      );
    }
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.action,
    required this.onPressed,
  });
  final IconData icon;
  final String title;
  final String text;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => InfoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Tok.accent,
            borderRadius: BorderRadius.circular(Tok.rMd),
          ),
          child: Icon(icon, color: Tok.brand),
        ),
        const SizedBox(height: Tok.s4),
        Text(title, style: Tok.heading(20)),
        const SizedBox(height: Tok.s2),
        Text(text, style: const TextStyle(color: Tok.textMuted)),
        const SizedBox(height: Tok.s4),
        FilledButton(onPressed: onPressed, child: Text(action)),
      ],
    ),
  );
}

class _PageEditorDialog extends StatefulWidget {
  const _PageEditorDialog({this.page});
  final SitePage? page;

  @override
  State<_PageEditorDialog> createState() => _PageEditorDialogState();
}

class _PageEditorDialogState extends State<_PageEditorDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.page?.title);
  late final _eyebrow = TextEditingController(text: widget.page?.eyebrow);
  late final _body = TextEditingController(text: widget.page?.body);
  late final _button = TextEditingController(text: widget.page?.buttonLabel);
  late final _link = TextEditingController(
    text: widget.page?.buttonLink ?? '/contact',
  );
  late String _image =
      widget.page?.image ?? 'assets/images/workshop_group_activity.jpeg';
  late bool _menu = widget.page?.showInMenu ?? true;
  late bool _published = widget.page?.published ?? true;

  @override
  void dispose() {
    for (final c in [_title, _eyebrow, _body, _button, _link]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final existing = widget.page;
    final slug =
        existing?.slug ??
        SitePage.slugify(_title.text) +
            (_store.pageBySlug(SitePage.slugify(_title.text)) == null
                ? ''
                : '-${DateTime.now().millisecondsSinceEpoch % 10000}');
    Navigator.pop(
      context,
      SitePage(
        slug: slug,
        title: _title.text.trim(),
        eyebrow: _eyebrow.text.trim(),
        body: _body.text.trim(),
        image: _image,
        buttonLabel: _button.text.trim(),
        buttonLink: _link.text.trim(),
        showInMenu: _menu,
        published: _published,
        order: existing?.order ?? _store.pages.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.page == null ? 'Add a page' : 'Edit page'),
    content: SizedBox(
      width: 560,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Page title'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Give the page a title.' : null,
              ),
              TextFormField(
                controller: _eyebrow,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Small label above the title (optional)',
                ),
              ),
              TextFormField(
                controller: _body,
                minLines: 5,
                maxLines: 12,
                maxLength: 5000,
                decoration: const InputDecoration(
                  labelText: 'Page text',
                  helperText: 'Leave an empty line between paragraphs.',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Add some text.' : null,
              ),
              const SizedBox(height: Tok.s3),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Tok.rSm),
                    child: Image(
                      image: siteImageProvider(_image),
                      width: 96,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: Tok.s3),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await pickSiteImage(
                        context,
                        title: 'Page photo',
                        current: _image,
                      );
                      if (picked != null && picked.isNotEmpty) {
                        setState(() => _image = picked);
                      }
                    },
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Choose photo'),
                  ),
                ],
              ),
              const SizedBox(height: Tok.s4),
              TextFormField(
                controller: _button,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Button text (optional), e.g. Book a call',
                ),
              ),
              TextFormField(
                controller: _link,
                decoration: const InputDecoration(
                  labelText: 'Button goes to',
                  helperText: 'A page like /contact, or a full https:// link.',
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (_button.text.trim().isEmpty || t.isEmpty) return null;
                  return t.startsWith('/') || t.startsWith('https://')
                      ? null
                      : 'Start with / or https://';
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show in the menu and footer'),
                value: _menu,
                onChanged: (v) => setState(() => _menu = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Published'),
                subtitle: const Text('Drafts are visible to admins only.'),
                value: _published,
                onChanged: (v) => setState(() => _published = v),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save page')),
    ],
  );
}

/// Public view of an extra page at `/p/<slug>`.
class SitePageView extends StatelessWidget {
  const SitePageView({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final page = _store.pageBySlug(slug);
      if (page == null || (!page.published && !_store.canEdit)) {
        return const PageWidth(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 96),
            child: Text(
              'This page is not available. Use the menu to find what you need.',
            ),
          ),
        );
      }
      final paragraphs = page.body
          .split(RegExp(r'\n\s*\n'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImageBanner(
            image: page.image,
            eyebrow: page.eyebrow.isEmpty ? 'MT Alchemy' : page.eyebrow,
            title: page.title,
            height: 260,
          ),
          if (!page.published)
            Container(
              color: Tok.accentTint,
              padding: const EdgeInsets.all(12),
              child: const Text(
                'Draft: only admins can see this page.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Tok.onAccentTint),
              ),
            ),
          PageWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Tok.s7),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in paragraphs) ...[
                      Text(p, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: Tok.s4),
                    ],
                    if (page.buttonLabel.isNotEmpty &&
                        page.buttonLink.isNotEmpty) ...[
                      const SizedBox(height: Tok.s3),
                      FilledButton(
                        onPressed: () => page.buttonLink.startsWith('/')
                            ? Navigator.pushNamed(context, page.buttonLink)
                            : launchUrl(
                                Uri.parse(page.buttonLink),
                                webOnlyWindowName: '_blank',
                              ),
                        child: Text(page.buttonLabel),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
