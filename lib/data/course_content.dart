import 'package:flutter/material.dart';

/// Kinds of learning material a lesson can hold.
enum LessonKind { video, reading, pdf, slides, document, link }

extension LessonKindInfo on LessonKind {
  String get id => name;

  String get label => switch (this) {
    LessonKind.video => 'Video',
    LessonKind.reading => 'Reading',
    LessonKind.pdf => 'PDF',
    LessonKind.slides => 'Slides',
    LessonKind.document => 'Document',
    LessonKind.link => 'Link',
  };

  /// What the admin can supply for this kind of lesson.
  String get hint => switch (this) {
    LessonKind.video => 'YouTube link, MP4 link or an uploaded MP4/WebM file',
    LessonKind.reading => 'Notes written in the lesson text',
    LessonKind.pdf => 'Uploaded PDF or a link to one',
    LessonKind.slides => 'Uploaded PPT/PPTX or a link to one',
    LessonKind.document => 'Uploaded DOC/DOCX or a link to one',
    LessonKind.link => 'Any web page or article',
  };

  IconData get icon => switch (this) {
    LessonKind.video => Icons.play_circle_outline,
    LessonKind.reading => Icons.article_outlined,
    LessonKind.pdf => Icons.picture_as_pdf_outlined,
    LessonKind.slides => Icons.slideshow_outlined,
    LessonKind.document => Icons.description_outlined,
    LessonKind.link => Icons.open_in_new,
  };

  /// File extensions the admin may upload for this kind.
  List<String> get extensions => switch (this) {
    LessonKind.video => const ['mp4', 'webm', 'm4v', 'mov'],
    LessonKind.pdf => const ['pdf'],
    LessonKind.slides => const ['ppt', 'pptx', 'odp'],
    LessonKind.document => const ['doc', 'docx', 'odt', 'rtf', 'txt'],
    LessonKind.reading || LessonKind.link => const [],
  };

  static LessonKind parse(String? value) => LessonKind.values.firstWhere(
    (k) => k.name == value,
    orElse: () => LessonKind.reading,
  );
}

/// One lesson in a course. A lesson's material is a link ([url]), an
/// uploaded file ([fileId] in the `lessonFiles` collection) or the text in
/// [body]. Built-in sample files use `assets/...` paths in [url].
class CourseLesson {
  const CourseLesson({
    required this.id,
    required this.module,
    required this.title,
    required this.kind,
    this.url = '',
    this.fileId = '',
    this.fileName = '',
    this.fileSize = 0,
    this.body = '',
    this.minutes = 10,
  });

  final String id;
  final int module;
  final String title;
  final LessonKind kind;
  final String url;
  final String fileId;
  final String fileName;
  final int fileSize;
  final String body;
  final int minutes;

  bool get hasFile => fileId.isNotEmpty;
  bool get isAsset => url.startsWith('assets/');

  CourseLesson copyWith({
    int? module,
    String? title,
    LessonKind? kind,
    String? url,
    String? fileId,
    String? fileName,
    int? fileSize,
    String? body,
    int? minutes,
  }) => CourseLesson(
    id: id,
    module: module ?? this.module,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    url: url ?? this.url,
    fileId: fileId ?? this.fileId,
    fileName: fileName ?? this.fileName,
    fileSize: fileSize ?? this.fileSize,
    body: body ?? this.body,
    minutes: minutes ?? this.minutes,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'module': module,
    'title': title,
    'type': kind.name,
    'url': url,
    'fileId': fileId,
    'fileName': fileName,
    'fileSize': fileSize,
    'body': body,
    'minutes': minutes,
  };

  factory CourseLesson.fromJson(Map<String, dynamic> j) => CourseLesson(
    id: '${j['id'] ?? ''}',
    module: (j['module'] as num?)?.toInt() ?? 0,
    title: '${j['title'] ?? 'Lesson'}',
    kind: LessonKindInfo.parse(j['type'] as String?),
    url: '${j['url'] ?? ''}',
    fileId: '${j['fileId'] ?? ''}',
    fileName: '${j['fileName'] ?? ''}',
    fileSize: (j['fileSize'] as num?)?.toInt() ?? 0,
    body: '${j['body'] ?? ''}',
    minutes: (j['minutes'] as num?)?.toInt() ?? 10,
  );
}

/// Lessons in module order, keeping each module's own order. Lessons whose
/// module no longer exists are dropped.
List<CourseLesson> orderLessons(List<CourseLesson> lessons, int moduleCount) {
  final out = <CourseLesson>[];
  for (var m = 0; m < moduleCount; m++) {
    out.addAll(lessons.where((l) => l.module == m));
  }
  return out;
}

