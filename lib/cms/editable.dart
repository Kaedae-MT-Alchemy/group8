import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../shared/image_compress.dart';
import '../theme.dart';
import 'site_content.dart';

SiteContentStore get _store => SiteContentStore.instance;

/// Builds [text] with `*phrase*` shown in italic (and [accent] colour).
/// "Master *human intelligence* today" → "human intelligence" in italics.
Widget accentText(
  String text, {
  required TextStyle style,
  Color? accent,
  TextAlign? textAlign,
  int? maxLines,
  TextOverflow? overflow,
}) {
  if (!text.contains('*')) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
  final parts = text.split('*');
  return Text.rich(
    TextSpan(
      style: style,
      children: [
        for (final (i, part) in parts.indexed)
          if (part.isNotEmpty)
            TextSpan(
              text: part,
              style: i.isOdd
                  ? style.copyWith(fontStyle: FontStyle.italic, color: accent)
                  : null,
            ),
      ],
    ),
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
  );
}

/// Text the super admin can change. Shows the saved override, or [fallback].
/// In edit mode it gets a gold outline and opens an editor when tapped.
class CmsText extends StatelessWidget {
  const CmsText(
    this.contentKey,
    this.fallback, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.label,
    this.accent,
    this.multiline = false,
  });

  final String contentKey;
  final String fallback;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Name shown in the editor ("Hero headline").
  final String? label;

  /// When set, `*words*` render in italics with this colour.
  final Color? accent;
  final bool multiline;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final value = _store.text(contentKey, fallback);
      final effective = style ?? DefaultTextStyle.of(context).style;
      final shown = accent != null
          ? accentText(
              value,
              style: effective,
              accent: accent,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: overflow,
            )
          : Text(
              value.replaceAll('*', ''),
              style: style,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: overflow,
            );
      if (!_store.editing) return shown;
      return EditFrame(
        tooltip: 'Edit ${label ?? 'text'}',
        onEdit: () => showTextEditor(
          context,
          contentKey: contentKey,
          fallback: fallback,
          label: label ?? 'Text',
          multiline: multiline || fallback.length > 80,
          allowAccent: accent != null,
        ),
        child: shown,
      );
    },
  );
}

/// Image the super admin can swap. [builder] receives the image provider.
class CmsImage extends StatelessWidget {
  const CmsImage(
    this.contentKey,
    this.fallback, {
    super.key,
    required this.builder,
    this.label,
  });
  final String contentKey;
  final String fallback;
  final Widget Function(BuildContext context, ImageProvider image) builder;
  final String? label;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final src = _store.image(contentKey, fallback);
      final child = builder(context, siteImageProvider(src));
      if (!_store.editing) return child;
      return Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          Positioned(
            left: 12,
            top: 12,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Tok.accent,
                foregroundColor: Tok.brandDeep,
              ),
              onPressed: () => showImageEditor(
                context,
                contentKey: contentKey,
                fallback: fallback,
                label: label ?? 'Image',
              ),
              icon: const Icon(Icons.image_outlined, size: 18),
              label: const Text('Change image'),
            ),
          ),
        ],
      );
    },
  );
}

/// A page section the super admin can hide or show again.
class CmsSection extends StatelessWidget {
  const CmsSection(
    this.contentKey, {
    super.key,
    required this.label,
    required this.child,
    this.showBar = true,
  });
  final String contentKey;
  final String label;
  final Widget child;

  /// False for the second and later parts of a section split across the
  /// page, so the show/hide switch appears once.
  final bool showBar;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final hidden = _store.isHidden(contentKey);
      if (!_store.editing) return hidden ? const SizedBox.shrink() : child;
      if (!showBar) return Opacity(opacity: hidden ? 0.35 : 1, child: child);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: Tok.s5),
            child: Material(
              color: hidden ? Tok.calmTint : Tok.accentTint,
              borderRadius: BorderRadius.circular(Tok.rMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      hidden ? Icons.visibility_off_outlined : Icons.view_day,
                      color: Tok.brand,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hidden
                            ? 'Section hidden from visitors: $label'
                            : 'Section: $label',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Tok.brandDeep,
                        ),
                      ),
                    ),
                    const Text('Show'),
                    Switch(
                      value: !hidden,
                      onChanged: (show) => _store.setHidden(contentKey, !show),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Opacity(opacity: hidden ? 0.35 : 1, child: child),
        ],
      );
    },
  );
}

