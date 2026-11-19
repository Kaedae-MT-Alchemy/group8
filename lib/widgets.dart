import 'package:flutter/material.dart';
import 'shared/notifications.dart';

import 'commerce/commerce_prototype_store.dart';
import 'shared/auth_prototype_store.dart';
import 'shared/profile_page.dart';
import 'cms/editable.dart';
import 'cms/site_content.dart';
import 'shared/effects.dart';
import 'shared/text_size.dart';
import 'shared/motion.dart';
import 'shared/ui_kit.dart';
import 'theme.dart';

const navItems = <String, String>{
  'Home': '/',
  'About': '/about',
  'Services': '/services',
  'Courses': '/upskilling',
  'Store': '/store',
  'Insights': '/insights',
  'Contact': '/contact',
  'Login': '/login',
  'Register': '/register',
  'Cart': '/cart',
  'Sitemap': '/sitemap',
};

const corporateNavItems = <String, String>{
  'Individual Coaching': '/coaching',
  'Organizations': '/organizations',
  'Corporate Programmes': '/programmes',
  'Impact Stories': '/impact',
};

void go(BuildContext context, String route, {Object? arguments}) {
  if (ModalRoute.of(context)?.settings.name != route) {
    Navigator.pushNamed(context, route, arguments: arguments);
  }
}

/// Top-level navigation (header, drawer, account menu): opens the page on
/// top of the first page instead of stacking every visited page, so Back
/// always leads somewhere sensible.
void navTo(BuildContext context, String route, {Object? arguments}) {
  if (ModalRoute.of(context)?.settings.name == route) return;
  final nav = Navigator.of(context);
  if (route == '/') {
    nav.pushNamedAndRemoveUntil('/', (r) => false);
  } else {
    nav.pushNamedAndRemoveUntil(route, (r) => r.isFirst, arguments: arguments);
  }
}

/// Where Back goes when there is no previous page (e.g. after a refresh).
String parentRouteOf(String route) {
  final role = AuthPrototypeStore.instance.role;
  if (route.startsWith('/admin/')) return '/admin';
  return switch (route) {
    '/employees' ||
    '/assign-course' ||
    '/reports' ||
    '/purchase-courses' ||
    '/quote-requests' => role == 'Employer' ? '/employer' : '/',
    '/quote-request' ||
    '/quote-confirmation' => role == 'Employer' ? '/employer' : '/',
    '/order-details' || '/order-confirmation' => '/orders',
    '/orders' || '/digital-library' || '/profile' => switch (role) {
      'Admin' => '/admin',
      'Employer' => '/employer',
      'Trainer' => '/trainer-dashboard',
      'Learner' => '/dashboard',
      _ => '/',
    },
    '/checkout' => '/cart',
    '/product' || '/cart' => '/store',
    '/course-detail' || '/enroll' => '/hub',
    '/course-player' ||
    '/quiz' ||
    '/certificate' => role == 'Trainer' ? '/trainer-dashboard' : '/dashboard',
    '/coaching' => '/individual',
    '/programmes' => '/organizations',
    _ => '/',
  };
}

/// Back arrow that pops, or goes to the page's parent when nothing to pop.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.fallback});
  final String? fallback;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Back',
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        final route = ModalRoute.of(context)?.settings.name ?? '/';
        nav.pushReplacementNamed(fallback ?? parentRouteOf(route));
      }
    },
  );
}

