import 'package:flutter/material.dart';

import '../../cms/editable.dart';

import '../../data/mock_data.dart';
import '../../data/progress_store.dart';
import '../../shared/format.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onViewCourse;
  final VoidCallback? onContinueCourse;

  const CourseCard({
    super.key,
    required this.course,
    this.onViewCourse,
    this.onContinueCourse,
  });

  bool get enrolled => enrolledCourses.contains(course.id);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DFFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CourseCover(course, height: 170, width: double.infinity),
          ),
          const SizedBox(height: 18),

          Text(
            course.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          Text(
            course.shortDescription,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),

          Text(
            course.instructor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoItem(icon: Icons.schedule_outlined, text: course.duration),
              _InfoItem(
                icon: Icons.signal_cellular_alt_outlined,
                text: course.level,
              ),
              _InfoItem(
                icon: Icons.star_outline,
                text: ratingLabel(course.rating),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            coursePrice(course.price),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          if (progressFor(course) > 0) ...[
            Text(
              '${progressFor(course)}% complete',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progressFor(course) / 100,
              minHeight: 7,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 14),
          ],

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: progressFor(course) > 0 || enrolled
                  ? (onContinueCourse ?? onViewCourse)
                  : onViewCourse,
              child: Text(
                progressFor(course) > 0
                    ? 'Continue Course'
                    : enrolled && onContinueCourse != null
                    ? 'Start Course'
                    : 'View Course',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF47416F)),
        const SizedBox(width: 5),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