/// Gold outline and pencil chip around editable content.
class EditFrame extends StatelessWidget {
  const EditFrame({
    super.key,
    required this.child,
    required this.onEdit,
    required this.tooltip,
  });
  final Widget child;
  final VoidCallback onEdit;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: tooltip,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onEdit,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: Tok.accent, width: 2),
                borderRadius: BorderRadius.circular(6),
                color: Tok.accent.withValues(alpha: 0.08),
              ),
              child: child,
            ),
            Positioned(
              right: -10,
              top: -12,
              child: Tooltip(
                message: tooltip,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Tok.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 15,
                    color: Tok.brandDeep,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showTextEditor(
  BuildContext context, {
  required String contentKey,
  required String fallback,
  required String label,
  bool multiline = false,
  bool allowAccent = false,
}) async {
  final controller = TextEditingController(
    text: _store.text(contentKey, fallback),
  );
  final changed = _store.texts.containsKey(contentKey);
  final result = await showDialog<String?>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Edit $label'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              minLines: multiline ? 3 : 1,
              maxLines: multiline ? 8 : 2,
              maxLength: 600,
              decoration: InputDecoration(labelText: label),
            ),
            if (allowAccent)
              const Text(
                'Tip: put *stars* around words to show them in gold italics.',
                style: TextStyle(color: Tok.textMuted, fontSize: 14),
              ),
            const SizedBox(height: 8),
            Text(
              'Original: ${fallback.replaceAll('*', '')}',
              style: const TextStyle(color: Tok.textMuted, fontSize: 13.5),
            ),
          ],
        ),
      ),
      actions: [
        if (changed)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Reset to original'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null || !context.mounted) return;
  final value = result.trim() == fallback.trim() ? '' : result;
  await _saveWithFeedback(context, () => _store.setText(contentKey, value));
}

/// Pictures admins can pick without uploading.
const siteImageLibrary = [
  'assets/images/home_hero_team_building.jpeg',
  'assets/images/workshop_group_activity.jpeg',
  'assets/images/workshop_group_discussion.jpeg',
  'assets/images/workshop_team_creativity.jpeg',
  'assets/images/workshop_eq_facilitator.jpeg',
  'assets/images/trainer_presenting.jpeg',
  'assets/images/impact_classroom_workshop.jpeg',
  'assets/images/impact_teachers_retreat.jpeg',
  'assets/images/impact_youth_group.jpeg',
  'assets/images/online_team_learning.jpg',
  'assets/images/stock/team_discussion.jpg',
  'assets/images/stock/team_laughing.jpg',
  'assets/images/stock/coaching_conversation.jpg',
  'assets/images/stock/meditation.jpg',
  'assets/images/stock/online_learning.jpg',
  'assets/images/stock/leadership.jpg',
  'assets/images/stock/wellbeing_class.jpg',
  'assets/images/stock/planning.jpg',
];

Future<void> showImageEditor(
  BuildContext context, {
  required String contentKey,
  required String fallback,
  required String label,
}) async {
  final picked = await pickSiteImage(
    context,
    title: 'Change $label',
    current: _store.image(contentKey, fallback),
    canReset: _store.images.containsKey(contentKey),
  );
  if (picked == null || !context.mounted) return;
  await _saveWithFeedback(
    context,
    () => _store.setImage(contentKey, picked.isEmpty ? null : picked),
  );
}

/// Lets the admin choose a library picture, upload a photo, or paste an
/// https link. Returns the new source, '' to reset, or null if cancelled.
Future<String?> pickSiteImage(
  BuildContext context, {
  required String title,
  required String current,
  bool canReset = false,
}) => showDialog<String>(
  context: context,
  builder: (context) =>
      _ImagePickerDialog(title: title, current: current, canReset: canReset),
);

