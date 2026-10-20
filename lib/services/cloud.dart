import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'auth.dart';

/// Keeps one copy of the user's data in Firestore, at users/{uid}, so it
/// follows the account to other devices. Only a logged-in user can touch their
/// own document (see firestore.rules). Every call is safe to make when
/// Firebase is off or the user is logged out: it just does nothing.
class Cloud {
  static DocumentReference<Map<String, dynamic>>? get _doc {
    final u = Auth.user;
    if (u == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(u.uid);
  }

  /// The saved data, or null when this account has nothing saved yet.
  /// Throws when it can't be reached (offline, rules not set).
  static Future<Map<String, dynamic>?> pull() async {
    final doc = _doc;
    if (doc == null) return null;
    final snap = await doc.get();
    return snap.data();
  }

  /// Saves [data] (replaces what was there). Errors are only logged, because a
  /// failed sync must never break the app.
  static Future<void> push(Map<String, dynamic> data) async {
    final doc = _doc;
    if (doc == null) return;
    try {
      await doc.set({...data, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Cloud save failed: $e');
    }
  }
}
