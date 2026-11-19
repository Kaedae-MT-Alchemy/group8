import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../backend/backend.dart';
import '../shared/auth_prototype_store.dart';

/// Website content the super admin can change without a code release:
/// text overrides, image overrides, hidden sections and extra pages.
///
/// Firestore layout (rules: anyone reads, only Admin writes):
/// - `siteContent/texts`    `{values: {key: text}}`
/// - `siteContent/settings` `{hidden: [sectionKey, ...]}`
/// - `siteImages/{key}`     `{key, src}` where src is an asset path, an
///   https link, or a compressed `data:image/jpeg;base64,...` upload
/// - `sitePages/{slug}`     one document per extra page ([SitePage])
class SiteContentStore extends ChangeNotifier {
  SiteContentStore._();
  static final instance = SiteContentStore._();

  final Map<String, String> _texts = {};
  final Map<String, String> _images = {};
  final Set<String> _hidden = {};
  final List<SitePage> _pages = [];
  final List<StreamSubscription<Object?>> _subs = [];
  bool _editing = false;
  String? lastError;

  /// True while the admin has inline editing switched on.
  bool get editing => _editing && canEdit;
  bool get canEdit => AuthPrototypeStore.instance.hasRole('Admin');

  set editing(bool value) {
    _editing = value;
    notifyListeners();
  }

  Map<String, String> get texts => Map.unmodifiable(_texts);
  Map<String, String> get images => Map.unmodifiable(_images);
  Set<String> get hidden => Set.unmodifiable(_hidden);

  /// Published extra pages, in menu order. Admins also see drafts.
  List<SitePage> get pages =>
      _pages.where((p) => p.published || canEdit).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  List<SitePage> get menuPages =>
      pages.where((p) => p.published && p.showInMenu).toList();

  SitePage? pageBySlug(String slug) =>
      _pages.where((p) => p.slug == slug).firstOrNull;

  String text(String key, String fallback) {
    final v = _texts[key];
    return v == null || v.trim().isEmpty ? fallback : v;
  }

  String image(String key, String fallback) => _images[key] ?? fallback;
  bool isHidden(String key) => _hidden.contains(key);

  /// Starts listening to Firestore. Safe to call more than once.
  void start() {
    if (!Backend.isReady || _subs.isNotEmpty) return;
    final db = Backend.db;
    void fail(Object e) {
      lastError = '$e';
      notifyListeners();
    }

    _subs
      ..add(
        db.collection('siteContent').doc('texts').snapshots().listen((s) {
          _texts
            ..clear()
            ..addAll(
              ((s.data()?['values'] as Map?) ?? const {}).map(
                (k, v) => MapEntry('$k', '$v'),
              ),
            );
          notifyListeners();
        }, onError: fail),
      )
      ..add(
        db.collection('siteContent').doc('settings').snapshots().listen((s) {
          _hidden
            ..clear()
            ..addAll(
              ((s.data()?['hidden'] as List?) ?? const []).map((e) => '$e'),
            );
          notifyListeners();
        }, onError: fail),
      )
      ..add(
        db.collection('siteImages').snapshots().listen((s) {
          _images
            ..clear()
            ..addAll({
              for (final d in s.docs)
                '${d.data()['key'] ?? d.id}': '${d.data()['src'] ?? ''}',
            });
          notifyListeners();
        }, onError: fail),
      )
      ..add(
        db.collection('sitePages').snapshots().listen((s) {
          _pages
            ..clear()
            ..addAll(s.docs.map((d) => SitePage.fromMap(d.data())));
          notifyListeners();
        }, onError: fail),
      );
  }