class SiteShell extends StatelessWidget {
  const SiteShell({super.key, required this.route, required this.child});
  final String route;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AuthPrototypeStore.instance,
    builder: (context, _) => _buildShell(context),
  );

  Widget _buildShell(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 1180;
    final compactHeader = MediaQuery.sizeOf(context).width < 440;
    final signedIn = AuthPrototypeStore.instance.isSignedIn;
    final role = AuthPrototypeStore.instance.role;
    final canViewCorporateWebsite =
        signedIn && const {'Employer', 'Admin'}.contains(role);
    final visibleCorporateNavItems = canViewCorporateWebsite
        ? corporateNavItems
        : <String, String>{
            'Individual Coaching': '/coaching',
            'Organizations': '/organizations',
            'Public Programmes': '/programmes',
            'Impact Stories': '/impact',
          };
    final workspaceRoute = switch (role) {
      'Admin' => '/admin',
      'Employer' => '/employer',
      'Learner' => '/dashboard',
      'Trainer' => '/trainer-dashboard',
      _ => null,
    };
    final workspaceLabel = switch (role) {
      'Admin' => 'Admin portal',
      'Employer' => 'Employer portal',
      'Learner' => 'Learner dashboard',
      'Trainer' => 'Trainer dashboard',
      _ => null,
    };
    void signOut() {
      AuthPrototypeStore.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }

    void goBackOrWorkspace() {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, parentRouteOf(route));
      }
    }

    final showBack = route != '/';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: desktop
            ? (showBack
                  ? IconButton(
                      tooltip: 'Go back',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: goBackOrWorkspace,
                    )
                  : null)
            : Builder(
                builder: (context) => Row(
                  children: [
                    if (showBack)
                      IconButton(
                        tooltip: 'Go back',
                        icon: const Icon(Icons.arrow_back),
                        onPressed: goBackOrWorkspace,
                      ),
                    IconButton(
                      tooltip: 'Open navigation',
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ],
                ),
              ),
        leadingWidth: desktop ? null : (showBack ? 104 : 56),
        toolbarHeight: 76,
        titleSpacing: desktop ? 36 : 16,
        title: InkWell(
          onTap: () => navTo(context, '/'),
          borderRadius: BorderRadius.circular(8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const SiteImage(
                    'site.logo',
                    'assets/images/logo_mt_alchemy.jpeg',
                    width: 48,
                    height: 48,
                    label: 'Logo',
                  ),
                ),
                const SizedBox(width: 12),
                KeyedSubtree(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MT Alchemy',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: Tok.serif,
                          fontSize: compactHeader ? 20 : 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          height: 1.1,
                          color: Tok.brandDeep,
                        ),
                      ),
                      if (!compactHeader)
                        const Text(
                          'Made to Thrive',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: Tok.serif,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            height: 1.2,
                            color: Tok.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: desktop
            ? [
                for (final item in const {
                  'About': '/about',
                  'Services': '/services',
                }.entries)
                  _NavLink(item.key, item.value, active: route == item.value),
                PopupMenuButton<String>(
                  tooltip: 'Programme pages',
                  onSelected: (value) => navTo(context, value),
                  position: PopupMenuPosition.under,
                  itemBuilder: (_) => [
                    for (final item in visibleCorporateNavItems.entries)
                      PopupMenuItem(value: item.value, child: Text(item.key)),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Text(
                          'Programmes',
                          style: TextStyle(
                            fontFamily: Tok.display,
                            fontSize: 15,
                            color: deepBlue,
                            fontWeight:
                                visibleCorporateNavItems.containsValue(route)
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        const Icon(
                          Icons.expand_more,
                          size: 18,
                          color: deepBlue,
                        ),
                      ],
                    ),
                  ),
                ),
                for (final item in const {
                  'Courses': '/upskilling',
                  'Store': '/store',
                  'Insights': '/insights',
                  'Contact': '/contact',
                }.entries)
                  _NavLink(item.key, item.value, active: route == item.value),
                const SizedBox(width: 8),
                const TextSizeButton(),
                IconButton(
                  tooltip: 'Cart',
                  onPressed: () => navTo(context, '/cart'),
                  icon: AnimatedBuilder(
                    animation: CommercePrototypeStore.instance,
                    builder: (context, _) => Badge(
                      isLabelVisible:
                          CommercePrototypeStore.instance.cartCount > 0,
                      label: Text(
                        '${CommercePrototypeStore.instance.cartCount}',
                      ),
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!signedIn) ...[
                  TextButton(
                    onPressed: () => navTo(context, '/login'),
                    child: const Text('Sign in'),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () => navTo(context, '/register'),
                    child: const Text('Get started'),
                  ),
                ] else ...[
                  const NotificationBell(),
                  const SizedBox(width: 6),
                ],
                if (signedIn)
                  _AccountMenu(
                    workspaceRoute: workspaceRoute,
                    workspaceLabel: workspaceLabel,
                    onSignOut: signOut,
                  ),
                const SizedBox(width: 28),
              ]
            : [
                const TextSizeButton(),
                if (signedIn) const NotificationBell(),
                const SizedBox(width: 8),
              ],
      ),
      drawer: desktop
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MT Alchemy',
                            style: TextStyle(
                              fontFamily: Tok.serif,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: Tok.brandDeep,
                            ),
                          ),
                          Text(
                            'Made to Thrive',
                            style: TextStyle(
                              fontFamily: Tok.serif,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Tok.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (signedIn)
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('My profile'),
                        onTap: () {
                          Navigator.pop(context);
                          navTo(context, '/profile');
                        },
                      ),
                    if (role == 'Admin') ...[
                      for (final item in {
                        'Overview': '/admin',
                        'Users': '/admin/users',
                        'Organizations': '/admin/organizations',
                        'Courses': '/admin/courses',
                        'Products': '/admin/products',
                        'Orders': '/admin/orders',
                        'Website content': '/admin/content',
                      }.entries)
                        ListTile(
                          leading: const Icon(Icons.dashboard_outlined),
                          title: Text(item.key),
                          onTap: () {
                            Navigator.pop(context);
                            navTo(context, item.value);
                          },
                        ),
                    ],
                    for (final item in navItems.entries.where(
                      (item) =>
                          !signedIn ||
                          !const {'Login', 'Register'}.contains(item.key),
                    ))
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          title: Text(item.key),
                          selected: route == item.value,
                          selectedColor: deepBlue,
                          selectedTileColor: Tok.brandTint,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            navTo(context, item.value);
                          },
                        ),
                      ),
                    for (final p in SiteContentStore.instance.menuPages)
                      ListTile(
                        title: Text(p.title),
                        selected: route == p.route,
                        selectedColor: deepBlue,
                        onTap: () {
                          Navigator.pop(context);
                          navTo(context, p.route);
                        },
                      ),
                    if (workspaceRoute != null && workspaceLabel != null)
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          leading: Icon(
                            role == 'Admin'
                                ? Icons.admin_panel_settings_outlined
                                : Icons.business_outlined,
                          ),
                          title: Text(workspaceLabel),
                          selected: route == workspaceRoute,
                          selectedColor: deepBlue,
                          selectedTileColor: Tok.brandTint,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            navTo(context, workspaceRoute);
                          },
                        ),
                      ),
                    if (signedIn)
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Sign out'),
                          onTap: () {
                            Navigator.pop(context);
                            signOut();
                          },
                        ),
                      ),
                    if (visibleCorporateNavItems.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'PROGRAMMES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: purple,
                          ),
                        ),
                      ),
                      for (final item in visibleCorporateNavItems.entries)
                        Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            title: Text(item.key),
                            selected: route == item.value,
                            selectedColor: deepBlue,
                            selectedTileColor: Tok.brandTint,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              navTo(context, item.value);
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ScrollProgress(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListenableBuilder(
                      listenable: CommercePrototypeStore.instance,
                      builder: (context, _) {
                        final error =
                            CommercePrototypeStore.instance.storageError;
                        return error == null
                            ? const SizedBox.shrink()
                            : MaterialBanner(
                                backgroundColor: const Color(0xFFFFF4E5),
                                leading: const Icon(
                                  Icons.cloud_off_outlined,
                                  color: Color(0xFF9A5B00),
                                ),
                                content: Text(error),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      CommercePrototypeStore
                                              .instance
                                              .storageError =
                                          null;
                                      CommercePrototypeStore.instance.refresh();
                                    },
                                    child: const Text('Dismiss'),
                                  ),
                                ],
                              );
                      },
                    ),
                    if (pageBanners[route] case final b?)
                      ImageBanner(
                        image: b.$1,
                        eyebrow: b.$2,
                        title: b.$3,
                        height: 240,
                      ),
                    child,
                    const SiteFooter(),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(left: 20, bottom: 20, child: EditModeToggle()),
        ],
      ),
    );
  }
}

