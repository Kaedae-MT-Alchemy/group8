import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/course_content.dart';
import '../data/lesson_files.dart';
import '../data/mock_data.dart';
import '../shared/auth_prototype_store.dart';
import '../shared/format.dart';
import '../theme.dart';
import '../widgets.dart';

/// Full-screen builder for a course's modules, lessons and quiz.
class CourseBuilderPage extends StatefulWidget {
  const CourseBuilderPage({super.key, required this.courseId});
  final String courseId;

  @override
  State<CourseBuilderPage> createState() => _CourseBuilderPageState();
}

class _CourseBuilderPageState extends State<CourseBuilderPage> {
  late final Course course = mockCourses.firstWhere(
    (c) => c.id == widget.courseId,
  );
  late final List<String> modules = [...course.modules];
  late final List<CourseLesson> lessons = [...course.courseLessons];
  late final List<QuizItem> quiz = [...course.quizItems];
  late final passMark = TextEditingController(text: '${course.passMark}');
  late final Set<String> _originalFiles = {
    for (final l in course.lessons)
      if (l.hasFile) l.fileId,
  };
  bool saving = false;
  bool dirty = false;
  String? error;

  @override
  void dispose() {
    passMark.dispose();
    super.dispose();
  }

  void _change(VoidCallback fn) => setState(() {
    fn();
    dirty = true;
    error = null;
  });

  List<CourseLesson> _inModule(int m) => [
    for (final l in lessons)
      if (l.module == m) l,
  ];

  // ---------------------------------------------------------------- modules
  Future<void> _editModule([int? index]) async {
    final name = await _askText(
      context,
      title: index == null ? 'Add module' : 'Rename module',
      label: 'Module title',
      initial: index == null ? '' : modules[index],
    );
    if (name == null) return;
    _change(() => index == null ? modules.add(name) : modules[index] = name);
  }

  Future<void> _deleteModule(int m) async {
    final count = _inModule(m).length;
    final ok = await _confirm(
      context,
      'Delete "${modules[m]}"?',
      count == 0
          ? 'This module has no lessons.'
          : 'Its ${plural(count, 'lesson')} will be removed too.',
    );
    if (ok != true) return;
    _change(() {
      lessons.removeWhere((l) => l.module == m);
      for (var i = 0; i < lessons.length; i++) {
        if (lessons[i].module > m) {
          lessons[i] = lessons[i].copyWith(module: lessons[i].module - 1);
        }
      }
      modules.removeAt(m);
    });
  }

  void _moveModule(int m, int delta) {
    final to = m + delta;
    if (to < 0 || to >= modules.length) return;
    _change(() {
      final name = modules.removeAt(m);
      modules.insert(to, name);
      for (var i = 0; i < lessons.length; i++) {
        final l = lessons[i];
        if (l.module == m) {
          lessons[i] = l.copyWith(module: to);
        } else if (l.module == to) {
          lessons[i] = l.copyWith(module: m);
        }
      }
    });
  }

