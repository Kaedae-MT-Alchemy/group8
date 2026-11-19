import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/course_content.dart';
import '../../data/lesson_files.dart';
import '../../shared/file_export.dart';
import '../../shared/media_embed.dart';
import '../../shared/video_embed.dart';
import '../../theme.dart';
import 'course_media.dart';

Future<void> _launch(String url) =>
    launchUrl(Uri.parse(absoluteUrl(url)), webOnlyWindowName: '_blank');

/// Shows one lesson: its video, document, slides, reading or link, plus
/// the lesson notes and open/download actions.
class LessonViewer extends StatelessWidget {
  const LessonViewer({
    super.key,
    required this.lesson,
    required this.moduleTitle,
    required this.position,
  });

  final CourseLesson lesson;
  final String moduleTitle;

  /// e.g. "Lesson 3 of 16".
  final String position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              avatar: Icon(lesson.kind.icon, size: 18, color: deepBlue),
              label: Text(lesson.kind.label),
              visualDensity: VisualDensity.compact,
              backgroundColor: const Color(0xFFEFEAFE),
              side: BorderSide.none,
            ),
            Text(
              '$position · about ${lesson.minutes} min',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(lesson.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          moduleTitle,
          style: const TextStyle(color: purple, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        if (lesson.kind == LessonKind.reading)
          ReadingText(text: lesson.body)
        else ...[
          _Material(lesson: lesson, key: ValueKey(lesson.id)),
          if (lesson.body.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            ReadingText(text: lesson.body),
          ],
        ],
      ],
    );
  }
}

