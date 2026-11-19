import 'widgets/lms/course_card.dart';
import 'admin/course_management.dart';
import 'shared/learning_navigation.dart';
import 'shared/profile_page.dart';
import 'data/mock_data.dart';
import 'data/progress_store.dart';
import 'package:flutter/material.dart';

import 'shared/file_export.dart';
import 'shared/report_document.dart';
import 'cms/content_admin_page.dart';
import 'programme_detail.dart';
import 'cms/editable.dart';
import 'cms/site_content.dart';
import 'shared/effects.dart';
import 'shared/motion.dart';
import 'shared/programme_carousel.dart';
import 'shared/ui_kit.dart';
import 'theme.dart';
import 'widgets.dart';
import 'admin/admin_pages.dart';
import 'admin/user_management.dart';
import 'commerce/order_pages.dart';
import 'commerce/store_pages.dart';
import 'commerce/quote_pages.dart';
import 'commerce/course_purchase_pages.dart';
import 'commerce/stripe_checkout.dart';
import 'commerce/commerce_prototype_store.dart';
import 'employer/employer_pages.dart';
import 'shared/auth_prototype_store.dart';
import 'shared/member3_login_page.dart';
import 'screens/lms/login_register_screen.dart';
import 'screens/lms/learning_hub_screen.dart';
import 'screens/lms/course_detail_screen.dart';
import 'screens/lms/learner_dashboard_screen.dart';
import 'screens/lms/certificate_screen.dart';
import 'screens/lms/certificate_verify.dart';
import 'screens/lms/trainer_dashboard_screen.dart';
import 'screens/lms/course_player_screen.dart';
import 'screens/lms/quiz_screen.dart';

Route<dynamic> buildRoute(RouteSettings settings) {
  final route = settings.name ?? '/';
  if (route.startsWith('/payment-return')) {
    final q = Uri.tryParse(route)?.queryParameters ?? const {};
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => SiteShell(
        route: '/payment-return',
        child: PaymentReturnPage(
          orderNumber: q['order'],
          sessionId: q['session_id'],
          status: q['status'],
        ),
      ),
    );
  }
  if (route.startsWith('/programme/')) {
    final slug = route.substring('/programme/'.length);
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => SiteShell(
        route: route,
        child: ProgrammeDetailPage(slug: slug),
      ),
    );
  }
  if (route.startsWith('/p/')) {
    final slug = route.substring(3);
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => SiteShell(
        route: route,
        child: SitePageView(slug: slug),
      ),
    );
  }
  if (route.startsWith('/verify')) {
    final id =
        Uri.tryParse(route)?.queryParameters['id'] ??
        (settings.arguments is String ? settings.arguments! as String : null);
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => SiteShell(
        route: '/verify',
        child: CertificateVerifyPage(initialId: id),
      ),
    );
  }
  final requiredRoles = _requiredRolesFor(route);
  if (requiredRoles != null &&
      !requiredRoles.any(AuthPrototypeStore.instance.hasRole)) {
    final requiredRole = requiredRoles.join(' or ');
    final signedIn = AuthPrototypeStore.instance.isSignedIn;
    final page = signedIn
        ? Member3AccessDeniedPage(requiredRole: requiredRole)
        : Member3LoginPage(
            redirectRoute: route,
            redirectArguments: settings.arguments,
            requiredRole: requiredRole,
            allowedRoles: requiredRoles,
          );
    return MaterialPageRoute(
      settings: const RouteSettings(name: '/login'),
      builder: (_) => signedIn ? SiteShell(route: '/login', child: page) : page,
    );
  }
  if (route == '/login' && AuthPrototypeStore.instance.isSignedIn) {
    return buildRoute(RouteSettings(name: accountDashboard));
  }
  if ({
    '/course-detail',
    '/course-player',
    '/enroll',
    '/quiz',
    '/certificate',
  }.contains(route)) {
    final id = settings.arguments is String
        ? settings.arguments as String
        : settings.arguments is Map
        ? (settings.arguments as Map)['courseId'] as String? ??
              'ei-fundamentals'
        : 'ei-fundamentals';
    final course = mockCourses.where((c) => c.id == id).firstOrNull;
    if (course == null) {
      return MaterialPageRoute(
        builder: (_) => const SiteShell(
          route: '/hub',
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text(
              'This course is no longer available. Browse courses from the menu.',
            ),
          ),
        ),
      );
    }
    if ({'/enroll', '/course-player', '/quiz'}.contains(route) &&
        !course.prerequisites.every(completedCourses.contains)) {
      return buildRoute(RouteSettings(name: '/course-detail', arguments: id));
    }
  }
  final page = switch (route) {
    '/' => const HomePage(),
    '/individual' => const IndividualHomePage(),
    '/sitemap' => const SitemapPage(),
    '/about' => const AboutPage(),
    '/services' => const ServicesPage(),
    '/coaching' => const CoachingPage(),
    '/organizations' => const OrganizationsPage(),
    '/programmes' => const ProgrammesPage(),
    '/impact' => const ImpactPage(),
    '/insights' => const InsightsPage(),
    '/contact' => ContactPage(
      initialEnquiryType: settings.arguments is String
          ? settings.arguments! as String
          : null,
    ),
    '/upskilling' => const LearningHubScreen(),
    '/hub' => const LearningHubScreen(),
    '/course-detail' => CourseDetailScreen(
      courseId: settings.arguments is String
          ? settings.arguments! as String
          : 'ei-fundamentals',
    ),
    '/store' => const StorePage(),
    '/login' => Member3LoginPage(
      redirectRoute: settings.arguments is String
          ? settings.arguments! as String
          : null,
    ),
    '/register' => LoginRegisterScreen(
      employer: settings.arguments == 'employer',
    ),
    '/cart' => const CartPage(),
    '/product' => ProductDetailPage(
      productId: settings.arguments is String
          ? settings.arguments! as String
          : null,
    ),
    '/enroll' => CourseEnrolScreen(
      courseId: settings.arguments is String
          ? settings.arguments! as String
          : 'ei-fundamentals',
    ),
    '/purchase-courses' => const PurchaseCoursesPage(),
    '/dashboard' => LearnerDashboardScreen(
      enroll: route == '/enroll',
      courseId: settings.arguments is String
          ? settings.arguments! as String
          : 'ei-fundamentals',
    ),
    '/course-player' => CoursePlayerScreen(
      courseId: settings.arguments is String
          ? settings.arguments! as String
          : 'ei-fundamentals',
    ),
    '/quiz' => QuizScreen(
      courseId: settings.arguments is String
          ? settings.arguments! as String
          : 'ei-fundamentals',
    ),
    '/certificate' => CertificateScreen(
      courseId: settings.arguments is Map
          ? (settings.arguments as Map)['courseId'] as String? ??
                'ei-fundamentals'
          : 'ei-fundamentals',
      score: settings.arguments is Map
          ? (settings.arguments as Map)['score'] as String? ?? ''
          : '',
    ),
    '/trainer-dashboard' => const TrainerDashboardScreen(),
    '/checkout' => const CheckoutPage(),
    '/quote-request' => QuoteRequestPage(
      productId: settings.arguments is String
          ? settings.arguments! as String
          : null,
    ),
    '/quote-confirmation' => QuoteConfirmationPage(
      reference: settings.arguments is String
          ? settings.arguments! as String
          : null,
    ),
    '/quote-requests' => const MyQuoteRequestsPage(),
    '/order-confirmation' => OrderConfirmationPage(
      orderNumber: settings.arguments is String
          ? settings.arguments! as String
          : null,
    ),
    '/order-details' => OrderConfirmationPage(
      confirmation: false,
      orderNumber: settings.arguments is String
          ? settings.arguments! as String
          : null,
    ),
    '/orders' => const MyOrdersPage(),
    '/digital-library' => const DigitalProductLibraryPage(),
    '/employer' => const EmployerDashboardPage(),
    '/employees' => const EmployeeManagementPage(),
    '/assign-course' => const CourseAssignmentPage(),
    '/reports' => const LearningReportsPage(),
    '/admin' => const AdminDashboardPage(),
    '/admin/courses' => const CourseManagementPage(),
    '/admin/content' => const ContentAdminPage(),
    '/admin/users' => const UserManagementPage(),
    '/admin/organizations' => const UserManagementPage(organizations: true),
    '/profile' => const AccountProfilePage(),
    '/admin/products' => const ProductManagementPage(),
    '/admin/orders' => const OrderManagementPage(),
    '/admin/quotes' => const QuoteManagementPage(),
    '/admin/enquiries' => const ContactEnquiriesPage(),
    _ => const HomePage(),
  };
  return MaterialPageRoute(
    settings: settings,
    builder: (_) {
      if (const {
        '/login',
        '/register',
        '/hub',
        '/upskilling',
        '/course-detail',
        '/dashboard',
        '/enroll',
        '/course-player',
        '/quiz',
        '/certificate',
        '/trainer-dashboard',
      }.contains(route)) {
        return page;
      }

      return SiteShell(route: route, child: page);
    },
  );
}

