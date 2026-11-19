import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:publicwebsite/cms/content_admin_page.dart';
import 'package:publicwebsite/cms/editable.dart';
import 'package:publicwebsite/cms/site_content.dart';
import 'package:publicwebsite/pages.dart';
import 'package:publicwebsite/programme_detail.dart';
import 'package:publicwebsite/shared/auth_prototype_store.dart';
import 'package:publicwebsite/theme.dart';

import 'support/fake_backend.dart';

void main() {
  final store = SiteContentStore.instance;

  setUp(() async {
    await setUpFakeBackend();
    store.reset();
  });
  tearDown(store.reset);

  testWidgets('text overrides from Firestore replace the default', (
    tester,
  ) async {
    store.start();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CmsText(
            'home.hero.title',
            'Default headline',
            style: const TextStyle(),
          ),
        ),
      ),
    );
    expect(find.textContaining('Default headline'), findsOneWidget);

    await fakeDb.collection('siteContent').doc('texts').set({
      'values': {'home.hero.title': 'New headline from the admin'},
    });
    await tester.pump();
    expect(find.textContaining('New headline from the admin'), findsOneWidget);
    expect(find.textContaining('Default headline'), findsNothing);
  });

  test('admin can save, hide and reset content', () async {
    await AuthPrototypeStore.instance.signIn(
      'admin@mtalchemy.demo',
      'AlchemyAdmin!26',
    );
    store.start();
    await store.setText('home.hero.subtitle', 'Edited subtitle');
    await store.setHidden('home.section.stats', true);
    final texts = await fakeDb.collection('siteContent').doc('texts').get();
    expect(texts.data()!['values']['home.hero.subtitle'], 'Edited subtitle');
    expect(store.isHidden('home.section.stats'), isTrue);

    await store.resetAllEdits();
    expect(store.text('home.hero.subtitle', 'fallback'), 'fallback');
    expect(store.isHidden('home.section.stats'), isFalse);
    await AuthPrototypeStore.instance.signOut();
  });

  testWidgets('a new page is stored and shown at its own address', (
    tester,
  ) async {
    store.start();
    final page = SitePage(
      slug: SitePage.slugify('Corporate Wellness Week!'),
      title: 'Corporate Wellness Week',
      body: 'Three days of workshops.\n\nOpen to all staff.',
    );
    expect(page.route, '/p/corporate-wellness-week');
    await store.savePage(page);
    final doc = await fakeDb
        .collection('sitePages')
        .doc('corporate-wellness-week')
        .get();
    expect(doc.data()!['title'], 'Corporate Wellness Week');
    expect(store.menuPages.map((p) => p.slug), contains(page.slug));

    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: SingleChildScrollView(child: SitePageView(slug: page.slug)),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Open to all staff.'), findsOneWidget);

    await store.deletePage(page.slug);
    expect(store.pageBySlug(page.slug), isNull);
  });

  testWidgets('a replaced photo shows instead of the default', (tester) async {
    store.start();
    await tester.pumpWidget(
      const MaterialApp(
        home: SiteImage('about.founder.image', 'assets/images/esther_ng.png'),
      ),
    );
    Image img() => tester.widget<Image>(find.byType(Image));
    expect(
      (img().image as AssetImage).assetName,
      'assets/images/esther_ng.png',
    );
    await fakeDb.collection('siteImages').doc('about.founder.image').set({
      'key': 'about.founder.image',
      'src': 'assets/images/trainer_presenting.jpeg',
    });
    await tester.pump();
    expect(
      (img().image as AssetImage).assetName,
      'assets/images/trainer_presenting.jpeg',
    );
  });

  testWidgets('each programme card opens its own programme page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final s in services) {
      expect(programmeDetails[s.$1], isNotNull, reason: s.$1);
    }
    final route = programmeRoute('Leadership & Communication');
    expect(route, '/programme/leadership-communication');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        onGenerateRoute: buildRoute,
        initialRoute: route,
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Leadership & Communication'), findsWidgets);
    expect(find.text('Enquire about this programme'), findsOneWidget);
    expect(find.text('Programme not found'), findsNothing);
  });
}