/// Placeholder lessons for a course that has modules but no lessons yet:
/// one reading per module so the player and progress still work.
List<CourseLesson> placeholderLessons(
  String courseId,
  List<String> modules,
) => [
  for (final (i, m) in modules.indexed)
    CourseLesson(
      id: '$courseId-m${i + 1}',
      module: i,
      title: m,
      kind: LessonKind.reading,
      body:
          '$m: reflect on a recent workplace experience. Identify one behaviour you would like to improve, practise it in your next conversation and note the outcome.',
    ),
];

enum QuizType { single, multi, trueFalse, short }

extension QuizTypeInfo on QuizType {
  String get id => switch (this) {
    QuizType.single => 'single',
    QuizType.multi => 'multi',
    QuizType.trueFalse => 'tf',
    QuizType.short => 'short',
  };

  String get label => switch (this) {
    QuizType.single => 'Multiple choice (one answer)',
    QuizType.multi => 'Select all that apply',
    QuizType.trueFalse => 'True or false',
    QuizType.short => 'Short answer',
  };

  static QuizType parse(String? value) => switch (value) {
    'multi' || 'multiple' || 'multipleAnswer' => QuizType.multi,
    'tf' || 'truefalse' || 'trueFalse' => QuizType.trueFalse,
    'short' || 'shortAnswer' || 'text' => QuizType.short,
    _ => QuizType.single,
  };
}

/// A quiz question. For [QuizType.short], [answers] are accepted keywords
/// (case-insensitive); any keyword found in the learner's answer is correct.
class QuizItem {
  const QuizItem({
    required this.type,
    required this.prompt,
    this.options = const [],
    this.answers = const [],
    this.explanation = '',
  });

  final QuizType type;
  final String prompt;
  final List<String> options;
  final List<String> answers;
  final String explanation;

  Map<String, Object> toJson() => {
    'type': type.id,
    'prompt': prompt,
    'options': options,
    'answers': answers,
    'explanation': explanation,
  };

  /// Reads the current shape and the older `{prompt, options, answer}` one.
  factory QuizItem.fromJson(Map<String, dynamic> j) {
    final type = QuizTypeInfo.parse(j['type'] as String?);
    final options = [for (final o in j['options'] as List? ?? []) '$o'];
    final answers = j['answers'] is List
        ? [for (final a in j['answers'] as List) '$a']
        : [if (j['answer'] != null) '${j['answer']}'];
    return QuizItem(
      type: type,
      prompt: '${j['prompt'] ?? ''}',
      options: type == QuizType.trueFalse && options.isEmpty
          ? const ['True', 'False']
          : options,
      answers: answers,
      explanation: '${j['explanation'] ?? ''}',
    );
  }

  /// Text shown as the correct answer on the results page.
  String get displayAnswer => type == QuizType.short && answers.isNotEmpty
      ? answers.first
      : answers.join(', ');

  /// True when [chosen] (option texts) or [text] (short answer) is correct.
  bool isCorrect({Set<String> chosen = const {}, String text = ''}) {
    if (type == QuizType.short) {
      final t = text.trim().toLowerCase();
      if (t.isEmpty) return false;
      return answers.any((a) => t.contains(a.trim().toLowerCase()));
    }
    return chosen.length == answers.length && answers.every(chosen.contains);
  }

  /// Problems an admin must fix before saving, or null when valid.
  String? validate() {
    if (prompt.trim().isEmpty) return 'Enter the question.';
    if (type == QuizType.short) {
      return answers.where((a) => a.trim().isNotEmpty).isEmpty
          ? 'Add at least one accepted answer.'
          : null;
    }
    final opts = options.where((o) => o.trim().isNotEmpty).toList();
    if (opts.length < 2) return 'Add at least two options.';
    if (opts.toSet().length != opts.length) return 'Options must be different.';
    if (answers.isEmpty) return 'Choose the correct answer.';
    if (answers.any((a) => !opts.contains(a))) {
      return 'Each correct answer must be one of the options.';
    }
    if (type != QuizType.multi && answers.length != 1) {
      return 'Choose exactly one correct answer.';
    }
    return null;
  }
}

/// Percentage score for a set of correct flags, 0 when there are none.
int quizPercent(List<bool> results) => results.isEmpty
    ? 0
    : (results.where((r) => r).length / results.length * 100).round();

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}