List<String>? _requiredRolesFor(String route) {
  if (route == '/admin/courses') return ['Admin', 'Trainer'];
  if (route == '/admin' || route.startsWith('/admin/')) return ['Admin'];
  if (const {'/quote-request', '/quote-confirmation'}.contains(route)) {
    return ['Employer', 'Admin'];
  }
  if (route == '/employer' ||
      route == '/employees' ||
      route == '/assign-course' ||
      route == '/reports' ||
      route == '/purchase-courses' ||
      route == '/quote-requests') {
    return ['Employer'];
  }
  if (route == '/trainer-dashboard') return ['Trainer'];
  if (route == '/dashboard' ||
      route == '/enroll' ||
      route == '/quiz' ||
      route == '/certificate') {
    return ['Learner', 'Employer', 'Trainer', 'Admin'];
  }
  if (route == '/profile' || route == '/course-player') {
    return ['Learner', 'Employer', 'Trainer', 'Admin'];
  }
  if (const {
    '/checkout',
    '/orders',
    '/order-details',
    '/order-confirmation',
  }.contains(route)) {
    return ['Learner', 'Employer'];
  }
  if (route == '/digital-library') return ['Learner'];
  return null;
}

const services = [
  (
    'Emotional Intelligence & Mindfulness',
    Icons.self_improvement,
    'Build self-awareness, emotional regulation and deliberate responses to workplace pressure.',
  ),
  (
    'Leadership & Communication',
    Icons.record_voice_over_outlined,
    'Develop empathetic leaders who communicate clearly and influence with confidence.',
  ),
  (
    'Organization Well-being Assessment',
    Icons.monitor_heart_outlined,
    'Understand workplace needs and identify practical opportunities for healthier teams.',
  ),
  (
    'Team Building & Effectiveness',
    Icons.groups_2_outlined,
    'Strengthen trust, collaboration, problem-solving and shared purpose through experience.',
  ),
  (
    'CSR & ESG',
    Icons.volunteer_activism_outlined,
    'Connect people with meaningful community initiatives aligned with organizational values.',
  ),
  (
    'Customized Programmes',
    Icons.tune_outlined,
    'Adapt objectives, activities and delivery to workforce needs and team demographics.',
  ),
];