  // ---------------------------------------------------------------- lessons
  Future<void> _editLesson(int module, [CourseLesson? lesson]) async {
    final result = await showDialog<CourseLesson>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LessonEditorDialog(
        lesson:
            lesson ??
            CourseLesson(
              id: '${course.id}-${DateTime.now().microsecondsSinceEpoch}',
              module: module,
              title: '',
              kind: LessonKind.video,
            ),
        isNew: lesson == null,
      ),
    );
    if (result == null) return;
    _change(() {
      final i = lessons.indexWhere((l) => l.id == result.id);
      if (i >= 0) {
        lessons[i] = result;
      } else {
        lessons.add(result);
      }
    });
  }

  Future<void> _deleteLesson(CourseLesson lesson) async {
    final ok = await _confirm(
      context,
      'Delete "${lesson.title}"?',
      'Learners will no longer see this lesson.',
    );
    if (ok == true) {
      _change(() => lessons.removeWhere((l) => l.id == lesson.id));
    }
  }

  void _moveLesson(CourseLesson lesson, int delta) {
    final siblings = _inModule(lesson.module);
    final pos = siblings.indexWhere((l) => l.id == lesson.id);
    final to = pos + delta;
    if (to < 0 || to >= siblings.length) return;
    _change(() {
      final a = lessons.indexWhere((l) => l.id == lesson.id);
      final b = lessons.indexWhere((l) => l.id == siblings[to].id);
      final tmp = lessons[a];
      lessons[a] = lessons[b];
      lessons[b] = tmp;
    });
  }

  // ---------------------------------------------------------------- quiz
  Future<void> _editQuestion([int? index]) async {
    final result = await showDialog<QuizItem>(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuestionEditorDialog(
        item: index == null
            ? const QuizItem(type: QuizType.single, prompt: '')
            : quiz[index],
      ),
    );
    if (result == null) return;
    _change(() => index == null ? quiz.add(result) : quiz[index] = result);
  }

  void _moveQuestion(int i, int delta) {
    final to = i + delta;
    if (to < 0 || to >= quiz.length) return;
    _change(() => quiz.insert(to, quiz.removeAt(i)));
  }

  // ---------------------------------------------------------------- save
  Future<void> _save() async {
    final mark = int.tryParse(passMark.text.trim());
    final problem = modules.isEmpty
        ? 'Add at least one module.'
        : modules.any((m) => m.trim().isEmpty)
        ? 'Every module needs a title.'
        : lessons.isEmpty
        ? 'Add at least one lesson.'
        : quiz.isEmpty
        ? 'Add at least one quiz question.'
        : mark == null || mark < 1 || mark > 100
        ? 'Passing score must be from 1 to 100.'
        : null;
    if (problem != null) {
      setState(() => error = problem);
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final updated = course.copyWith(
      modules: [...modules],
      lessons: orderLessons(lessons, modules.length),
      quiz: [for (final q in quiz) q.toJson()],
      passMark: mark,
    );
    try {
      await saveCourseCatalogue([
        for (final c in mockCourses) c.id == course.id ? updated : c,
      ]);
      // Remove uploads that no lesson uses any more.
      final used = {
        for (final l in updated.lessons)
          if (l.hasFile) l.fileId,
      };
      for (final id in _originalFiles.difference(used)) {
        try {
          await LessonFiles.delete(id);
        } catch (_) {
          /* An orphaned file is harmless; the course is already saved. */
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course content saved. Learners see it now.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = 'Could not save: ${'$e'.replaceFirst('Bad state: ', '')}';
        });
      }
    }
  }

  Future<bool> _confirmLeave() async {
    if (!dirty || saving) return true;
    return await _confirm(
          context,
          'Discard your changes?',
          'You have unsaved changes to this course.',
          action: 'Discard',
        ) ==
        true;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      if (await _confirmLeave() && context.mounted) {
        setState(() => dirty = false);
        Navigator.pop(context);
      }
    },
    child: DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5FF),
        appBar: AppBar(
          title: Text(course.title),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Lessons (${lessons.length})'),
              Tab(text: 'Quiz (${quiz.length})'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Saving…' : 'Save content'),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            if (error != null)
              MaterialBanner(
                backgroundColor: const Color(0xFFFFEBEE),
                content: Text(error!),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => error = null),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            Expanded(child: TabBarView(children: [_lessonsTab(), _quizTab()])),
          ],
        ),
      ),
    ),
  );

  Widget _page(List<Widget> children) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ],
  );

  Widget _lessonsTab() => _page([
    Text(
      'Each module holds lessons. A lesson can be a YouTube or MP4 video, a PDF, slides (PPT/PPTX), a document (DOC/DOCX), a reading or a web link. Upload files up to 10 MB, or paste a link for anything larger.',
      style: Theme.of(context).textTheme.bodyMedium,
    ),
    const SizedBox(height: 16),
    for (var m = 0; m < modules.length; m++) _moduleCard(m),
    const SizedBox(height: 8),
    Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: () => _editModule(),
        icon: const Icon(Icons.add),
        label: const Text('Add module'),
      ),
    ),
  ]);

  Widget _moduleCard(int m) {
    final items = _inModule(m);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MODULE ${m + 1}',
                        style: const TextStyle(
                          color: purple,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        modules[m],
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Move module up',
                  onPressed: m == 0 ? null : () => _moveModule(m, -1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Move module down',
                  onPressed: m == modules.length - 1
                      ? null
                      : () => _moveModule(m, 1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: 'Rename module',
                  onPressed: () => _editModule(m),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete module',
                  onPressed: () => _deleteModule(m),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const Divider(),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No lessons yet.'),
              ),
            for (final (i, l) in items.indexed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEFEAFE),
                  child: Icon(l.kind.icon, color: deepBlue, size: 20),
                ),
                title: Text(
                  l.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${l.kind.label} · ${l.minutes} min · ${_source(l)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Move lesson up',
                      onPressed: i == 0 ? null : () => _moveLesson(l, -1),
                      icon: const Icon(Icons.keyboard_arrow_up),
                    ),
                    IconButton(
                      tooltip: 'Move lesson down',
                      onPressed: i == items.length - 1
                          ? null
                          : () => _moveLesson(l, 1),
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                    IconButton(
                      tooltip: 'Edit lesson',
                      onPressed: () => _editLesson(m, l),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete lesson',
                      onPressed: () => _deleteLesson(l),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _editLesson(m),
              icon: const Icon(Icons.add),
              label: Text('Add lesson to module ${m + 1}'),
            ),
          ],
        ),
      ),
    );
  }

  static String _source(CourseLesson l) {
    if (l.hasFile) return '${l.fileName} (${formatBytes(l.fileSize)})';
    if (l.isAsset) return '${l.url.split('/').last} (built-in)';
    if (l.url.isNotEmpty) {
      return Uri.tryParse(l.url)?.host.replaceFirst('www.', '') ?? l.url;
    }
    return l.kind == LessonKind.reading ? 'text lesson' : 'no material yet';
  }

  Widget _quizTab() => _page([
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'Learners take this quiz after finishing every lesson. Mix question types and add an explanation so learners understand the right answer.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 170,
          child: TextField(
            controller: passMark,
            keyboardType: TextInputType.number,
            onChanged: (_) => dirty = true,
            decoration: const InputDecoration(labelText: 'Passing score (%)'),
          ),
        ),
      ],
    ),
    const SizedBox(height: 16),
    if (quiz.isEmpty)
      const InfoCard(child: Text('No questions yet. Add the first one.')),
    for (var i = 0; i < quiz.length; i++)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InfoCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: deepBlue,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz[i].type.label.toUpperCase(),
                      style: const TextStyle(
                        color: purple,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quiz[i].prompt,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Answer: ${quiz[i].displayAnswer}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Move question up',
                onPressed: i == 0 ? null : () => _moveQuestion(i, -1),
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                tooltip: 'Move question down',
                onPressed: i == quiz.length - 1
                    ? null
                    : () => _moveQuestion(i, 1),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              IconButton(
                tooltip: 'Edit question',
                onPressed: () => _editQuestion(i),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete question',
                onPressed: () => _change(() => quiz.removeAt(i)),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: () => _editQuestion(),
        icon: const Icon(Icons.add),
        label: const Text('Add question'),
      ),
    ),
  ]);
}