/// Lesson notes: blank lines split paragraphs, "• " lines are bullets and
/// a short line on its own (e.g. "Key ideas") is a subheading.
class ReadingText extends StatelessWidget {
  const ReadingText({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];
    for (final block in text.split(RegExp(r'\n\s*\n'))) {
      final lines = block.trim().split('\n');
      if (lines.first.isEmpty) continue;
      var start = 0;
      final first = lines.first.trim();
      if (lines.length > 1 &&
          first.length < 40 &&
          !first.startsWith('• ') &&
          !first.endsWith('.')) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 6),
            child: Text(first, style: theme.textTheme.titleMedium),
          ),
        );
        start = 1;
      }
      for (final line in lines.skip(start)) {
        final t = line.trim();
        if (t.isEmpty) continue;
        children.add(
          t.startsWith('• ')
              ? Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3, right: 10),
                        child: Icon(
                          Icons.check_circle,
                          size: 18,
                          color: purple,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          t.substring(2),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(t, style: theme.textTheme.bodyLarge),
                ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _Material extends StatefulWidget {
  const _Material({super.key, required this.lesson});
  final CourseLesson lesson;

  @override
  State<_Material> createState() => _MaterialState();
}

class _MaterialState extends State<_Material> {
  CourseLesson get lesson => widget.lesson;
  Future<Uint8List>? _bytes;
  String? _blob;

  @override
  void initState() {
    super.initState();
    if (lesson.hasFile) _bytes = LessonFiles.load(lesson.fileId);
  }

  String get _name => lesson.fileName.isNotEmpty
      ? lesson.fileName
      : Uri.tryParse(lesson.url)?.pathSegments.lastOrNull ?? 'file';

  /// Where the browser can fetch the material: a link, a bundled file or
  /// an object URL for an uploaded file.
  String? _source(Uint8List? bytes) {
    if (bytes != null) {
      return _blob ??= blobUrl(bytes, LessonFiles.mimeFor(_name));
    }
    return lesson.url.isEmpty ? null : absoluteUrl(lesson.url);
  }

  Future<void> _download(Uint8List? bytes) async {
    if (bytes != null) {
      await saveLocalFile(_name, bytes);
    } else if (lesson.url.isNotEmpty) {
      await _launch(lesson.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) return _body(null);
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snap) {
        if (snap.hasError) {
          return _Notice(
            icon: Icons.error_outline,
            text: '${snap.error}'.replaceFirst('Bad state: ', ''),
          );
        }
        if (!snap.hasData) {
          return const _Notice(
            icon: Icons.downloading,
            text: 'Loading the lesson file…',
            busy: true,
          );
        }
        return _body(snap.data);
      },
    );
  }

  Widget _body(Uint8List? bytes) {
    final src = _source(bytes);
    if (src == null && lesson.kind != LessonKind.link) {
      return const _Notice(
        icon: Icons.hourglass_empty,
        text: 'The material for this lesson has not been added yet.',
      );
    }
    final actions = _Actions(
      openLabel: switch (lesson.kind) {
        LessonKind.video => 'Open video in a new tab',
        LessonKind.link => 'Open resource',
        _ => 'Open in a new tab',
      },
      onOpen: lesson.kind == LessonKind.link || bytes == null
          ? (lesson.url.isEmpty ? null : () => _launch(lesson.url))
          : (src == null ? null : () => _launch(src)),
      downloadLabel:
          lesson.kind == LessonKind.link ||
              lesson.kind == LessonKind.video && youTubeId(lesson.url) != null
          ? null
          : 'Download ${_name.split('.').last.toUpperCase()}',
      onDownload: () => _download(bytes),
      detail: bytes != null
          ? '$_name · ${formatBytes(bytes.length)}'
          : lesson.isAsset
          ? _name
          : null,
    );
    switch (lesson.kind) {
      case LessonKind.video:
        if (bytes == null && youTubeId(lesson.url) != null) {
          return CourseVideo(url: lesson.url);
        }
        final player = videoView(src!);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (player != null)
              _Frame(aspectRatio: 16 / 9, dark: true, child: player),
            const SizedBox(height: 8),
            actions,
          ],
        );
      case LessonKind.pdf:
        final frame = iframeView(src!, title: lesson.title);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (frame != null) _Frame(height: 640, child: frame),
            const SizedBox(height: 8),
            actions,
          ],
        );
      case LessonKind.slides || LessonKind.document:
        // Microsoft's web viewer can show Office files that have a public
        // https address; uploaded files are offered as a download instead.
        final public = bytes == null && src!.startsWith('https://');
        final frame = public
            ? iframeView(
                'https://view.officeapps.live.com/op/embed.aspx?src=${Uri.encodeComponent(src)}',
                title: lesson.title,
              )
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (frame != null)
              _Frame(
                height: lesson.kind == LessonKind.slides ? 520 : 640,
                child: frame,
              )
            else
              _FileCard(lesson: lesson, name: _name),
            const SizedBox(height: 8),
            actions,
          ],
        );
      case LessonKind.link:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: const Color(0xFFEFEAFE),
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                leading: const Icon(Icons.public, color: deepBlue),
                title: Text(
                  Uri.tryParse(lesson.url)?.host.replaceFirst('www.', '') ??
                      lesson.url,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  lesson.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.open_in_new),
                onTap: lesson.url.isEmpty ? null : () => _launch(lesson.url),
              ),
            ),
            const SizedBox(height: 8),
            actions,
          ],
        );
      case LessonKind.reading:
        return const SizedBox.shrink();
    }
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.child,
    this.aspectRatio,
    this.height,
    this.dark = false,
  });
  final Widget child;
  final double? aspectRatio;
  final double? height;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final box = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dark ? Colors.black : Colors.white,
          border: Border.all(color: deepBlue.withValues(alpha: .12)),
        ),
        child: child,
      ),
    );
    return aspectRatio != null
        ? AspectRatio(aspectRatio: aspectRatio!, child: box)
        : SizedBox(
            height: (MediaQuery.sizeOf(context).height * .75).clamp(
              360,
              height ?? 640,
            ),
            child: box,
          );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.lesson, required this.name});
  final CourseLesson lesson;
  final String name;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: deepBlue,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(lesson.kind.icon, size: 48, color: softYellow),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${lesson.kind.label} file. Download it to open in PowerPoint, Word, Google Slides/Docs or Keynote.',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.openLabel,
    required this.onOpen,
    required this.downloadLabel,
    required this.onDownload,
    this.detail,
  });
  final String openLabel;
  final VoidCallback? onOpen;
  final String? downloadLabel;
  final VoidCallback onDownload;
  final String? detail;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (onOpen != null)
        OutlinedButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(openLabel),
        ),
      if (downloadLabel != null)
        OutlinedButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.download_outlined, size: 18),
          label: Text(downloadLabel!),
        ),
      if (detail != null)
        Text(detail!, style: const TextStyle(color: Colors.black54)),
    ],
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.busy = false});
  final IconData icon;
  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F1FF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Icon(icon, color: deepBlue),
        const SizedBox(width: 14),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