/// Image for each service card (company photos first, CC0 stock otherwise).
const serviceImages = {
  'Emotional Intelligence & Mindfulness': 'assets/images/stock/meditation.jpg',
  'Leadership & Communication': 'assets/images/stock/leadership.jpg',
  'Organization Well-being Assessment':
      'assets/images/stock/balance_stones.jpg',
  'Team Building & Effectiveness':
      'assets/images/workshop_team_creativity.jpeg',
  'CSR & ESG': 'assets/images/impact_youth_group.jpeg',
  'Customized Programmes': 'assets/images/stock/facilitator.jpg',
};

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 600;
    return Column(
      children: [
        // 1. Hero: animated banner with the two ways in.
        const _HomeHero(),
        // 2. Key figures, counting up.
        CmsSection(
          'home.section.stats',
          label: 'Key numbers',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Tok.surface,
                  border: Border(bottom: BorderSide(color: Tok.border)),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: narrow ? Tok.s5 : Tok.s6,
                ),
                child: const PageWidth(
                  child: TileGrid(
                    maxColumns: 4,
                    minTileWidth: 150,
                    children: [
                      _StatBandItem('1,100+', 'participants impacted'),
                      _StatBandItem('6', 'focus areas for growth'),
                      _StatBandItem('8', 'self-paced courses'),
                      _StatBandItem('5', 'sectors served'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        PageWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CmsSection(
                'home.section.programmes',
                label: 'What we do (rotating cards)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 3. Programme types on a rotating wheel.
                    const SectionTitle(
                      'What we do',
                      eyebrow: 'Our programmes',
                      subtitle:
                          'Six focus areas, run as workshops, coaching or a programme built for your team. Use the arrows or swipe to look around.',
                      center: true,
                    ),
                    Reveal(
                      child: ProgrammeCarousel(
                        items: [
                          for (final (i, item) in services.indexed)
                            ProgrammeItem(
                              title: item.$1,
                              text: item.$3,
                              icon: item.$2,
                              tag: 'Programme ${i + 1} of ${services.length}',
                              image:
                                  serviceImages[item.$1] ??
                                  'assets/images/stock/planning.jpg',
                              onOpen: () =>
                                  go(context, programmeRoute(item.$1)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              CmsSection(
                'home.section.formats',
                label: 'Programme formats (flip cards)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Programme formats as flip cards.
                    const SectionTitle(
                      'Pick the format that fits.',
                      eyebrow: 'How we work',
                      subtitle:
                          'Every focus area runs in four formats. Hover or tap a card to see what each one includes.',
                    ),
                    const _ProgrammeFormats(),
                  ],
                ),
              ),
              CmsSection(
                'home.section.bento',
                label: 'Growth that starts from within',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 4. Three ways to work with MT Alchemy.
                    const SectionTitle(
                      'Growth that starts from within.',
                      eyebrow: 'About MT Alchemy',
                      subtitle:
                          'A people development consultancy helping individuals, teams and organizations grow through emotional intelligence, leadership, team effectiveness and workplace well-being.',
                    ),
                    BentoGrid(
                      tiles: [
                        BentoTile(
                          image: 'assets/images/stock/team_laughing.jpg',
                          icon: Icons.business_outlined,
                          title: 'Work With Us',
                          text:
                              'Strengthen leadership, culture and organizational well-being with programmes designed around your teams.',
                          cta: 'For organizations',
                          onTap: () => go(context, '/organizations'),
                        ),
                        BentoTile(
                          image: 'assets/images/stock/online_learning.jpg',
                          icon: Icons.school_outlined,
                          title: 'Upskill With Us',
                          text:
                              'Self-paced courses with quizzes and certificates, plus scheduled public programmes.',
                          cta: 'Browse courses',
                          onTap: () => go(context, '/hub'),
                        ),
                        BentoTile(
                          image: 'assets/images/stock/journal.jpg',
                          icon: Icons.shopping_bag_outlined,
                          title: 'Shop',
                          text:
                              'Workbooks, journals and team kits that keep learning going after the workshop.',
                          cta: 'Visit the store',
                          onTap: () => go(context, '/store'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CmsSection(
                'home.section.learning',
                label: 'Learn at your own pace',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 5. How online learning works, as three steps.
                    const SectionTitle(
                      'Learn at your own pace.',
                      eyebrow: 'Upskilling',
                      subtitle:
                          'Build workplace skills with guided courses, practical resources and certificates.',
                    ),
                    const _LearningSteps(),
                    const SizedBox(height: Tok.s6),
                    ResponsiveGrid(
                      children: [
                        for (final course in publishedCourses.take(3))
                          TiltHover(
                            child: CourseCard(
                              course: course,
                              onViewCourse: () => go(
                                context,
                                '/course-detail',
                                arguments: course.id,
                              ),
                              onContinueCourse: () => go(
                                context,
                                '/course-player',
                                arguments: course.id,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: Tok.s5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => go(context, '/hub'),
                        icon: const Icon(Icons.grid_view_rounded),
                        label: const Text('See all courses'),
                      ),
                    ),
                  ],
                ),
              ),
              // 6. Impact photos gliding past.
              CmsSection(
                'home.section.impact',
                label: 'Impact photos',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle(
                      'Real people. Meaningful experiences.',
                      eyebrow: 'Impact',
                      subtitle:
                          'Experiential sessions with schools, corporate teams, youth groups and communities.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        CmsSection(
          'home.section.impact',
          label: 'Impact photos',
          showBar: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Reveal(
                child: Marquee(
                  itemWidth: narrow ? 240 : 320,
                  height: narrow ? 180 : 230,
                  gap: Tok.s4,
                  children: [
                    for (final (path, label) in _ImpactGallery.photos)
                      _ImpactPhoto(path: path, label: label),
                  ],
                ),
              ),
            ],
          ),
        ),
        PageWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CmsSection(
                'home.section.impact',
                label: 'Impact photos',
                showBar: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: Tok.s5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () => go(context, '/impact'),
                        icon: const Icon(Icons.auto_stories_outlined),
                        label: const Text('Read impact stories'),
                      ),
                    ),
                  ],
                ),
              ),
              CmsSection(
                'home.section.testimonials',
                label: 'Testimonials',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 7. Testimonials.
                    const SectionTitle(
                      'What our participants say',
                      eyebrow: 'Testimonials',
                      subtitle:
                          'Feedback from MT Alchemy programme participants.',
                    ),
                    const ResponsiveGrid(
                      children: [
                        _TestimonialCard(
                          quote:
                              'The trainer was very well-prepared and explained the content clearly with real-life examples.',
                          detail: 'Participant feedback · Training session',
                        ),
                        _TestimonialCard(
                          quote:
                              'I learned the importance of empathic communication.',
                          detail: 'Participant takeaway · Leadership learning',
                        ),
                        _TestimonialCard(
                          quote:
                              'All were good as it is a reminder to connect with myself.',
                          detail:
                              'Participant feedback · Mindfulness programme',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Tok.s8),
            ],
          ),
        ),
        // 8. Final call to action.
        ImageBanner(
          image: 'assets/images/stock/handshake.jpg',
          eyebrow: 'Get in touch',
          title: 'Ready to build a stronger workplace?',
          subtitle:
              'Start a conversation about leadership, team effectiveness and workplace well-being.',
          height: 280,
          actions: [
            HeaderButton(
              label: 'Contact MT Alchemy',
              icon: Icons.mail_outline,
              primary: true,
              onPressed: () => go(context, '/contact'),
            ),
            HeaderButton(
              label: 'Get a free consultation',
              icon: Icons.event_available_outlined,
              onPressed: () =>
                  go(context, '/contact', arguments: 'Corporate Training'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      width: double.infinity,
      color: Tok.brand,
      child: Stack(
        children: [
          const Positioned.fill(child: AmbientShapes()),
          PageWidth(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: width < 600 ? 48 : 88),
              child: LayoutBuilder(
                builder: (context, box) {
                  final wide = box.maxWidth >= 860;
                  final small = box.maxWidth < 600;
                  final text = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Reveal(
                        child: CmsValue(
                          'home.hero.eyebrow',
                          'People first. Possibility always.',
                          label: 'hero label',
                          builder: (context, v) => Eyebrow(v, light: true),
                        ),
                      ),
                      const SizedBox(height: Tok.s5),
                      Reveal(
                        delay: const Duration(milliseconds: 100),
                        child: CmsText(
                          'home.hero.title',
                          'Elevate your value: Master *human intelligence* in a rapidly evolving AI-driven world.',
                          label: 'hero headline',
                          accent: Tok.accent,
                          style: Tok.heading(
                            small ? 34 : 50,
                            color: Colors.white,
                            height: 1.08,
                          ),
                        ),
                      ),
                      const SizedBox(height: Tok.s4),
                      Reveal(
                        delay: const Duration(milliseconds: 200),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Programmes for ',
                              style: Tok.heading(
                                small ? 20 : 24,
                                color: Colors.white,
                              ),
                            ),
                            RotatingWords(
                              words: const [
                                'leaders',
                                'teams',
                                'schools',
                                'you',
                              ],
                              style: Tok.heading(
                                small ? 20 : 24,
                                color: Tok.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Tok.s4),
                      const Reveal(
                        delay: Duration(milliseconds: 280),
                        child: CmsText(
                          'home.hero.subtitle',
                          'Build self-aware leaders, resilient teams and a workplace where people thrive.',
                          label: 'hero intro',
                          multiline: true,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: Tok.s6),
                      Reveal(
                        delay: const Duration(milliseconds: 360),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "I'm browsing as:",
                              style: TextStyle(
                                color: Tok.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: Tok.s3),
                            PathChoiceCard(
                              icon: Icons.person_outline,
                              title: 'An individual',
                              text:
                                  'Courses, certificates, coaching and resources',
                              onTap: () => go(context, '/individual'),
                            ),
                            const SizedBox(height: 10),
                            PathChoiceCard(
                              icon: Icons.business_outlined,
                              title: 'An organization',
                              text:
                                  'Programmes, team learning and employee reports',
                              onTap: () => go(context, '/organizations'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  final photo = Reveal(
                    delay: const Duration(milliseconds: 250),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Fine gold ring ornament behind the photo.
                        Positioned(
                          right: -28,
                          top: -28,
                          child: ExcludeSemantics(
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Tok.accent.withValues(alpha: 0.7),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        CmsImage(
                          'home.hero.image',
                          'assets/images/home_hero_team_building.jpeg',
                          label: 'hero photo',
                          builder: (context, provider) => ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image(
                              image: provider,
                              height: wide ? 480 : 260,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              semanticLabel:
                                  'MT Alchemy team building workshop participants',
                            ),
                          ),
                        ),
                        // Glass bubble floating over the photo corner.
                        Positioned(
                          left: wide ? -70 : -20,
                          top: wide ? -60 : -30,
                          child: FloatY(
                            phase: 0.25,
                            child: GlassBubble(size: wide ? 160 : 100),
                          ),
                        ),
                        Positioned(
                          left: wide ? -24 : 12,
                          bottom: wide ? 32 : 12,
                          child: const FloatY(
                            child: _FloatingBadge(
                              icon: Icons.groups_2,
                              value: '1,100+',
                              label: 'participants impacted',
                            ),
                          ),
                        ),
                        const Positioned(
                          right: 12,
                          top: 12,
                          child: FloatY(
                            phase: 0.5,
                            child: _FloatingBadge(
                              icon: Icons.workspace_premium,
                              value: 'HRDC',
                              label: 'certified trainer',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  return wide
                      ? Row(
                          children: [
                            Expanded(child: text),
                            const SizedBox(width: 64),
                            Expanded(child: photo),
                          ],
                        )
                      : Column(
                          children: [text, const SizedBox(height: 40), photo],
                        );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(Tok.rMd + 4),
      boxShadow: const [
        BoxShadow(
          color: Color(0x3316105B),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Tok.accent,
            borderRadius: BorderRadius.circular(Tok.rSm + 2),
          ),
          child: Icon(icon, color: Tok.brandDeep, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: Tok.display,
                fontWeight: FontWeight.w700,
                color: Tok.brand,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Tok.textMuted),
            ),
          ],
        ),
      ],
    ),
  );
}

class _StatBandItem extends StatelessWidget {
  const _StatBandItem(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 3,
        height: 52,
        decoration: BoxDecoration(
          color: Tok.accent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: Tok.s4),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CountUp(
              value,
              style: const TextStyle(
                fontFamily: Tok.display,
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: Tok.brand,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Tok.textMuted, fontSize: 15),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Choose → Learn → Earn, joined by a line that draws itself in.
class _LearningSteps extends StatelessWidget {
  const _LearningSteps();

  static const _steps = [
    (
      Icons.travel_explore_rounded,
      'Choose a course',
      'Pick a topic like leadership, mindfulness or well-being.',
    ),
    (
      Icons.play_circle_outline_rounded,
      'Learn with videos',
      'Short lessons, real examples and articles you can read later.',
    ),
    (
      Icons.workspace_premium_outlined,
      'Earn a certificate',
      'Pass the quiz and download a certificate anyone can verify.',
    ),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth >= 760;
      final items = [
        for (final (i, (icon, title, text)) in _steps.indexed)
          Reveal(
            delay: Duration(milliseconds: 140 * i),
            child: _StepItem(
              number: i + 1,
              icon: icon,
              title: title,
              text: text,
            ),
          ),
      ];
      if (!wide) {
        return Column(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: Tok.s5),
                child: item,
              ),
          ],
        );
      }
      return Stack(
        children: [
          Positioned(
            left: 32,
            right: box.maxWidth / 3,
            top: 31,
            child: const _DrawLine(),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: Tok.s5),
                    child: item,
                  ),
                ),
            ],
          ),
        ],
      );
    },
  );
}

class _DrawLine extends StatefulWidget {
  const _DrawLine();

  @override
  State<_DrawLine> createState() => _DrawLineState();
}

class _DrawLineState extends State<_DrawLine> {
  bool _drawn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _drawn = true);
    });
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Reveal(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _drawn ? 1 : 0),
        duration: Motion.enabled(context)
            ? const Duration(milliseconds: 1400)
            : Duration.zero,
        curve: Tok.easeInOut,
        builder: (context, v, _) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: v,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: Tok.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    ),
  );
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
  });
  final int number;
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Tok.surface,
          shape: BoxShape.circle,
          border: Border.all(color: Tok.brandTint, width: 6),
        ),
        child: Icon(icon, color: Tok.brand, size: 28),
      ),
      const SizedBox(height: Tok.s4),
      Text(
        'STEP $number',
        style: const TextStyle(
          color: Tok.calmText,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          fontSize: 12.5,
        ),
      ),
      const SizedBox(height: Tok.s1),
      Text(title, style: Tok.heading(20)),
      const SizedBox(height: Tok.s1),
      Text(text, style: const TextStyle(color: Tok.textMuted, height: 1.5)),
    ],
  );
}

class _ImpactPhoto extends StatelessWidget {
  const _ImpactPhoto({required this.path, required this.label});
  final String path;
  final String label;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(Tok.rLg),
    child: Stack(
      fit: StackFit.expand,
      children: [
        SiteImage(
          '${contentKey('photo', label)}.image',
          path,
          semanticLabel: label,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Tok.brandDeep.withValues(alpha: 0.8),
              ],
              stops: const [0.5, 1],
            ),
          ),
        ),
        Positioned(
          left: Tok.s4,
          bottom: 14,
          right: Tok.s4,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ImpactGallery {
  static const photos = [
    ('assets/images/impact_inti_workshop.jpeg', 'University workshop'),
    ('assets/images/impact_teachers_retreat.jpeg', 'Teachers retreat'),
    ('assets/images/impact_youth_group.jpeg', 'Youth leadership'),
    ('assets/images/impact_classroom_workshop.jpeg', 'Classroom EQ session'),
    ('assets/images/impact_creative_art.jpeg', 'Creative reflection'),
    ('assets/images/workshop_group_activity.jpeg', 'Corporate team building'),
  ];
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.quote, required this.detail});
  final String quote;
  final String detail;
  @override
  Widget build(BuildContext context) => InfoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 5; i++)
              const Icon(Icons.star_rounded, color: Tok.accent, size: 20),
          ],
        ),
        const SizedBox(height: Tok.s4),
        Text(
          '“$quote”',
          style: const TextStyle(fontSize: 17.5, height: 1.55, color: Tok.text),
        ),
        const SizedBox(height: Tok.s5),
        Container(height: 1, color: Tok.border),
        const SizedBox(height: Tok.s3),
        Text(detail, style: const TextStyle(color: Tok.textMuted)),
      ],
    ),
  );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => PageWidth(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          'People grow. Teams flourish. Organizations thrive.',
          eyebrow: 'About us',
          subtitle:
              'MT Alchemy believes lasting change begins with understanding both people and systems.',
        ),
        ResponsiveGrid(
          children: const [
            InfoCard(
              color: Color(0xFFFFF0B9),
              child: _Statement(
                title: 'Vision',
                text:
                    'To develop authentic leaders with emotional strength who navigate personal and professional relationships with clarity and confidence.',
              ),
            ),
            InfoCard(
              color: Color(0xFFEFEAFE),
              child: _Statement(
                title: 'Mission',
                text:
                    'To build emotional intelligence and resilient cultures through experiential learning, creating fulfilling and sustainable work environments.',
              ),
            ),
            InfoCard(
              child: _Statement(
                title: 'Our approach',
                text:
                    'Self-awareness → Emotional intelligence → Effective communication → Authentic leadership → Resilient culture.',
              ),
            ),
          ],
        ),
        const SectionTitle(
          'Why emotional intelligence matters',
          subtitle:
              'Many workplace challenges are rooted in emotional and interpersonal factors. Self-awareness and empathy help people communicate, lead and respond to pressure more effectively.',
        ),
        const PhotoCard(
          path: 'assets/images/workshop_eq_facilitator.jpeg',
          title: 'Experiential learning',
          subtitle:
              'Practical tools, meaningful reflection and active participation help turn insight into everyday behaviour.',
          height: 420,
        ),
        const SectionTitle('Our impact', eyebrow: 'Growing reach'),
        const ResponsiveGrid(
          children: [
            InfoCard(
              color: Color(0xFFFFF0B9),
              child: _Statement(
                title: '1,100+ participants',
                text:
                    'Reached through education, corporate teams, youth leadership and community programmes.',
              ),
            ),
            InfoCard(
              child: _Statement(
                title: 'Experiential learning',
                text:
                    'Activities, reflection and practical tools support lasting behavioural change.',
              ),
            ),
            InfoCard(
              color: Color(0xFFEFEAFE),
              child: _Statement(
                title: 'Human-centred growth',
                text:
                    'Programmes connect individual self-awareness with healthier teams and workplace cultures.',
              ),
            ),
          ],
        ),
        const SectionTitle('Founder', eyebrow: 'Leadership'),
        InfoCard(
          child: LayoutBuilder(
            builder: (context, box) {
              final photo = ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: const SiteImage(
                  'about.founder.image',
                  'assets/images/trainer_presenting.jpeg',
                  width: 320,
                  height: 360,
                  label: 'Founder photo',
                ),
              );
              final copy = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mabel Tan KH',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: deepBlue,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Founder · EQ Coach · HRDC Certified Trainer',
                    style: TextStyle(
                      color: purple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Mabel combines a people-and-systems perspective to support self-awareness, emotional intelligence and resilience. Her work uses experiential learning and practical application to help develop authentic leaders and healthy workplace cultures.',
                    style: TextStyle(fontSize: 16, height: 1.65),
                  ),
                ],
              );
              return box.maxWidth > 720
                  ? Row(
                      children: [
                        photo,
                        const SizedBox(width: 36),
                        Expanded(child: copy),
                      ],
                    )
                  : Column(children: [photo, const SizedBox(height: 28), copy]);
            },
          ),
        ),
        const SectionTitle(
          'Our team',
          eyebrow: 'People behind the work',
          subtitle:
              'MT Alchemy brings together people development and operational experience to support meaningful, sustainable growth.',
        ),
        InfoCard(
          child: LayoutBuilder(
            builder: (context, box) {
              final photo = ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: const SiteImage(
                  'about.team.esther.image',
                  'assets/images/esther_ng.png',
                  width: 280,
                  height: 300,
                  label: 'Team member photo',
                ),
              );
              final copy = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Esther Ng',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: deepBlue,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Consultant & Operations Advisor',
                    style: TextStyle(
                      color: purple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'With more than 25 years of teaching experience and ISO 9001 auditing experience, Esther supports operations and business development at MT Alchemy.',
                    style: TextStyle(fontSize: 16, height: 1.65),
                  ),
                ],
              );
              return box.maxWidth > 720
                  ? Row(
                      children: [
                        photo,
                        const SizedBox(width: 36),
                        Expanded(child: copy),
                      ],
                    )
                  : Column(children: [photo, const SizedBox(height: 28), copy]);
            },
          ),
        ),
      ],
    ),
  );
}

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});
  @override
  Widget build(BuildContext context) => PageWidth(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          'People development, shaped around real needs.',
          eyebrow: 'Services',
          subtitle:
              'Explore six focus areas designed for healthier teams, stronger leaders and sustainable workplace growth.',
        ),
        Reveal(
          child: ProgrammeCarousel(
            items: [
              for (final (i, item) in services.indexed)
                ProgrammeItem(
                  title: item.$1,
                  text: item.$3,
                  icon: item.$2,
                  tag: 'Focus area ${i + 1}',
                  image:
                      serviceImages[item.$1] ??
                      'assets/images/stock/planning.jpg',
                  onOpen: () => go(context, programmeRoute(item.$1)),
                ),
            ],
          ),
        ),
        const SectionTitle(
          'Four ways to take part',
          eyebrow: 'Formats',
          subtitle: 'Hover or tap a card to see what each format includes.',
        ),
        const _ProgrammeFormats(),
        const SectionTitle('Every focus area at a glance', eyebrow: 'Details'),
        ResponsiveGrid(
          children: [
            for (final item in services)
              InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SiteImage(
                        '${contentKey('programme', item.$1)}.photo',
                        seedCourses[services.indexOf(item)].imageAsset,
                        height: 180,
                        width: double.infinity,
                        label: item.$1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Tok.accent,
                        borderRadius: BorderRadius.circular(Tok.rMd),
                      ),
                      child: Icon(item.$2, color: Tok.brandDeep, size: 22),
                    ),
                    const SizedBox(height: Tok.s4),
                    Text(item.$1, style: Tok.heading(20)),
                    const SizedBox(height: Tok.s2),
                    Text(
                      item.$3,
                      style: const TextStyle(color: Tok.textMuted, height: 1.5),
                    ),
                    const SizedBox(height: Tok.s4),
                    const Text(
                      'Key objectives',
                      style: TextStyle(
                        fontFamily: Tok.display,
                        fontWeight: FontWeight.w600,
                        color: Tok.brandDeep,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (programmeDetails[item.$1]?.$1 ?? const <String>[])
                          .take(3)
                          .map((o) => '• $o')
                          .join('\n'),
                      style: const TextStyle(height: 1.6),
                    ),
                    const SizedBox(height: 22),
                    TextButton(
                      onPressed: () => go(context, programmeRoute(item.$1)),
                      child: const Text('View programme →'),
                    ),
                  ],
                ),
              ),
          ],
        ),
        _Callout(
          title: 'Not sure where to begin?',
          text:
              'Tell us about your organization and we can explore the right starting point together.',
          button: 'Get a free consultation',
          route: '/contact',
        ),
      ],
    ),
  );
}

