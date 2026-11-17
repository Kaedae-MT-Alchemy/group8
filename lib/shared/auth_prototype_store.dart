import 'dart:async';

import 'package:flutter/foundation.dart';

import '../backend/backend.dart';
import '../commerce/commerce_prototype_store.dart';
import '../data/progress_store.dart';

/// Signed-in account and role.
///
/// Identity comes from Firebase Authentication. The role and profile live in
/// Firestore at `users/{uid}`; security rules stop users from granting
/// themselves the Admin or Trainer role.
class AuthPrototypeStore extends ChangeNotifier {
  AuthPrototypeStore._();
  static final AuthPrototypeStore instance = AuthPrototypeStore._();

  static const selfServiceRoles = {'Learner', 'Employer'};
  static const allRoles = {'Learner', 'Employer', 'Trainer', 'Admin'};

  String? _uid;
  String? _email;
  String? _role;
  String? _displayName;
  Map<String, dynamic> _profile = const {};
  String? lastError;

  String? get uid => _uid;
  String? get email => _email;
  String? get role => _role;
  String? get displayName => _displayName;
  Map<String, dynamic> get profile => Map.unmodifiable(_profile);
  bool get isSignedIn => _email != null;
  bool hasRole(String role) => _role == role;

  /// Restores a session persisted by Firebase (for example after reload).
  Future<void> restoreSession() async {
    final user = Backend.auth.currentUser;
    if (user == null) {
      await CommercePrototypeStore.instance.attach();
      return;
    }
    if (!await _openSession(user)) {
      await Backend.auth.signOut();
      await CommercePrototypeStore.instance.attach();
    }
  }

  /// Returns the account role, or null with [lastError] set.
  Future<String?> signIn(String email, String password) async {
    lastError = null;
    try {
      final user = await Backend.auth.signIn(email, password);
      if (!await _openSession(user)) {
        await Backend.auth.signOut();
        lastError ??= 'This account has no MT Alchemy profile yet.';
        return null;
      }
      return _role;
    } on AuthFailure catch (e) {
      lastError = e.message;
      return null;
    }
  }

  /// Creates a Learner or Employer account. Returns null on success or a
  /// message to show.
  Future<String?> registerAccount({
    required String email,
    required String password,
    required String role,
    required String displayName,
    Map<String, String> details = const {},
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!selfServiceRoles.contains(role)) {
      return 'Only Learner and Employer accounts can be registered.';
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalizedEmail)) {
      return 'Enter a valid email address.';
    }
    if (password.length < 8) return 'Use at least 8 characters.';
    try {
      final user = await Backend.auth.register(normalizedEmail, password);
      await Backend.db.collection('users').doc(user.uid).set({
        'email': normalizedEmail,
        'role': role,
        'displayName': displayName.trim(),
        ...{
          for (final e in details.entries)
            if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
        },
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (!await _openSession(user)) {
        return lastError ?? 'Your account was created but could not be opened.';
      }
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    } catch (_) {
      return 'Your account could not be created. Check your connection.';
    }
  }

  Future<String?> changePassword(String current, String next) async {
    try {
      await Backend.auth.changePassword(current, next);
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await Backend.auth.sendPasswordReset(email);
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    }
  }

  Future<bool> _openSession(AuthUser user) async {
    try {
      final doc = await Backend.db.collection('users').doc(user.uid).get();
      final data = doc.data();
      final role = data?['role'] as String?;
      if (data == null || !allRoles.contains(role)) {
        lastError = 'This account has no MT Alchemy profile yet.';
        return false;
      }
      if (data['status'] == 'Suspended') {
        lastError = 'This account is suspended. Contact MT Alchemy for help.';
        return false;
      }
      _uid = user.uid;
      _email = user.email.toLowerCase();
      _role = role;
      _displayName = (data['displayName'] as String?)?.trim().isNotEmpty == true
          ? data['displayName'] as String
          : _email;
      _profile = data;
      _watchProfile(user.uid);
      await CommercePrototypeStore.instance.attach(role: _role, email: _email);
      await selectLearner(_email);
      notifyListeners();
      return true;
    } catch (_) {
      lastError = 'Your profile could not be loaded. Check your connection.';
      return false;
    }
  }

  Future<bool> updateProfile(
    String name, {
    Map<String, String>? details,
  }) async {
    if (_uid == null || name.trim().isEmpty) return false;
    try {
      final update = <String, dynamic>{
        'displayName': name.trim(),
        if (details != null)
          for (final e in details.entries) e.key: e.value.trim(),
      };
      await Backend.db.collection('users').doc(_uid).update(update);
      if (name.trim() != _displayName && _role == 'Learner') {
        // Keep the employer's employee list in step with the new name.
        try {
          final records = await Backend.db
              .collection('employees')
              .where('email', isEqualTo: _email)
              .get();
          for (final doc in records.docs) {
            await doc.reference.update({'name': name.trim()});
          }
        } catch (_) {}
      }
      _displayName = name.trim();
      _profile = {..._profile, ...update};
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Profile is loaded at sign-in; kept for existing call sites.
  Future<void> loadProfile() async {}

  /// Clears the session synchronously (so the next route is unprotected),
  /// then signs out of Firebase.
  StreamSubscription<dynamic>? _profileSub;

  /// Keeps the signed-in user's name, role and details live: edits made on
  /// another device or by an admin show up immediately.
  void _watchProfile(String uid) {
    _profileSub?.cancel();
    _profileSub = Backend.db.collection('users').doc(uid).snapshots().listen((
      snap,
    ) {
      final data = snap.data();
      if (data == null || _uid != uid) return;
      if (data['status'] == 'Suspended') {
        lastError = 'This account is suspended. Contact MT Alchemy for help.';
        signOut();
        return;
      }
      final name = (data['displayName'] as String?)?.trim();
      _displayName = name == null || name.isEmpty ? _email : name;
      final role = data['role'] as String?;
      if (allRoles.contains(role) && role != _role) {
        _role = role;
        CommercePrototypeStore.instance.attach(role: _role, email: _email);
      }
      _profile = data;
      notifyListeners();
    }, onError: (_) {});
  }

  Future<void> signOut() async {
    _profileSub?.cancel();
    _profileSub = null;
    _uid = null;
    _email = null;
    _role = null;
    _displayName = null;
    _profile = const {};
    CommercePrototypeStore.instance.activeEmployer = null;
    selectLearner(null);
    notifyListeners();
    // Queued progress and commerce writes keep running in the background;
    // Firestore sends them before the session's token is dropped.
    await Backend.auth.signOut();
    await CommercePrototypeStore.instance.detach();
    notifyListeners();
  }
}
