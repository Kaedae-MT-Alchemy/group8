import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicwebsite/data/course_content.dart';
import 'package:publicwebsite/data/lesson_files.dart';
import 'package:publicwebsite/data/mock_data.dart';
import 'package:publicwebsite/data/progress_store.dart';

import 'support/fake_backend.dart';

void main() {
  setUp(setUpFakeBackend);
  tearDown(() {
    mockCourses
      ..clear()
      ..addAll(seedCourses);
  });

  group('QuizItem', () {
    test('reads the older {prompt, options, answer} shape', () {
      final q = QuizItem.fromJson({
        'prompt': 'Ready?',
        'options': ['Yes', 'No'],
        'answer': 'Yes',
      });
      expect(q.type, QuizType.single);
      expect(q.answers, ['Yes']);
      expect(q.isCorrect(chosen: {'Yes'}), isTrue);
      expect(q.isCorrect(chosen: {'No'}), isFalse);
    });

    test('select-all needs exactly the correct set', () {
      const q = QuizItem(
        type: QuizType.multi,
        prompt: 'Pick',
        options: ['A', 'B', 'C'],
        answers: ['A', 'C'],
      );
      expect(q.isCorrect(chosen: {'A', 'C'}), isTrue);
      expect(q.isCorrect(chosen: {'A'}), isFalse);
      expect(q.isCorrect(chosen: {'A', 'B', 'C'}), isFalse);
    });

    test('short answers match any keyword, ignoring case', () {
      const q = QuizItem(
        type: QuizType.short,
        prompt: 'Name it',
        answers: ['Empathy', 'empathic'],
      );
      expect(q.isCorrect(text: 'I think EMPATHY'), isTrue);
      expect(q.isCorrect(text: 'sympathy'), isFalse);
      expect(q.isCorrect(text: ''), isFalse);
    });

    test('true/false gets default options and round-trips', () {
      final q = QuizItem.fromJson({
        'type': 'tf',
        'prompt': 'Sky is blue',
        'answers': ['True'],
      });
      expect(q.options, ['True', 'False']);
      final again = QuizItem.fromJson(q.toJson());
      expect(again.type, QuizType.trueFalse);
      expect(again.answers, ['True']);
    });

    test('validation catches incomplete questions', () {
      expect(
        const QuizItem(type: QuizType.single, prompt: '').validate(),
        isNotNull,
      );
      expect(
        const QuizItem(
          type: QuizType.single,
          prompt: 'Q',
          options: ['A', 'B'],
          answers: ['A', 'B'],
        ).validate(),
        'Choose exactly one correct answer.',
      );
      expect(
        const QuizItem(
          type: QuizType.multi,
          prompt: 'Q',
          options: ['A', 'B'],
          answers: ['C'],
        ).validate(),
        isNotNull,
      );
      expect(
        const QuizItem(
          type: QuizType.multi,
          prompt: 'Q',
          options: ['A', 'B'],
          answers: ['A', 'B'],
        ).validate(),
        isNull,
      );
    });

    test('quizPercent', () {
      expect(quizPercent([]), 0);
      expect(quizPercent([true, false, true, true]), 75);
    });
  });

  group('course content', () {
    test('every built-in course has full lessons and a mixed quiz', () {
      for (final c in seedCourses) {
        final lessons = c.courseLessons;
        expect(lessons.length, greaterThanOrEqualTo(15), reason: c.id);
        final kinds = lessons.map((l) => l.kind).toSet();
        expect(kinds, containsAll(LessonKind.values), reason: c.id);
        expect(lessons.map((l) => l.module).toSet(), {
          for (var i = 0; i < c.modules.length; i++) i,
        }, reason: '${c.id} has lessons in every module');
        final quiz = c.quizItems;
        expect(quiz.length, 8, reason: c.id);
        expect(quiz.map((q) => q.type).toSet(), QuizType.values.toSet());
        for (final q in quiz) {
          expect(q.validate(), isNull, reason: '${c.id}: ${q.prompt}');
        }
      }
    });

    test('a course without built-in content gets a reading per module', () {
      const c = Course(
        id: 'new-course',
        title: 'New',
        shortDescription: 'x',
        instructor: 'x',
        duration: '1 week',
        level: 'Beginner',
        rating: 0,
        price: 0,
        modules: ['One', 'Two'],
      );
      expect(c.courseLessons.map((l) => l.title), ['One', 'Two']);
      expect(c.quizItems, isEmpty);
    });

    test(
      'saved lessons and quiz replace the built-in ones and persist',
      () async {
        final base = mockCourses.firstWhere((c) => c.id == 'mindfulness');
        final custom = base.copyWith(
          lessons: const [
            CourseLesson(
              id: 'l2',
              module: 1,
              title: 'Second',
              kind: LessonKind.pdf,
              fileId: 'f1',
              fileName: 'guide.pdf',
              fileSize: 1200,
            ),
            CourseLesson(
              id: 'l1',
              module: 0,
              title: 'First',
              kind: LessonKind.video,
              url: 'https://www.youtube.com/watch?v=qzR62JJCMBQ',
            ),
            CourseLesson(
              id: 'gone',
              module: 9,
              title: 'Module removed',
              kind: LessonKind.reading,
            ),
          ],
          quiz: [
            const QuizItem(
              type: QuizType.short,
              prompt: 'Name it',
              answers: ['calm'],
            ).toJson(),
          ],
        );
        await saveCourseCatalogue([
          for (final c in mockCourses) c.id == custom.id ? custom : c,
        ]);
        mockCourses.clear();
        await loadCourseCatalogue();
        final restored = mockCourses.firstWhere((c) => c.id == 'mindfulness');
        expect(restored.courseLessons.map((l) => l.title), ['First', 'Second']);
        expect(restored.courseLessons.last.fileName, 'guide.pdf');
        expect(restored.quizItems.single.type, QuizType.short);
      },
    );

    test('progress counts the real lessons and ignores old positions', () {
      final c = mockCourses.firstWhere((c) => c.id == 'leadership');
      final total = c.courseLessons.length;
      expect(lessonPercent(c, {for (var i = 0; i < total; i++) i}), 100);
      expect(lessonPercent(c, {0, 1, 400, -1}), (2 / total * 100).round());
    });
  });

  group('lesson files', () {
    test('large files are split into chunks and read back intact', () async {
      final bytes = Uint8List.fromList(
        List.generate(2 * 1024 * 1024 + 123, (i) => i % 251),
      );
      final id = await LessonFiles.upload(bytes, 'talk.mp4');
      final meta = (await fakeDb.collection('lessonFiles').doc(id).get())
          .data()!;
      expect(meta['chunks'], 3);
      expect(meta['mime'], 'video/mp4');
      final chunks = await fakeDb
          .collection('lessonFiles')
          .doc(id)
          .collection('chunks')
          .get();
      expect(chunks.docs.length, 3);
      expect(await LessonFiles.load(id), bytes);
      await LessonFiles.delete(id);
      expect(
        (await fakeDb.collection('lessonFiles').doc(id).get()).exists,
        isFalse,
      );
    });

    test('files over 10 MB are refused', () async {
      expect(
        () =>
            LessonFiles.upload(Uint8List(LessonFiles.maxBytes + 1), 'big.pdf'),
        throwsArgumentError,
      );
    });
  });
}