class CoachingPage extends StatelessWidget {
  const CoachingPage({super.key});
  @override
  Widget build(BuildContext context) => PageWidth(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          'A focused space for clarity and growth.',
          eyebrow: 'Individual coaching',
          subtitle:
              'One-to-one support for people navigating change, relationships, decisions and personal development.',
        ),
        const PhotoCard(
          path: 'assets/images/trainer_presenting.jpeg',
          title: 'Coaching centred on the person',
          subtitle:
              'Reflect, understand what matters and move forward with practical next steps.',
          height: 410,
        ),
        const SectionTitle('Who coaching is for'),
        const ResponsiveGrid(
          children: [
            InfoCard(
              child: _Statement(
                title: 'Career guidance',
                text: 'Clarify strengths, values and a meaningful next step.',
              ),
            ),
            InfoCard(
              child: _Statement(
                title: 'Transitions',
                text:
                    'Navigate professional or personal change with greater confidence.',
              ),
            ),
            InfoCard(
              child: _Statement(
                title: 'Relationships',
                text:
                    'Build self-awareness, empathy and healthier communication.',
              ),
            ),
            InfoCard(
              child: _Statement(
                title: 'Personal development',
                text:
                    'Create habits that support resilience, clarity and growth.',
              ),
            ),
          ],
        ),
        const SectionTitle('Coaching focus'),
        const ResponsiveGrid(
          children: [
            InfoCard(
              color: Color(0xFFFFF8DE),
              child: _Statement(
                title: 'Self-awareness',
                text:
                    'Recognize personal patterns, emotions, strengths and values with greater clarity.',
              ),
            ),
            InfoCard(
              color: Color(0xFFEFEAFE),
              child: _Statement(
                title: 'Emotional clarity',
                text:
                    'Understand difficult emotions and respond with greater intention.',
              ),
            ),
            InfoCard(
              color: Color(0xFFFFF8DE),
              child: _Statement(
                title: 'Confidence & communication',
                text:
                    'Express needs, choices and boundaries with empathy and confidence.',
              ),
            ),
            InfoCard(
              color: Color(0xFFEFEAFE),
              child: _Statement(
                title: 'Purposeful action',
                text:
                    'Turn reflection into practical steps that support personal progress.',
              ),
            ),
          ],
        ),
        const SectionTitle('How it works'),
        const ResponsiveGrid(
          children: [
            InfoCard(
              child: _Statement(
                title: '1 · Discover',
                text:
                    'Start with your goals, context and what you want to change.',
              ),
            ),
            InfoCard(
              child: _Statement(
                title: '2 · Explore',
                text:
                    'Use guided reflection and practical tools to uncover useful insight.',
              ),
            ),
            InfoCard(
              child: _Statement(
                title: '3 · Apply',
                text:
                    'Turn insight into realistic actions and review your progress.',
              ),
            ),
          ],
        ),
        const SectionTitle(
          'Available programmes',
          subtitle:
              'Representative coaching directions can be adapted after an initial conversation.',
        ),
        ResponsiveGrid(
          children: [
            InfoCard(
              child: _CoachingProgramme(
                title: 'Career Clarity Coaching',
                focus:
                    'Strengths, values, career direction and decision-making.',
                format: 'Individual sessions · Online or in person',
              ),
            ),
            InfoCard(
              child: _CoachingProgramme(
                title: 'Transition Support',
                focus:
                    'Confidence, emotional resilience and practical next steps during change.',
                format: 'Individual sessions · Flexible package',
              ),
            ),
            InfoCard(
              child: _CoachingProgramme(
                title: 'Relationship & Communication',
                focus:
                    'Self-awareness, empathy, boundaries and constructive communication.',
                format: 'Individual sessions · Goal-based',
              ),
            ),
            InfoCard(
              child: _CoachingProgramme(
                title: 'Personal Growth Journey',
                focus:
                    'Emotional clarity, resilience, habits and purposeful development.',
                format: 'Individual sessions · Customized',
              ),
            ),
          ],
        ),
        const SectionTitle('Frequently asked questions'),
        const InfoCard(
          child: Column(
            children: [
              ExpansionTile(
                title: Text('Is coaching confidential?'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Coaching conversations are treated respectfully and confidentially within agreed professional boundaries.',
                    ),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('How many sessions will I need?'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'The number and frequency of sessions depend on your goals and will be discussed before the programme begins.',
                    ),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('Can sessions be conducted online?'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Available delivery arrangements can be confirmed when you make an enquiry.',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SectionTitle('What participants say', eyebrow: 'Testimonials'),
        const ResponsiveGrid(
          children: [
            _TestimonialCard(
              quote:
                  'The trainer was very well-prepared and explained the content clearly with real-life examples.',
              detail: 'Anonymous MT Alchemy participant feedback',
            ),
            _TestimonialCard(
              quote: 'She listened to us and encouraged participation.',
              detail: 'Anonymous MT Alchemy participant feedback',
            ),
            _TestimonialCard(
              quote:
                  'It was a good experience to discover mindfulness — something new that works for everyone.',
              detail: 'Anonymous MT Alchemy participant feedback',
            ),
          ],
        ),
        _Callout(
          title: 'Ready to begin?',
          text:
              'Share what you would like to work on and request a coaching conversation.',
          button: 'Book a coaching session',
          route: '/contact',
        ),
      ],
    ),
  );
}

class _CoachingProgramme extends StatelessWidget {
  const _CoachingProgramme({
    required this.title,
    required this.focus,
    required this.format,
  });
  final String title;
  final String focus;
  final String format;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.psychology_outlined, color: purple, size: 38),
      const SizedBox(height: 16),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Text(focus),
      const SizedBox(height: 16),
      Text(
        format,
        style: const TextStyle(color: purple, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class OrganizationsPage extends StatelessWidget {
  const OrganizationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    const challenges = [
      'Employee burnout',
      'Rising stress',
      'Communication breakdowns',
      'Team conflicts',
      'Leadership gaps',
      'Low engagement',
      'High turnover',
    ];
    const solutions = [
      'Leadership development',
      'Emotional intelligence',
      'Team effectiveness',
      'Communication',
      'Workplace well-being',
      'Organizational development',
      'CSR & ESG',
      'Customized training',
    ];
    return PageWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            'Build emotionally intelligent leaders and resilient workplace cultures.',
            eyebrow: 'For organizations',
            subtitle:
                'Support your people with practical development experiences that connect individual growth to organizational outcomes.',
          ),
          const PhotoCard(
            path: 'assets/images/workshop_team_creativity.jpeg',
            title: 'Learn together. Grow together.',
            subtitle:
                'Interactive experiences help teams communicate, solve problems and build trust.',
            height: 430,
          ),
          const SectionTitle(
            'Today’s workplace reality',
            subtitle:
                'Organizational performance is shaped by how people feel, communicate and work together.',
          ),
          ResponsiveGrid(
            children: [
              for (final challenge in challenges)
                InfoCard(
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: purple),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          challenge,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SectionTitle('Solutions for sustainable growth'),
          ResponsiveGrid(
            children: [
              for (final solution in solutions)
                InfoCard(
                  color: const Color(0xFFFFF8DE),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: deepBlue),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          solution,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          _Callout(
            title: 'Start with a conversation.',
            text:
                'Share your goals, team context and development priorities with MT Alchemy.',
            button: 'Talk to MT Alchemy',
            route: '/contact',
          ),
        ],
      ),
    );
  }
}

class ProgrammesPage extends StatelessWidget {
  const ProgrammesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final canViewCorporate =
        AuthPrototypeStore.instance.isSignedIn &&
        const {'Employer', 'Admin'}.contains(AuthPrototypeStore.instance.role);
    final programmes = [
      (
        'Leading with Emotional Intelligence',
        'Leaders and people managers',
        '1–2 days',
        'In-person / blended',
        ['Self-awareness', 'Empathy', 'Emotionally intelligent decisions'],
        [
          'Understanding emotional intelligence',
          'Leading self',
          'Leading others',
        ],
        'Develop the self-awareness and empathy needed to lead people with clarity, confidence and care.',
      ),
      (
        'Mindful Resilience at Work',
        'Employees and teams',
        'Half day / 1 day',
        'In-person / online',
        ['Stress awareness', 'Mindful pause', 'Practical resilience habits'],
        [
          'Understanding workplace stress',
          'Mindfulness practice',
          'Personal resilience plan',
        ],
        'Help employees move from reactive stress toward deliberate focus and sustainable resilience.',
      ),
      (
        'Communication That Connects',
        'Cross-functional teams',
        '1 day',
        'In-person',
        ['Active listening', 'Constructive conversations', 'Team alignment'],
        [
          'Communication styles',
          'Listening and empathy',
          'Difficult conversations',
        ],
        'Strengthen workplace communication through active listening, empathy and constructive dialogue.',
      ),
      (
        'Team Effectiveness Experience',
        'New or evolving teams',
        '1–2 days',
        'In-person',
        ['Trust', 'Collaboration', 'Creative problem-solving'],
        ['Building team trust', 'Collaborative challenge', 'Team reflection'],
        'Build the social connection and mutual trust required for collective resilience and performance.',
      ),
      (
        'Workplace Well-being Discovery',
        'HR and leadership teams',
        'Custom',
        'Assessment / facilitated session',
        ['Current-state insight', 'Priority areas', 'Action planning'],
        ['Well-being assessment', 'Insight review', 'Action priorities'],
        'Explore workplace well-being needs and identify practical priorities for a healthier culture.',
      ),
      (
        'Customized People Development',
        'Organizations with specific needs',
        'Custom',
        'Flexible',
        ['Needs alignment', 'Tailored activities', 'Application to work'],
        [
          'Discovery and design',
          'Experiential learning',
          'Workplace application',
        ],
        'A tailored programme adapted to the organization’s workforce, goals and team demographics.',
      ),
    ];
    return PageWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            canViewCorporate
                ? 'Programmes designed for people and context.'
                : 'Public programmes',
            eyebrow: canViewCorporate ? 'Corporate programmes' : 'Fixed price',
            subtitle: canViewCorporate
                ? 'Browse representative programme directions. Final objectives, duration, group size and investment are tailored after consultation.'
                : 'Scheduled sessions that individuals can join at a published fee.',
          ),
          if (canViewCorporate)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEAFE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Public programme: fixed schedule and published fee.   •   Corporate programme: tailored scope and request a quote.',
                style: TextStyle(fontWeight: FontWeight.w700, color: deepBlue),
              ),
            ),
          if (canViewCorporate)
            const SectionTitle(
              'Public programmes',
              eyebrow: 'Fixed price',
              subtitle:
                  'Scheduled sessions that individuals can join at a published fee.',
            ),
          const ResponsiveGrid(
            children: [
              _PublicProgrammeCard(
                title: 'Emotional Intelligence Essentials',
                description:
                    'An accessible introduction to emotional awareness, regulation and empathy for everyday life and work.',
                objectives: [
                  'Recognize emotional patterns',
                  'Practise emotional regulation',
                  'Communicate with greater empathy',
                ],
                audience: 'Individuals, emerging leaders and working adults',
                duration: '1 day',
                participants: 'Up to 25 participants',
                delivery: 'In-person public workshop',
                modules: [
                  'Understanding emotions',
                  'Self-regulation tools',
                  'Empathy in action',
                ],
                trainer: 'Mabel Tan KH',
                price: 'RM 380 per participant (sample)',
              ),
              _PublicProgrammeCard(
                title: 'Mindfulness for Everyday Resilience',
                description:
                    'A practical workshop for managing stress, creating a mindful pause and building sustainable resilience habits.',
                objectives: [
                  'Understand personal stress responses',
                  'Use simple mindfulness practices',
                  'Create a personal resilience plan',
                ],
                audience: 'Individuals and working adults',
                duration: 'Half day',
                participants: 'Up to 30 participants',
                delivery: 'Online / in person',
                modules: [
                  'Stress awareness',
                  'The mindful pause',
                  'Resilience in daily life',
                ],
                trainer: 'Mabel Tan KH',
                price: 'RM 220 per participant (sample)',
              ),
              _PublicProgrammeCard(
                title: 'Leading with Emotional Intelligence',
                description:
                    'Build practical self-awareness, empathy and communication skills for confident everyday leadership.',
                objectives: [
                  'Recognize personal leadership patterns',
                  'Practise empathetic communication',
                  'Make emotionally intelligent decisions',
                ],
                audience: 'Emerging leaders and people managers',
                duration: '1 day',
                participants: 'Up to 25 participants',
                delivery: 'In-person / blended',
                modules: [
                  'Understanding emotional intelligence',
                  'Leading self',
                  'Leading others',
                ],
                trainer: 'Mabel Tan KH',
                price: 'RM 380 per participant (sample)',
              ),
              _PublicProgrammeCard(
                title: 'Communication That Connects',
                description:
                    'Strengthen active listening, empathy and constructive dialogue for stronger workplace relationships.',
                objectives: [
                  'Use active listening techniques',
                  'Handle difficult conversations',
                  'Build clearer team alignment',
                ],
                audience: 'Working adults and cross-functional teams',
                duration: '1 day',
                participants: 'Up to 30 participants',
                delivery: 'In-person / online',
                modules: [
                  'Communication styles',
                  'Listening with empathy',
                  'Constructive conversations',
                ],
                trainer: 'Mabel Tan KH',
                price: 'RM 320 per participant (sample)',
              ),
            ],
          ),
          if (canViewCorporate) ...[
            const SectionTitle(
              'Corporate programmes',
              eyebrow: 'Request a quote',
              subtitle:
                  'Tailored programmes for employers. Objectives, participant numbers, delivery and modules can adapt to workforce and team demographics.',
            ),
            ResponsiveGrid(
              children: [
                for (final p in programmes)
                  InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Eyebrow('Corporate programme'),
                        const SizedBox(height: 12),
                        Text(
                          p.$1,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        Text(p.$7),
                        const SizedBox(height: 16),
                        _Meta(icon: Icons.people_outline, text: p.$2),
                        const _Meta(
                          icon: Icons.groups_outlined,
                          text: 'Recommended group: 15-30 participants',
                        ),
                        _Meta(icon: Icons.schedule_outlined, text: p.$3),
                        _Meta(icon: Icons.location_on_outlined, text: p.$4),
                        const _Meta(
                          icon: Icons.person_outline,
                          text: 'Trainer: Mabel Tan KH',
                        ),
                        const Divider(height: 30),
                        const Text(
                          'Learning objectives',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        for (final objective in p.$5)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Text('• $objective'),
                          ),
                        const SizedBox(height: 10),
                        const Text(
                          'Modules',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        for (var index = 0; index < p.$6.length; index++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Text('Module ${index + 1}: ${p.$6[index]}'),
                          ),
                        const SizedBox(height: 14),
                        const Text(
                          'Price: Request a quote',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: purple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton(
                              onPressed: () => go(context, '/quote-request'),
                              child: const Text('Request a quote'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => downloadBrochure(context, [
                                p.$1,
                                p.$7,
                                'Audience: ${p.$2}',
                                'Duration: ${p.$3}',
                                'Delivery: ${p.$4}',
                                'Learning objectives:',
                                for (final o in p.$5) '  - $o',
                                'Modules:',
                                for (final (i, m) in p.$6.indexed)
                                  '  Module ${i + 1}: $m',
                                'Price: request a quote at mtalchemy (Contact page).',
                              ]),
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('Brochure'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PublicProgrammeCard extends StatelessWidget {
  const _PublicProgrammeCard({
    required this.title,
    required this.description,
    required this.objectives,
    required this.audience,
    required this.duration,
    required this.participants,
    required this.delivery,
    required this.modules,
    required this.trainer,
    required this.price,
  });
  final String title;
  final String description;
  final List<String> objectives;
  final String audience;
  final String duration;
  final String participants;
  final String delivery;
  final List<String> modules;
  final String trainer;
  final String price;

  @override
  Widget build(BuildContext context) => InfoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Public programme · Fixed price'),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Text(description),
        const SizedBox(height: 16),
        _Meta(icon: Icons.people_outline, text: 'Target: $audience'),
        _Meta(icon: Icons.schedule_outlined, text: duration),
        _Meta(icon: Icons.groups_outlined, text: participants),
        _Meta(icon: Icons.location_on_outlined, text: delivery),
        _Meta(icon: Icons.person_outline, text: 'Trainer: $trainer'),
        const Divider(height: 30),
        const Text(
          'Learning objectives',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final objective in objectives)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('• $objective'),
          ),
        const SizedBox(height: 10),
        const Text('Modules', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (var index = 0; index < modules.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('Module ${index + 1}: ${modules[index]}'),
          ),
        const SizedBox(height: 12),
        Text(
          'Fixed price: $price',
          style: const TextStyle(fontWeight: FontWeight.w900, color: purple),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton(
              onPressed: () => go(context, '/contact'),
              child: const Text('Enquire'),
            ),
            OutlinedButton.icon(
              onPressed: () => downloadBrochure(context, [
                title,
                description,
                'Audience: $audience',
                'Duration: $duration',
                'Participants: $participants',
                'Delivery: $delivery',
                'Trainer: $trainer',
                'Learning objectives:',
                for (final o in objectives) '  - $o',
                'Modules:',
                for (final (i, m) in modules.indexed) '  Module ${i + 1}: $m',
                'Fixed price: $price',
              ]),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download brochure'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 18, color: purple),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class ImpactPage extends StatefulWidget {
  const ImpactPage({super.key});
  @override
  State<ImpactPage> createState() => _ImpactPageState();
}

class _ImpactPageState extends State<ImpactPage> {
  String filter = 'All';
  String query = '';
  final stories = const [
    (
      'Education',
      'Emotional Intelligence',
      'Emotional Intelligence Workshop',
      'assets/images/impact_school_talk.jpeg',
      '230 students',
      'Help students understand, identify and manage their emotions effectively.',
      'Emotional regulation awareness talk with practical emotion-management tools.',
      'Students gained emotional clarity, reduced impulsive reactions, improved concentration and built resilience for everyday challenges.',
      'Emotional Intelligence & Mindfulness',
    ),
    (
      'Youth',
      'Mindfulness',
      'Mindfulness & Creative Expression Workshop',
      'assets/images/impact_creative_art.jpeg',
      '15 children',
      'Nurture creativity, confidence and self-expression in a safe environment.',
      'Expressive art activities, role-playing and storytelling sessions.',
      'Children explored their imagination, shared ideas and expressed thoughts and emotions with greater confidence.',
      'Emotional Intelligence & Mindfulness',
    ),
    (
      'Education',
      'Emotional Intelligence',
      'Emotional Regulation Workshop',
      'assets/images/impact_classroom_workshop.jpeg',
      '40 students',
      'Equip students to recognize emotions and respond more constructively.',
      'Emotional regulation awareness talk and interactive activities.',
      'Students developed emotional clarity, concentration and resilience while reducing impulsive reactions.',
      'Emotional Intelligence & Mindfulness',
    ),
    (
      'Corporate',
      'Team Building',
      'Leadership & Team Building',
      'assets/images/home_hero_team_building.jpeg',
      '50 participants',
      'Develop problem-solving skills, creativity and effective collaboration.',
      'Leadership and team-building challenges with group reflection.',
      'Participants practised critical thinking, teamwork and approaching challenges with fresh perspectives.',
      'Team Building & Team Effectiveness',
    ),
    (
      'Education',
      'Leadership',
      'Leadership & Communication Workshop',
      'assets/images/impact_inti_workshop.jpeg',
      '10 future leaders',
      'Strengthen emotional intelligence, empathy, teamwork and authentic leadership.',
      'Communication training, discussion and experiential leadership activities.',
      'Participants better understood themselves and used empathy to support teamwork and authentic leadership.',
      'Leadership & Communication',
    ),
    (
      'Community',
      'Mindfulness',
      'Mindfulness & Expressive Art for Educators',
      'assets/images/impact_teachers_retreat.jpeg',
      '28 participants',
      'Support emotional release, self-awareness and inner clarity for educators.',
      'Mindfulness practices, reflection and expressive art activities.',
      'Educators felt calmer, lighter and more connected to themselves, helping them support students’ emotional well-being and creativity.',
      'Emotional Intelligence & Mindfulness',
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final shown = stories.where((s) {
      final matchesFilter = filter == 'All' || s.$1 == filter || s.$2 == filter;
      final text = '${s.$1} ${s.$2} ${s.$3} ${s.$8}'.toLowerCase();
      return matchesFilter && text.contains(query.toLowerCase());
    }).toList();
    return PageWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            'Impact through experience.',
            eyebrow: 'Impact stories',
            subtitle:
                'Selected moments from MT Alchemy learning and community programmes.',
          ),
          const InfoCard(
            color: Color(0xFFFFF0B9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1,100+ participants reached',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: deepBlue,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Across educational institutions, corporate teams, youth leadership programmes, NGOs and community groups, educators and social service organizations.',
                  style: TextStyle(fontSize: 16, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search impact stories',
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final name in [
                'All',
                'Corporate',
                'Education',
                'Youth',
                'NGO',
                'Community',
                'Leadership',
                'Mindfulness',
                'Emotional Intelligence',
                'Team Building',
              ])
                ChoiceChip(
                  label: Text(name),
                  selected: filter == name,
                  onSelected: (_) => setState(() => filter = name),
                ),
            ],
          ),
          const SizedBox(height: 30),
          ResponsiveGrid(
            children: [for (final s in shown) _ImpactStoryCard(story: s)],
          ),
        ],
      ),
    );
  }
}

class _ImpactStoryCard extends StatelessWidget {
  const _ImpactStoryCard({required this.story});
  final (String, String, String, String, String, String, String, String, String)
  story;
  @override
  Widget build(BuildContext context) => InfoCard(
    padding: 0,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: SiteImage(
            '${contentKey('story', story.$3)}.image',
            story.$4,
            height: 220,
            label: story.$3,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow('${story.$1} · ${story.$2}'),
              const SizedBox(height: 10),
              Text(story.$3, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              _StoryDetail(label: 'Participants', text: story.$5),
              _StoryDetail(label: 'Objective', text: story.$6),
              _StoryDetail(label: 'Activities', text: story.$7),
              _StoryDetail(label: 'Outcome', text: story.$8),
              _StoryDetail(label: 'Related service', text: story.$9),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StoryDetail extends StatelessWidget {
  const _StoryDetail({required this.label, required this.text});
  final String label;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(text: text),
        ],
      ),
    ),
  );
}

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});
  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  String query = '';
  String category = 'All';
  String contentType = 'All';
  final articles = const [
    (
      'Emotional Intelligence',
      'Article',
      'Pause before you respond',
      'A small pause creates room to notice emotion, choose intention and respond with clarity.',
    ),
    (
      'Leadership',
      'Video',
      'Lead with curiosity',
      'Thoughtful questions help leaders understand people before moving toward solutions.',
    ),
    (
      'Mindfulness',
      'Guide',
      'Make reflection a workplace habit',
      'Short moments of reflection can help teams learn from experience and reset attention.',
    ),
    (
      'Communication',
      'Article',
      'Listen to understand',
      'Active listening builds trust by helping people feel heard before decisions are made.',
    ),
    (
      'Workplace',
      'Resource',
      'Well-being is a shared practice',
      'Healthy culture grows through everyday habits, supportive systems and open conversations.',
    ),
    (
      'Personal Development',
      'Guide',
      'A practical self-awareness check-in',
      'Use a short reflection to notice what you feel, what you need and what action fits your values.',
    ),
    (
      'Organizational Development',
      'Resource',
      'Questions for a healthier culture',
      'A discussion resource for exploring trust, communication, well-being and shared responsibility.',
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final shown = articles.where((a) {
      final matchesSearch = '${a.$1} ${a.$2} ${a.$3} ${a.$4}'
          .toLowerCase()
          .contains(query.toLowerCase());
      return matchesSearch &&
          (category == 'All' || a.$1 == category) &&
          (contentType == 'All' || a.$2 == contentType);
    }).toList();
    return PageWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            'Ideas for human-centred growth.',
            eyebrow: 'Insights',
            subtitle:
                'Short reflections on emotional intelligence, leadership, mindfulness and workplace culture.',
          ),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search insights',
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items:
                [
                      'All',
                      'Emotional Intelligence',
                      'Leadership',
                      'Mindfulness',
                      'Communication',
                      'Workplace',
                      'Personal Development',
                      'Organizational Development',
                    ]
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => category = value ?? 'All'),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final type in [
                'All',
                'Article',
                'Video',
                'Guide',
                'Resource',
              ])
                ChoiceChip(
                  label: Text(type),
                  selected: contentType == type,
                  onSelected: (_) => setState(() => contentType = type),
                ),
            ],
          ),
          const SizedBox(height: 28),
          ResponsiveGrid(
            children: [
              for (final a in shown)
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow('${a.$1} · ${a.$2}'),
                      const SizedBox(height: 12),
                      Text(a.$3, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Text(a.$4),
                      const SizedBox(height: 18),
                      Text(
                        a.$2 == 'Video'
                            ? 'Watch preview'
                            : 'Open ${a.$2.toLowerCase()}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ModuleHandoffPage extends StatelessWidget {
  const ModuleHandoffPage({
    super.key,
    required this.title,
    required this.owner,
    required this.icon,
  });
  final String title;
  final String owner;
  final IconData icon;
  @override
  Widget build(BuildContext context) => PageWidth(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 90),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: InfoCard(
            child: Column(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0B9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 42, color: deepBlue),
                ),
                const SizedBox(height: 24),
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 14),
                Text(
                  owner,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: purple,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This navigation destination is included for the shared top-level website structure. Its full UI will connect here when the team modules are merged.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.6),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => go(context, '/'),
                  child: const Text('Return to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class ContactPage extends StatefulWidget {
  const ContactPage({super.key, this.initialEnquiryType});
  final String? initialEnquiryType;
  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _organization = TextEditingController();
  final _message = TextEditingController();
  late String? enquiryType = widget.initialEnquiryType;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _organization.dispose();
    _message.dispose();
    super.dispose();
  }

  String? requiredField(String? value) => value == null || value.trim().isEmpty
      ? 'Please complete this field'
      : null;
  String? emailField(String? value) {
    final required = requiredField(value);
    if (required != null) return required;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())
        ? null
        : 'Enter a valid email address';
  }

  @override
  Widget build(BuildContext context) => PageWidth(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          'Ready to build a stronger workplace?',
          eyebrow: 'Contact',
          subtitle:
              'Tell us what you want to strengthen and our team will get back to you.',
        ),
        LayoutBuilder(
          builder: (context, box) {
            final details = const InfoCard(
              color: deepBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow('Reach us', light: true),
                  SizedBox(height: 18),
                  Text(
                    'Start a meaningful conversation.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '+60 11-7239 9249\nmabeltan.alchemy@gmail.com',
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.8,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Leadership · Team effectiveness · Workplace well-being · Partnerships',
                    style: TextStyle(color: Colors.white70, height: 1.6),
                  ),
                ],
              ),
            );
            final form = InfoCard(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Send an enquiry',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: requiredField,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: emailField,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                      validator: requiredField,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _organization,
                      decoration: const InputDecoration(
                        labelText: 'Organization (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: enquiryType,
                      decoration: const InputDecoration(
                        labelText: 'Enquiry type',
                      ),
                      items:
                          [
                                'Individual Coaching',
                                'Corporate Training',
                                'Leadership Development',
                                'Team Development',
                                'Products',
                                'Partnership',
                                'Other',
                              ]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (value) => setState(() => enquiryType = value),
                      validator: requiredField,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _message,
                      decoration: const InputDecoration(labelText: 'Message'),
                      minLines: 4,
                      maxLines: 6,
                      validator: requiredField,
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final enquiry = CommercePrototypeStore.instance
                              .createContactEnquiry(
                                name: _name.text.trim(),
                                email: _email.text.trim(),
                                phone: _phone.text.trim(),
                                organization: _organization.text.trim(),
                                enquiryType: enquiryType!,
                                message: _message.text.trim(),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Enquiry ${enquiry.reference} saved to the local Admin inbox. No email was sent.',
                              ),
                            ),
                          );
                          formKey.currentState!.reset();
                          _name.clear();
                          _email.clear();
                          _phone.clear();
                          _organization.clear();
                          _message.clear();
                          setState(() => enquiryType = null);
                        }
                      },
                      child: const Text('Submit enquiry'),
                    ),
                  ],
                ),
              ),
            );
            return box.maxWidth >= 850
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 360, child: details),
                      const SizedBox(width: 24),
                      Expanded(child: form),
                    ],
                  )
                : Column(children: [details, const SizedBox(height: 24), form]);
          },
        ),
      ],
    ),
  );
}