  @visibleForTesting
  void reset() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _texts.clear();
    _images.clear();
    _hidden.clear();
    _pages.clear();
    _editing = false;
    lastError = null;
  }

  // ---- Writes (Admin only; Firestore rules enforce this too) ----

  Future<void> setText(String key, String? value) async {
    if (value == null || value.trim().isEmpty) {
      _texts.remove(key);
    } else {
      _texts[key] = value.trim();
    }
    notifyListeners();
    await Backend.db.collection('siteContent').doc('texts').set({
      'values': Map.of(_texts),
    });
  }

  Future<void> setImage(String key, String? src) async {
    final ref = Backend.db
        .collection('siteImages')
        .doc(key.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_'));
    if (src == null || src.isEmpty) {
      _images.remove(key);
      notifyListeners();
      await ref.delete();
    } else {
      _images[key] = src;
      notifyListeners();
      await ref.set({'key': key, 'src': src});
    }
  }

  Future<void> setHidden(String key, bool hide) async {
    hide ? _hidden.add(key) : _hidden.remove(key);
    notifyListeners();
    await Backend.db.collection('siteContent').doc('settings').set({
      'hidden': _hidden.toList()..sort(),
    });
  }

  Future<void> savePage(SitePage page) async {
    _pages
      ..removeWhere((p) => p.slug == page.slug)
      ..add(page);
    notifyListeners();
    await Backend.db.collection('sitePages').doc(page.slug).set(page.toMap());
  }

  Future<void> deletePage(String slug) async {
    _pages.removeWhere((p) => p.slug == slug);
    notifyListeners();
    await Backend.db.collection('sitePages').doc(slug).delete();
  }

  /// Clears every text and image change and shows all sections again.
  /// Extra pages are kept.
  Future<void> resetAllEdits() async {
    final db = Backend.db;
    final keys = _images.keys.toList();
    _texts.clear();
    _images.clear();
    _hidden.clear();
    notifyListeners();
    await db.collection('siteContent').doc('texts').set({'values': {}});
    await db.collection('siteContent').doc('settings').set({'hidden': []});
    for (final k in keys) {
      await db
          .collection('siteImages')
          .doc(k.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_'))
          .delete();
    }
  }
}

/// An extra page the admin created.
class SitePage {
  const SitePage({
    required this.slug,
    required this.title,
    this.eyebrow = '',
    this.body = '',
    this.image = 'assets/images/stock/planning.jpg',
    this.buttonLabel = '',
    this.buttonLink = '',
    this.showInMenu = true,
    this.published = true,
    this.order = 0,
  });

  final String slug;
  final String title;
  final String eyebrow;
  final String body;
  final String image;
  final String buttonLabel;
  final String buttonLink;
  final bool showInMenu;
  final bool published;
  final int order;

  String get route => '/p/$slug';

  factory SitePage.fromMap(Map<String, dynamic> m) => SitePage(
    slug: '${m['slug'] ?? ''}',
    title: '${m['title'] ?? 'Untitled page'}',
    eyebrow: '${m['eyebrow'] ?? ''}',
    body: '${m['body'] ?? ''}',
    image: '${m['image'] ?? 'assets/images/stock/planning.jpg'}',
    buttonLabel: '${m['buttonLabel'] ?? ''}',
    buttonLink: '${m['buttonLink'] ?? ''}',
    showInMenu: m['showInMenu'] != false,
    published: m['published'] != false,
    order: (m['order'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'slug': slug,
    'title': title,
    'eyebrow': eyebrow,
    'body': body,
    'image': image,
    'buttonLabel': buttonLabel,
    'buttonLink': buttonLink,
    'showInMenu': showInMenu,
    'published': published,
    'order': order,
  };

  /// "Corporate Wellness Week!" → "corporate-wellness-week".
  static String slugify(String title) {
    final s = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return s.isEmpty ? 'page' : (s.length > 60 ? s.substring(0, 60) : s);
  }
}

/// Image from an asset path, an https link or an uploaded data URI.
ImageProvider siteImageProvider(String src) {
  if (src.startsWith('data:')) {
    final comma = src.indexOf(',');
    return MemoryImage(base64Decode(src.substring(comma + 1)));
  }
  if (src.startsWith('http://') || src.startsWith('https://')) {
    return NetworkImage(src);
  }
  return AssetImage(src);
}

/// Stable content key from a default text: "Learn at your own pace." →
/// "learn-at-your-own-pace".
String contentKey(String prefix, String text) {
  final slug = SitePage.slugify(text);
  return '$prefix.${slug.length > 48 ? slug.substring(0, 48) : slug}';
}
