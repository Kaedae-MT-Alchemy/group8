// Worst-case data for the public components (Phase 8 stress test).
//
// Every value is something a real visitor or admin could enter. The test
// renders each component at a phone, a small phone with 200% text and a
// desktop width, and fails on any overflow or layout error. Keep it: it is the
// regression test for the next change to these widgets.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:publicwebsite/data/mock_data.dart';
import 'package:publicwebsite/shared/effects.dart';
import 'package:publicwebsite/shared/programme_carousel.dart';
import 'package:publicwebsite/shared/ui_kit.dart';
import 'package:publicwebsite/theme.dart';
import 'package:publicwebsite/widgets.dart';
import 'package:publicwebsite/widgets/lms/course_card.dart';

const _longTitle =
    'Kecerdasan Emosi untuk Pengurus Pertengahan: Program Persijilan Profesional (HRDC Claimable)';
const _longText =
    'A twelve-week blended programme for middle managers in manufacturing, healthcare and public service, with on-site workshops, fortnightly coaching and a capstone project presented to senior leadership.';

const worstCourse = Course(
  id: 'worst-case',
  title: _longTitle,
  shortDescription: _longText,
  instructor: 'Dr. Nurul Aisyah binti Mohd Kamaruzzaman (Lead Facilitator)',
  duration: '12 weeks (self-paced)',
  level: 'Intermediate to Advanced',
  rating: 4.666666,
  price: 12499.5,
  modules: [],
);

const oneLetterCourse = Course(
  id: 'x',
  title: 'EQ',
  shortDescription: '',
  instructor: 'Jo',
  duration: '1 week',
  level: 'Beginner',
  rating: 0,
  price: 0,
  modules: [],
);

ProgrammeItem _programme(String title, String text, {String? tag}) =>
    ProgrammeItem(
      title: title,
      text: text,
      image: 'assets/images/stock/planning.jpg',
      icon: Icons.psychology_alt_outlined,
      onOpen: () {},
      tag: tag,
    );

final Map<String, Widget Function()> cases = {
  'course card, long everything': () => const CourseCard(course: worstCourse),
  'course card, minimal': () => const CourseCard(course: oneLetterCourse),
  'carousel, empty': () => const ProgrammeCarousel(items: []),
  'carousel, one item': () =>
      ProgrammeCarousel(items: [_programme('Coaching', 'One to one.')]),
  'carousel, long items': () => ProgrammeCarousel(
    items: [
      for (var i = 0; i < 7; i++)
        _programme(
          _longTitle,
          _longText,
          tag: 'Focus area ${i + 1} · Organisational development',
        ),
    ],
  ),
  'photo feature card, long': () => PhotoFeatureCard(
    image: 'assets/images/stock/planning.jpg',
    icon: Icons.school_outlined,
    title: _longTitle,
    text: _longText,
    cta: 'Lihat semua program kepimpinan dan pembangunan',
    onTap: () {},
  ),
  'bento grid, long': () => BentoGrid(
    tiles: [
      for (var i = 0; i < 3; i++)
        BentoTile(
          image: 'assets/images/stock/planning.jpg',
          icon: Icons.business_outlined,
          title: _longTitle,
          text: _longText,
          cta: 'Lihat semua program kepimpinan dan pembangunan',
          onTap: () {},
        ),
    ],
  ),
  'glass bubble': () => const GlassBubble(),
  'flip card, long': () => const FlipCard(
    icon: Icons.groups_2_outlined,
    title: 'Customised organisational development programmes',
    caption: 'Built for your organisation after a two-week needs assessment',
    details: _longText,
  ),
  'section title, long': () => const SectionTitle(
    'Psychological safety, emotional intelligence and well-being for multigenerational workplaces',
    eyebrow: 'Organisational development and team effectiveness',
    subtitle: _longText,
  ),
  'image banner, long': () => const ImageBanner(
    image: 'assets/images/stock/planning.jpg',
    eyebrow: 'Corporate programmes for public and private sector teams',
    title: _longTitle,
    subtitle: _longText,
    height: 240,
  ),
  'stat tile, huge value': () => const StatTile(
    icon: Icons.payments_outlined,
    value: 'RM 1,284,560.00',
    label: 'Revenue from corporate programmes this financial year',
    caption: 'Up 312% on last year across 1,284 employer accounts',
  ),
  'header buttons, long labels': () => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      HeaderButton(
        label: 'Muat turun laporan kemajuan pekerja',
        icon: Icons.download,
        onPressed: () {},
        primary: true,
      ),
      HeaderButton(
        label: 'Jadualkan sesi bimbingan',
        icon: Icons.event,
        onPressed: () {},
      ),
    ],
  ),
};

Future<List<String>> _render(
  WidgetTester tester,
  Widget child,
  Size size,
  double textScale,
) async {
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (d) =>
      errors.add(d.exceptionAsString().split('\n').first);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          backgroundColor: Tok.page,
          body: SingleChildScrollView(
            child: ColoredBox(
              color: Tok.brand,
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  FlutterError.onError = previous;
  return errors;
}

void main() {
  const sizes = {
    'phone 320': (Size(320, 800), 1.0),
    'phone 390 at 200% text': (Size(390, 900), 2.0),
    'desktop 1440': (Size(1440, 900), 1.0),
  };
  for (final c in cases.entries) {
    for (final s in sizes.entries) {
      testWidgets('${c.key} @ ${s.key}', (tester) async {
        addTearDown(tester.view.reset);
        final errors = await _render(tester, c.value(), s.value.$1, s.value.$2);
        expect(errors, isEmpty, reason: errors.toSet().join(' | '));
      });
    }
  }
}