class _Statement extends StatelessWidget {
  const _Statement({required this.title, required this.text});
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Text(text),
    ],
  );
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.title,
    required this.text,
    required this.button,
    required this.route,
  });
  final String title;
  final String text;
  final String button;
  final String route;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 56),
    padding: const EdgeInsets.all(34),
    decoration: BoxDecoration(
      color: deepBlue,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 30,
      runSpacing: 24,
      children: [
        SizedBox(
          width: 650,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                text,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: softYellow,
            foregroundColor: deepBlue,
          ),
          onPressed: () => go(context, route),
          child: Text(button),
        ),
      ],
    ),
  );
}

class SitemapPage extends StatelessWidget {
  const SitemapPage({super.key});
  @override
  Widget build(BuildContext context) => PageWidth(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          'Sitemap',
          subtitle: 'Explore MT Alchemy and sign in to access your workspace.',
        ),
        for (final entry in {...navItems, ...corporateNavItems}.entries)
          TextButton(
            onPressed: () => go(context, entry.value),
            child: Text(entry.key),
          ),
        const Text(
          'Learner, trainer, employer and administrator workspaces are available through the shared Login page.',
        ),
      ],
    ),
  );
}

/// Generates a programme brochure PDF and asks the browser to download it.
Future<void> downloadBrochure(BuildContext context, List<String> lines) async {
  final messenger = ScaffoldMessenger.of(context);
  final title = lines.first;
  final pdf = createReportPdf([
    'MT Alchemy - $title',
    'People first. Possibility always.',
    '',
    ...lines.skip(1),
    '',
    'Contact MT Alchemy through the website Contact page to book or tailor this programme.',
  ]);
  final name =
      'MT_Alchemy_${title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}_brochure.pdf';
  try {
    await saveLocalFile(name, pdf);
    messenger.showSnackBar(
      SnackBar(content: Text('Brochure downloaded: $name')),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('The brochure could not be downloaded.')),
    );
  }
}