// ------------------------------------------------------------ lesson editor
class LessonEditorDialog extends StatefulWidget {
  const LessonEditorDialog({
    super.key,
    required this.lesson,
    required this.isNew,
  });
  final CourseLesson lesson;
  final bool isNew;

  @override
  State<LessonEditorDialog> createState() => _LessonEditorDialogState();
}

class _LessonEditorDialogState extends State<LessonEditorDialog> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.lesson.title);
  late final url = TextEditingController(
    text: widget.lesson.hasFile ? '' : widget.lesson.url,
  );
  late final body = TextEditingController(text: widget.lesson.body);
  late final minutes = TextEditingController(text: '${widget.lesson.minutes}');
  late LessonKind kind = widget.lesson.kind;
  late String fileId = widget.lesson.fileId;
  late String fileName = widget.lesson.fileName;
  late int fileSize = widget.lesson.fileSize;
  late bool useUpload = widget.lesson.hasFile;
  double? progress;
  String? error;

  bool get _canUpload => kind.extensions.isNotEmpty;

  @override
  void dispose() {
    for (final c in [title, url, body, minutes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _upload() async {
    setState(() => error = null);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: kind.extensions,
        withData: true,
      );
      if (picked == null || !mounted) return;
      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        setState(() => error = 'That file could not be read.');
        return;
      }
      if (bytes.length > LessonFiles.maxBytes) {
        setState(
          () => error =
              '${file.name} is ${formatBytes(bytes.length)}. Upload files up to 10 MB, or put larger videos on YouTube and paste the link.',
        );
        return;
      }
      setState(() => progress = 0);
      final id = await LessonFiles.upload(
        bytes,
        file.name,
        uploadedBy: AuthPrototypeStore.instance.email ?? '',
        onProgress: (p) {
          if (mounted) setState(() => progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        fileId = id;
        fileName = file.name;
        fileSize = bytes.length;
        progress = null;
        if (title.text.trim().isEmpty) {
          title.text = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          progress = null;
          error =
              'Upload failed: ${'$e'.replaceFirst('Invalid argument(s): ', '')}';
        });
      }
    }
  }

  void _save() {
    if (!form.currentState!.validate()) return;
    final link = url.text.trim();
    final hasUpload = useUpload && _canUpload && fileId.isNotEmpty;
    if (kind != LessonKind.reading && !hasUpload && link.isEmpty) {
      setState(
        () => error = _canUpload
            ? 'Upload a file or paste a link for this lesson.'
            : 'Paste the link for this lesson.',
      );
      return;
    }
    if (kind == LessonKind.reading && body.text.trim().isEmpty) {
      setState(() => error = 'Write the reading text for this lesson.');
      return;
    }
    Navigator.pop(
      context,
      widget.lesson.copyWith(
        title: title.text.trim(),
        kind: kind,
        url: kind == LessonKind.reading || hasUpload ? '' : link,
        fileId: hasUpload ? fileId : '',
        fileName: hasUpload
            ? fileName
            : (link.startsWith('assets/') ? widget.lesson.fileName : ''),
        fileSize: hasUpload ? fileSize : 0,
        body: body.text.trim(),
        minutes: int.tryParse(minutes.text.trim()) ?? 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.isNew ? 'Add lesson' : 'Edit lesson'),
    content: SizedBox(
      width: 620,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Lesson title'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<LessonKind>(
                      initialValue: kind,
                      decoration: const InputDecoration(
                        labelText: 'Lesson type',
                      ),
                      items: [
                        for (final k in LessonKind.values)
                          DropdownMenuItem(
                            value: k,
                            child: Row(
                              children: [
                                Icon(k.icon, size: 18),
                                const SizedBox(width: 8),
                                Text(k.label),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (k) => setState(() {
                        if (k == null || k == kind) return;
                        kind = k;
                        // A file of the old type does not fit the new one.
                        fileId = '';
                        fileName = '';
                        fileSize = 0;
                        useUpload = useUpload && _canUpload;
                        error = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: minutes,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Minutes'),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        return n == null || n < 1 || n > 600 ? '1-600' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(kind.hint, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              if (kind != LessonKind.reading) ...[
                if (_canUpload)
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.upload_file),
                        label: Text('Upload a file'),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.link),
                        label: Text('Paste a link'),
                      ),
                    ],
                    selected: {useUpload},
                    onSelectionChanged: (s) =>
                        setState(() => useUpload = s.first),
                  ),
                const SizedBox(height: 12),
                if (useUpload && _canUpload) ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: progress != null ? null : _upload,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          fileId.isEmpty ? 'Choose file' : 'Replace file',
                        ),
                      ),
                      Text(
                        'Accepted: ${kind.extensions.map((e) => '.$e').join(', ')} · up to 10 MB',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  if (progress != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(value: progress),
                    ),
                  if (fileId.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(kind.icon, color: deepBlue),
                      title: Text(fileName),
                      subtitle: Text('Uploaded · ${formatBytes(fileSize)}'),
                    ),
                ] else
                  TextFormField(
                    controller: url,
                    decoration: InputDecoration(
                      labelText: switch (kind) {
                        LessonKind.video => 'YouTube or MP4 link',
                        LessonKind.link => 'Web address',
                        _ => 'Link to the file',
                      },
                      hintText: 'https://',
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty || t.startsWith('assets/')) return null;
                      final u = Uri.tryParse(t);
                      return u == null || !u.isScheme('https') || u.host.isEmpty
                          ? 'Use a full https:// link'
                          : null;
                    },
                  ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: body,
                minLines: kind == LessonKind.reading ? 8 : 3,
                maxLines: kind == LessonKind.reading ? 18 : 6,
                decoration: InputDecoration(
                  labelText: kind == LessonKind.reading
                      ? 'Reading text'
                      : 'Notes for learners (optional)',
                  helperText:
                      'Blank line = new paragraph · start a line with "• " for a bullet',
                  alignLabelWithHint: true,
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: progress != null ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: progress != null ? null : _save,
        child: const Text('Save lesson'),
      ),
    ],
  );
}

