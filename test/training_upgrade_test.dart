import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:publicwebsite/main.dart';
import 'support/fake_backend.dart';
import 'package:publicwebsite/data/course_content.dart';
import 'package:publicwebsite/data/mock_data.dart';
import 'package:publicwebsite/data/progress_store.dart';
import 'package:publicwebsite/shared/auth_prototype_store.dart';

void main() {
  final auth = AuthPrototypeStore.instance;
  setUp(setUpFakeBackend);
  tearDown(() {
    mockCourses
      ..clear()
      ..addAll(seedCourses);
  });

  test(
    'course catalogue persists PDF, quiz, prerequisites and deletion',
    () async {
      const custom = Course(
        id: 'custom',
        title: 'Custom training',
        shortDescription: 'Practice',
        instructor: 'Trainer',
        duration: '1 week',
        level: 'Beginner',
        rating: 0,
        price: 0,
        modules: ['Introduction'],
        prerequisites: ['mindfulness'],
        pdfName: 'guide.pdf',
        pdfBase64: 'JVBERi0=',
        quiz: [
          {
            'prompt': 'Ready?',
            'options': ['Yes', 'No'],
            'answer': 'Yes',
          },
        ],
      );
      await saveCourseCatalogue([...mockCourses, custom]);
      mockCourses.clear();
      await loadCourseCatalogue();
      final restored = mockCourses.firstWhere((c) => c.id == 'custom');
      expect(restored.pdfBase64, 'JVBERi0=');
      expect(restored.quiz.single['answer'], 'Yes');
      expect(restored.prerequisites, ['mindfulness']);
      await saveCourseCatalogue(
        mockCourses.where((c) => c.id != 'custom').toList(),
      );
      await loadCourseCatalogue();
      expect(mockCourses.any((c) => c.id == 'custom'), isFalse);
    },
  );
  test(
    'prerequisites and full lessons plus passing score gate completion',
    () async {
      await auth.signIn('learner@mtalchemy.demo', 'AlchemyLearner!26');
      enrollCourse('leadership');
      expect(enrolledCourses, isNot(contains('leadership')));
      completeCourse('ei-fundamentals', score: 100);
      expect(completedCourses, isEmpty);
      completedLessons['ei-fundamentals'] = {for (var i = 0; i < 20; i++) i};
      completeCourse('ei-fundamentals', score: 40);
      expect(completedCourses, isEmpty);
      completeCourse('ei-fundamentals', score: 80);
      enrollCourse('leadership');
      expect(enrolledCourses, contains('leadership'));
    },
  );
  test('profile names persist per account', () async {
    await auth.signIn('learner@mtalchemy.demo', 'AlchemyLearner!26');
    expect(await auth.updateProfile('A Learner'), isTrue);
    await auth.signIn('trainer@mtalchemy.demo', 'AlchemyTrainer!26');
    await auth.loadProfile();
    expect(auth.displayName, 'MT Alchemy Trainer');
    await auth.signIn('learner@mtalchemy.demo', 'AlchemyLearner!26');
    await auth.loadProfile();
    expect(auth.displayName, 'A Learner');
  });
  for (final role in [
    ('learner', 'AlchemyLearner!26'),
    ('trainer', 'AlchemyTrainer!26'),
    ('employer', 'AlchemyEmployer!26'),
    ('admin', 'AlchemyAdmin!26'),
  ]) {
    testWidgets(
      '${role.$1} account can navigate home, learning and its profile',
      (tester) async {
        await auth.signIn('${role.$1}@mtalchemy.demo', role.$2);
        await tester.pumpWidget(const MtAlchemyApp());
        final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        for (final route in ['/dashboard', '/hub', '/profile', '/']) {
          nav.pushNamed(route);
          await tester.pumpAndSettle();
          expect(find.text('Workspace access required'), findsNothing);
          expect(tester.takeException(), isNull);
          nav.pop();
          await tester.pumpAndSettle();
        }
      },
    );
  }
  testWidgets('Next completes lessons without a blocking snackbar', (
    tester,
  ) async {
    await auth.signIn('learner@mtalchemy.demo', 'AlchemyLearner!26');
    await tester.pumpWidget(const MtAlchemyApp());
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed('/course-player', arguments: 'mindfulness');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(completedLessons['mindfulness'], contains(0));
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('quiz deep link requires lesson completion', (tester) async {
    await auth.signIn('learner@mtalchemy.demo', 'AlchemyLearner!26');
    await tester.pumpWidget(const MtAlchemyApp());
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed('/quiz');
    await tester.pumpAndSettle();
    expect(
      find.text('Complete all lessons before taking the assessment.'),
      findsOneWidget,
    );
    expect(completedCourses, isEmpty);
  });
  testWidgets('admin adds a course, then builds its lessons and quiz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await auth.signIn('admin@mtalchemy.demo', 'AlchemyAdmin!26');
    await tester.pumpWidget(const MtAlchemyApp());
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed('/admin/courses');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add course'));
    await tester.tap(find.text('Add course'));
    await tester.pumpAndSettle();
    for (final entry in [
      ('Course title', 'Safety training'),
      ('Description', 'Workplace skills'),
      ('Duration', '1 week'),
      ('Modules (one per line)', 'Getting started'),
      ('Price (RM)', '150'),
    ]) {
      final field = find.widgetWithText(TextFormField, entry.$1);
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.$2);
    }
    await tester.tap(find.text('Save course'));
    await tester.pumpAndSettle();
    final created = mockCourses.last;
    expect(created.title, 'Safety training');
    expect(created.status, 'Draft');
    expect(created.price, 150);
    expect(publishedCourses.any((c) => c.title == 'Safety training'), isFalse);

    // Open the builder for the new course.
    final open = find.widgetWithText(FilledButton, 'Lessons & quiz').last;
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.text('MODULE 1'), findsOneWidget);

    // Add a link lesson.
    await tester.tap(find.text('Add lesson to module 1'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Lesson title'),
      'Safety guide',
    );
    await tester.tap(find.byType(DropdownButtonFormField<LessonKind>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Link').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Web address'),
      'https://example.com/safety',
    );
    await tester.tap(find.text('Save lesson'));
    await tester.pumpAndSettle();
    expect(find.text('Safety guide'), findsOneWidget);

    // Add a true/false question.
    await tester.tap(find.textContaining('Quiz ('));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add question'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<QuizType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('True or false').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Question'),
      'Ask for help when unsure.',
    );
    await tester.tap(find.text('Save question'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save content'));
    await tester.pumpAndSettle();

    final saved = mockCourses.firstWhere((c) => c.id == created.id);
    final lesson = saved.lessons.firstWhere((l) => l.title == 'Safety guide');
    expect(lesson.kind, LessonKind.link);
    expect(lesson.url, 'https://example.com/safety');
    expect(saved.quizItems.single.type, QuizType.trueFalse);
    expect(saved.quizItems.single.answers, ['True']);
    expect(tester.takeException(), isNull);
  });
}