/// Homepage for individual visitors (Group 8 feedback): self-paced courses,
/// one-to-one coaching and practical resources. Employers use /organizations.
class IndividualHomePage extends StatelessWidget {
  const IndividualHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = publishedCourses.take(3).toList();
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [deepBlue, royalBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: PageWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: LayoutBuilder(
                builder: (context, box) {
                  final text = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('For individuals', light: true),
                      const SizedBox(height: 18),
                      Text(
                        'Grow the skills that make you thrive at work and in life.',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontSize: box.maxWidth < 600 ? 34 : 44,
                            ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Self-paced courses in emotional intelligence, mindfulness and leadership, plus one-to-one coaching when you want a guide.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: softYellow,
                              foregroundColor: deepBlue,
                            ),
                            onPressed: () => go(context, '/hub'),
                            icon: const Icon(Icons.play_lesson_outlined),
                            label: const Text('Browse courses'),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                            ),
                            onPressed: () => go(context, '/coaching'),
                            icon: const Icon(Icons.forum_outlined),
                            label: const Text('Book a coaching session'),
                          ),
                        ],
                      ),
                    ],
                  );
                  final photo = ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: const SiteImage(
                      'photo.student-interaction.image',
                      'assets/images/impact_student_interaction.jpeg',
                      height: 380,
                      width: double.infinity,
                      label: 'Photo',
                    ),
                  );
                  return box.maxWidth >= 820
                      ? Row(
                          children: [
                            Expanded(child: text),
                            const SizedBox(width: 48),
                            Expanded(child: photo),
                          ],
                        )
                      : Column(
                          children: [text, const SizedBox(height: 32), photo],
                        );
                },
              ),
            ),
          ),
        ),
        PageWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                'Learn at your own pace.',
                eyebrow: 'Upskilling',
                subtitle:
                    'Short, practical courses with lessons, a quiz and a certificate when you pass.',
              ),
              ResponsiveGrid(
                children: [
                  for (final c in courses)
                    InfoCard(
                      padding: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                            child: CourseCover(
                              c,
                              height: 170,
                              width: double.infinity,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${c.level} · ${c.duration} · ${money(c.price)}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 14),
                                OutlinedButton(
                                  onPressed: () => go(
                                    context,
                                    '/course-detail',
                                    arguments: c.id,
                                  ),
                                  child: const Text('View course'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SectionTitle(
                'A focused space for clarity and growth.',
                eyebrow: 'Individual coaching',
                subtitle:
                    'One-to-one sessions with an EQ coach for career guidance, career transitions, relationships and personal development.',
              ),
              ResponsiveGrid(
                children: [
                  for (final (icon, title, text) in const [
                    (
                      Icons.explore_outlined,
                      'Career guidance',
                      'Clarify strengths, values and the next step that fits you.',
                    ),
                    (
                      Icons.swap_horiz,
                      'Career transitions',
                      'Navigate change with confidence and a clear plan.',
                    ),
                    (
                      Icons.favorite_outline,
                      'Relationships',
                      'Build empathy and communicate with care at work and at home.',
                    ),
                  ])
                    InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: purple, size: 32),
                          const SizedBox(height: 14),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(text),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () =>
                      go(context, '/contact', arguments: 'Individual Coaching'),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Book a coaching session'),
                ),
              ),
              const SectionTitle(
                'Tools for everyday practice.',
                eyebrow: 'Store',
                subtitle:
                    'Workbooks, journals and digital resources that keep learning going.',
              ),
              ResponsiveGrid(
                children: [
                  for (final p
                      in CommercePrototypeStore.instance.publishedProducts.take(
                        3,
                      ))
                    InfoCard(
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFEAFE),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(p.icon, color: purple),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: deepBlue,
                                  ),
                                ),
                                Text(
                                  '${p.digital ? 'Digital' : 'Physical'} · ${money(p.price)}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'View ${p.name}',
                            onPressed: () =>
                                go(context, '/product', arguments: p.id),
                            icon: const Icon(Icons.arrow_forward),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SectionTitle(
                'What participants say.',
                eyebrow: 'Testimonials',
              ),
              const ResponsiveGrid(
                children: [
                  _TestimonialCard(
                    quote:
                        'All were good as it is a reminder to connect with myself.',
                    detail: 'Participant feedback · Mindfulness programme',
                  ),
                  _TestimonialCard(
                    quote:
                        'I learned the importance of empathic communication.',
                    detail: 'Participant takeaway · Leadership learning',
                  ),
                  _TestimonialCard(
                    quote:
                        'The trainer was very well-prepared and explained the content clearly with real-life examples.',
                    detail: 'Participant feedback · Training session',
                  ),
                ],
              ),
              const SizedBox(height: 40),
              InfoCard(
                color: const Color(0xFFFFF4CC),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 14,
                  spacing: 20,
                  children: [
                    Text(
                      'Start learning today.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    FilledButton(
                      onPressed: () => go(context, '/register'),
                      child: const Text('Create a free account'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ],
    );
  }
}

/// The four programme formats as flip cards.
class _ProgrammeFormats extends StatelessWidget {
  const _ProgrammeFormats();

  @override
  Widget build(BuildContext context) => const ResponsiveGrid(
    maxColumns: 4,
    minWidth: 220,
    children: [
      FlipCard(
        icon: Icons.groups_2_outlined,
        title: 'Workshops',
        caption: 'Half-day or full-day, in person or online',
        details:
            'Hands-on group sessions for up to 30 people, with activities, reflection and a take-home workbook.',
      ),
      FlipCard(
        icon: Icons.record_voice_over_outlined,
        title: 'Coaching',
        caption: 'One to one with a certified coach',
        details:
            'Six sessions planned around your goals, with a check-in after each one and a short progress report.',
      ),
      FlipCard(
        icon: Icons.play_lesson_outlined,
        title: 'Online courses',
        caption: 'Self-paced, with a certificate',
        details:
            'Short video lessons, quizzes and resources you can finish at your own pace, then download a certificate.',
      ),
      FlipCard(
        icon: Icons.tune_rounded,
        title: 'Custom programmes',
        caption: 'Built for your organisation',
        details:
            'We assess your team first, then combine workshops, coaching and courses into a plan that fits your goals.',
      ),
    ],
  );
}
