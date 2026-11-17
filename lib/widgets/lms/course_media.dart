import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/mock_data.dart';
import '../../shared/video_embed.dart';
import '../../theme.dart';

void _open(String url) =>
    launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');

/// Lesson video: an inline YouTube player on the web, otherwise a link.
class CourseVideo extends StatelessWidget {
  const CourseVideo({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final id = youTubeId(url);
    final player = id == null ? null : youTubePlayer(id);
    if (player == null) {
      return Material(
        color: const Color(0xFFF1ECFB),
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          leading: const Icon(Icons.play_circle_fill, color: purple, size: 36),
          title: const Text('Lesson video'),
          subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _open(url),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(color: Colors.black, child: player),
          ),
        ),
        TextButton.icon(
          onPressed: () => _open(url),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Watch on YouTube'),
        ),
      ],
    );
  }
}

/// Further reading and viewing for a course.
class CourseResources extends StatelessWidget {
  const CourseResources({super.key, required this.course});
  final Course course;

  static IconData _icon(String kind) => switch (kind.toLowerCase()) {
    'video' => Icons.smart_display_outlined,
    'guide' => Icons.menu_book_outlined,
    'fact sheet' => Icons.fact_check_outlined,
    'pdf' => Icons.picture_as_pdf_outlined,
    _ => Icons.article_outlined,
  };

  @override
  Widget build(BuildContext context) {
    if (course.resources.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in course.resources)
          if ((r['url'] ?? '').isNotEmpty)
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: deepBlue.withValues(alpha: .1)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFECE9FF),
                  child: Icon(_icon(r['kind'] ?? ''), color: deepBlue),
                ),
                title: Text(
                  r['title']?.isNotEmpty == true ? r['title']! : r['url']!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${r['kind'] ?? 'Link'} · ${Uri.tryParse(r['url']!)?.host.replaceFirst('www.', '') ?? ''}',
                ),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _open(r['url']!),
              ),
            ),
      ],
    );
  }
}