class _ImagePickerDialog extends StatefulWidget {
  const _ImagePickerDialog({
    required this.title,
    required this.current,
    required this.canReset,
  });
  final String title;
  final String current;
  final bool canReset;

  @override
  State<_ImagePickerDialog> createState() => _ImagePickerDialogState();
}

class _ImagePickerDialogState extends State<_ImagePickerDialog> {
  late String _selected = widget.current;
  final _link = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file?.bytes == null) return;
    final small = compressImage(file!.bytes!, maxSide: 1600);
    if (small == null) {
      setState(() => _error = 'That file is not a JPG, PNG or WebP image.');
      return;
    }
    setState(() {
      _error = null;
      _selected = 'data:image/jpeg;base64,${base64Encode(small)}';
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 640,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Tok.rMd),
              child: Image(
                image: siteImageProvider(_selected),
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 180,
                  child: Center(child: Text('This image could not load.')),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _upload,
                  icon: const Icon(Icons.upload_rounded),
                  label: const Text('Upload a photo'),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Tok.danger)),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _link,
              decoration: InputDecoration(
                labelText: 'Or paste an image link (https://…)',
                suffixIcon: IconButton(
                  tooltip: 'Use this link',
                  icon: const Icon(Icons.check_rounded),
                  onPressed: () {
                    final v = _link.text.trim();
                    if (v.startsWith('https://')) {
                      setState(() => _selected = v);
                    } else {
                      setState(() => _error = 'Links must start with https://');
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Or pick one of the site’s photos:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final path in siteImageLibrary)
                  Semantics(
                    button: true,
                    selected: path == _selected,
                    label: 'Photo ${siteImageLibrary.indexOf(path) + 1}',
                    child: InkWell(
                      onTap: () => setState(() => _selected = path),
                      borderRadius: BorderRadius.circular(Tok.rSm),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Tok.rSm),
                          border: Border.all(
                            color: path == _selected
                                ? Tok.accent
                                : Colors.transparent,
                            width: 3,
                          ),
                          image: DecorationImage(
                            image: AssetImage(path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: [
      if (widget.canReset)
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: const Text('Reset to original'),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _selected),
        child: const Text('Use this image'),
      ),
    ],
  );
}

Future<void> _saveWithFeedback(
  BuildContext context,
  Future<void> Function() save,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await save();
    messenger?.showSnackBar(
      const SnackBar(content: Text('Saved. Visitors see the change now.')),
    );
  } catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text('Could not save: $e')));
  }
}

/// Floating "Edit this page" pill for admins, bottom left.
class EditModeToggle extends StatelessWidget {
  const EditModeToggle({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      if (!_store.canEdit) return const SizedBox.shrink();
      final on = _store.editing;
      return Material(
        color: on ? Tok.accent : Tok.brandDeep,
        shape: const StadiumBorder(),
        elevation: 6,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => _store.editing = !on,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  on ? Icons.check_rounded : Icons.edit_rounded,
                  size: 18,
                  color: on ? Tok.brandDeep : Tok.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  on ? 'Done editing' : 'Edit this page',
                  style: TextStyle(
                    fontFamily: Tok.display,
                    fontWeight: FontWeight.w600,
                    color: on ? Tok.brandDeep : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Editable text rendered by your own [builder] (for widgets like Eyebrow
/// that style the string themselves).
class CmsValue extends StatelessWidget {
  const CmsValue(
    this.contentKey,
    this.fallback, {
    super.key,
    required this.label,
    required this.builder,
    this.multiline = false,
  });
  final String contentKey;
  final String fallback;
  final String label;
  final bool multiline;
  final Widget Function(BuildContext context, String value) builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final child = builder(context, _store.text(contentKey, fallback));
      if (!_store.editing) return child;
      return EditFrame(
        tooltip: 'Edit $label',
        onEdit: () => showTextEditor(
          context,
          contentKey: contentKey,
          fallback: fallback,
          label: label,
          multiline: multiline || fallback.length > 80,
        ),
        child: child,
      );
    },
  );
}