class PageWidth extends StatelessWidget {
  const PageWidth({super.key, required this.child, this.padding = true});
  final Widget child;
  final bool padding;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1240),
      child: Padding(
        padding: padding
            ? EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width < 600 ? 20 : 40,
              )
            : EdgeInsets.zero,
        child: child,
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title, {
    super.key,
    this.eyebrow,
    this.subtitle,
    this.center = false,
  });
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    // Content keys come from the original title, so the super admin's edits
    // stay attached to this section.
    final key = contentKey('section', title);
    return Padding(
      padding: EdgeInsets.only(top: narrow ? Tok.s8 : 88, bottom: Tok.s6),
      child: Reveal(
        child: Column(
          crossAxisAlignment: center
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            if (eyebrow != null)
              CmsValue(
                '$key.eyebrow',
                eyebrow!,
                label: 'section label',
                builder: (context, v) => Eyebrow(v),
              ),
            if (eyebrow != null) const SizedBox(height: Tok.s3),
            CmsText(
              '$key.title',
              title,
              label: 'section heading',
              accent: Tok.brand,
              textAlign: center ? TextAlign.center : null,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge!.copyWith(fontSize: narrow ? 30 : 40),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: Tok.s3),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: CmsText(
                  '$key.subtitle',
                  subtitle!,
                  label: 'section intro',
                  multiline: true,
                  textAlign: center ? TextAlign.center : null,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.light = false});
  final String text;
  final bool light;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 24,
        height: 2,
        decoration: BoxDecoration(
          color: Tok.accent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: light ? Tok.accent : Tok.calmText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
      ),
    ],
  );
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = 26,
  });
  final Widget child;
  final Color color;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(Tok.rLg),
      border: Border.all(color: Tok.border),
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minWidth = 280,
    this.maxColumns = 3,
  });
  final List<Widget> children;
  final double minWidth;
  final int maxColumns;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth >= 1000
          ? maxColumns
          : box.maxWidth >= 620
          ? 2
          : 1;
      final width = (box.maxWidth - (columns - 1) * Tok.s5) / columns;
      return Wrap(
        spacing: Tok.s5,
        runSpacing: Tok.s5,
        children: [
          for (final (i, child) in children.indexed)
            SizedBox(
              width: width < minWidth ? box.maxWidth : width,
              child: Reveal(
                delay: Duration(milliseconds: 70 * (i % columns)),
                child: child,
              ),
            ),
        ],
      );
    },
  );
}