// ------------------------------------------------------------ question editor
class QuestionEditorDialog extends StatefulWidget {
  const QuestionEditorDialog({super.key, required this.item});
  final QuizItem item;

  @override
  State<QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<QuestionEditorDialog> {
  late QuizType type = widget.item.type;
  late final prompt = TextEditingController(text: widget.item.prompt);
  late final explanation = TextEditingController(text: widget.item.explanation);
  late final accepted = TextEditingController(
    text: widget.item.type == QuizType.short
        ? widget.item.answers.join(', ')
        : '',
  );
  late final List<TextEditingController> options = [
    for (final o
        in widget.item.type == QuizType.trueFalse ||
                widget.item.type == QuizType.short
            ? const ['', '']
            : (widget.item.options.isEmpty
                  ? const ['', '', '', '']
                  : widget.item.options))
      TextEditingController(text: o),
  ];
  late final Set<int> correct = {
    if (widget.item.type == QuizType.single ||
        widget.item.type == QuizType.multi)
      for (final (i, o) in widget.item.options.indexed)
        if (widget.item.answers.contains(o)) i,
  };
  late bool tfAnswer =
      widget.item.type != QuizType.trueFalse ||
      widget.item.answers.firstOrNull != 'False';
  String? error;

  @override
  void dispose() {
    for (final c in [prompt, explanation, accepted, ...options]) {
      c.dispose();
    }
    super.dispose();
  }

  QuizItem _build() {
    switch (type) {
      case QuizType.trueFalse:
        return QuizItem(
          type: type,
          prompt: prompt.text.trim(),
          options: const ['True', 'False'],
          answers: [tfAnswer ? 'True' : 'False'],
          explanation: explanation.text.trim(),
        );
      case QuizType.short:
        return QuizItem(
          type: type,
          prompt: prompt.text.trim(),
          answers: [
            for (final a in accepted.text.split(','))
              if (a.trim().isNotEmpty) a.trim(),
          ],
          explanation: explanation.text.trim(),
        );
      case QuizType.single || QuizType.multi:
        final kept = <String>[];
        final answers = <String>[];
        for (final (i, c) in options.indexed) {
          final t = c.text.trim();
          if (t.isEmpty) continue;
          kept.add(t);
          if (correct.contains(i)) answers.add(t);
        }
        return QuizItem(
          type: type,
          prompt: prompt.text.trim(),
          options: kept,
          answers: answers,
          explanation: explanation.text.trim(),
        );
    }
  }

  void _save() {
    final item = _build();
    final problem = item.validate();
    if (problem != null) {
      setState(() => error = problem);
      return;
    }
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item.prompt.isEmpty ? 'Add question' : 'Edit question'),
    content: SizedBox(
      width: 620,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<QuizType>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Question type'),
              items: [
                for (final t in QuizType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (t) => setState(() {
                if (t == null) return;
                if (type == QuizType.multi && t == QuizType.single) {
                  final sorted = correct.toList()..sort();
                  correct
                    ..clear()
                    ..addAll(sorted.take(1));
                }
                type = t;
                error = null;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: prompt,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Question'),
            ),
            const SizedBox(height: 16),
            if (type == QuizType.trueFalse)
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('True is correct')),
                  ButtonSegment(value: false, label: Text('False is correct')),
                ],
                selected: {tfAnswer},
                onSelectionChanged: (s) => setState(() => tfAnswer = s.first),
              )
            else if (type == QuizType.short)
              TextField(
                controller: accepted,
                decoration: const InputDecoration(
                  labelText: 'Accepted answers',
                  helperText:
                      'Separate with commas. An answer is correct if it contains any of these (not case-sensitive).',
                  helperMaxLines: 2,
                ),
              )
            else ...[
              Text(
                type == QuizType.multi
                    ? 'Options · tick every correct answer'
                    : 'Options · choose the correct answer',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      type == QuizType.multi
                          ? Checkbox(
                              value: correct.contains(i),
                              onChanged: (v) => setState(
                                () => v == true
                                    ? correct.add(i)
                                    : correct.remove(i),
                              ),
                            )
                          : IconButton(
                              tooltip: 'Mark option ${i + 1} correct',
                              onPressed: () => setState(() {
                                correct
                                  ..clear()
                                  ..add(i);
                              }),
                              icon: Icon(
                                correct.contains(i)
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: correct.contains(i) ? purple : null,
                              ),
                            ),
                      Expanded(
                        child: TextField(
                          controller: options[i],
                          decoration: InputDecoration(
                            labelText: 'Option ${i + 1}',
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove option ${i + 1}',
                        onPressed: options.length <= 2
                            ? null
                            : () => setState(() {
                                options.removeAt(i).dispose();
                                final shifted = {
                                  for (final c in correct)
                                    if (c < i) c else if (c > i) c - 1,
                                };
                                correct
                                  ..clear()
                                  ..addAll(shifted);
                              }),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              if (options.length < 8)
                TextButton.icon(
                  onPressed: () =>
                      setState(() => options.add(TextEditingController())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add option'),
                ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: explanation,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Explanation (shown after the quiz)',
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save question')),
    ],
  );
}

// ------------------------------------------------------------ helpers
Future<String?> _askText(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 460,
        child: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim());
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (c.text.trim().isNotEmpty) Navigator.pop(ctx, c.text.trim());
          },
          child: const Text('Save'),
        ),
      ],
    ),
  ).whenComplete(c.dispose);
}

Future<bool?> _confirm(
  BuildContext context,
  String title,
  String message, {
  String action = 'Delete',
}) => showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(ctx, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(ctx, true),
        child: Text(action),
      ),
    ],
  ),
);