class PhotoCard extends StatelessWidget {
  const PhotoCard({
    super.key,
    required this.path,
    required this.title,
    required this.subtitle,
    this.height = 260,
  });
  final String path;
  final String title;
  final String subtitle;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: CmsImage(
      '${contentKey('photo', title)}.image',
      path,
      label: title,
      builder: (context, provider) => Container(
        height: height,
        decoration: BoxDecoration(
          image: DecorationImage(image: provider, fit: BoxFit.cover),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.bottomLeft,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xD900001F)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  static const _explore = {
    'About': '/about',
    'Services': '/services',
    'Programmes': '/programmes',
    'Courses': '/upskilling',
    'Store': '/store',
  };
  static const _more = {
    'Impact stories': '/impact',
    'Insights': '/insights',
    'Individual coaching': '/coaching',
    'Verify a certificate': '/verify',
    'Sitemap': '/sitemap',
  };

  @override
  Widget build(BuildContext context) {
    Widget heading(String t) => Padding(
      padding: const EdgeInsets.only(bottom: Tok.s3),
      child: Text(
        t,
        style: const TextStyle(
          color: Tok.accent,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          fontSize: 13,
        ),
      ),
    );
    Widget links(Map<String, String> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in items.entries)
          TextButton(
            onPressed: () => navTo(context, e.value),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.centerLeft,
              textStyle: const TextStyle(
                fontFamily: Tok.body,
                fontSize: 15.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            child: Text(e.key),
          ),
      ],
    );
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: Tok.s8),
      color: Tok.brandDeep,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 0),
      child: PageWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 48,
              runSpacing: 32,
              children: [
                const SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MT Alchemy',
                        style: TextStyle(
                          fontFamily: Tok.serif,
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Made to Thrive',
                        style: TextStyle(
                          fontFamily: Tok.serif,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: Tok.accent,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: Tok.s3),
                      Text(
                        'Building emotionally intelligent leaders and resilient workplace cultures.',
                        style: TextStyle(
                          color: Colors.white,
                          height: 1.6,
                          fontSize: 15.5,
                        ),
                      ),
                      SizedBox(height: Tok.s5),
                      Text(
                        '+60 11-7239 9249\nmabeltan.alchemy@gmail.com',
                        style: TextStyle(color: Colors.white, height: 1.8),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [heading('EXPLORE'), links(_explore)],
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heading('MORE'),
                      ListenableBuilder(
                        listenable: SiteContentStore.instance,
                        builder: (context, _) => links({
                          ..._more,
                          for (final p in SiteContentStore.instance.menuPages)
                            p.title: p.route,
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Tok.s6),
            Container(height: 1, color: Colors.white24),
            const SizedBox(height: Tok.s4),
            const Text(
              '© 2026 MT Alchemy · NET4207 · Flutter + Firebase',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink(this.label, this.route, {required this.active});
  final String label;
  final String route;
  final bool active;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: TextButton(
        onPressed: () => navTo(context, widget.route),
        style: TextButton.styleFrom(
          foregroundColor: deepBlue,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 14),
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: Tok.display,
                  fontSize: 15,
                  fontWeight: widget.active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              // Gold underline slides in from the left on hover and stays
              // under the current page.
              TweenAnimationBuilder<double>(
                tween: Tween(end: widget.active || _hover ? 1 : 0),
                duration: Motion.enabled(context) ? Tok.slow : Duration.zero,
                curve: Tok.easeOut,
                builder: (context, t, _) => Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.diagonal3Values(t, 1, 1),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Tok.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({
    required this.workspaceRoute,
    required this.workspaceLabel,
    required this.onSignOut,
  });
  final String? workspaceRoute;
  final String? workspaceLabel;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AuthPrototypeStore.instance,
    builder: (context, _) => _menu(context),
  );

  Widget _menu(BuildContext context) {
    final auth = AuthPrototypeStore.instance;
    final name = auth.displayName ?? auth.email ?? '';
    PopupMenuItem<String> item(String value, IconData icon, String label) =>
        PopupMenuItem(
          value: value,
          child: Row(
            children: [
              Icon(icon, size: 20, color: deepBlue),
              const SizedBox(width: 12),
              Text(label),
            ],
          ),
        );
    return PopupMenuButton<String>(
      tooltip: 'Account',
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 'signout') {
          onSignOut();
        } else {
          navTo(context, value);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: deepBlue,
                ),
              ),
              Text(
                '${auth.role} · ${auth.email}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        if (workspaceRoute != null)
          item(
            workspaceRoute!,
            Icons.space_dashboard_outlined,
            workspaceLabel ?? 'Dashboard',
          ),
        item('/profile', Icons.person_outline, 'My profile'),
        if (auth.role == 'Learner' || auth.role == 'Employer')
          item('/orders', Icons.receipt_long_outlined, 'My orders'),
        const PopupMenuDivider(),
        item('signout', Icons.logout, 'Sign out'),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE8DFFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileAvatar(
              bytes: ProfileAvatar.fromProfile(auth.profile),
              name: name,
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                workspaceLabel ?? 'Account',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: deepBlue,
                ),
              ),
            ),
            const Icon(Icons.expand_more, size: 18, color: deepBlue),
          ],
        ),
      ),
    );
  }
}

/// Photo banner shown at the top of each public page.
const pageBanners = <String, (String, String, String)>{
  '/about': (
    'assets/images/workshop_eq_facilitator.jpeg',
    'About MT Alchemy',
    'People first. Possibility always.',
  ),
  '/services': (
    'assets/images/workshop_group_discussion.jpeg',
    'Services',
    'Practical programmes for people, teams and organizations.',
  ),
  '/coaching': (
    'assets/images/stock/coaching_conversation.jpg',
    'Individual coaching',
    'One-to-one support for clarity, confidence and growth.',
  ),
  '/organizations': (
    'assets/images/stock/team_discussion.jpg',
    'For organizations',
    'Programmes that help teams grow together.',
  ),
  '/programmes': (
    'assets/images/stock/facilitator.jpg',
    'Programmes',
    'Public and corporate programmes led by experienced facilitators.',
  ),
  '/impact': (
    'assets/images/impact_school_talk.jpeg',
    'Impact stories',
    'Real people. Meaningful experiences.',
  ),
  '/insights': (
    'assets/images/stock/reflection.jpg',
    'Insights',
    'Articles, guides and resources for everyday growth.',
  ),
  '/contact': (
    'assets/images/stock/handshake.jpg',
    'Contact',
    'We’d love to hear from you.',
  ),
  '/sitemap': (
    'assets/images/stock/planning.jpg',
    'Sitemap',
    'Every page of the MT Alchemy platform.',
  ),
};
