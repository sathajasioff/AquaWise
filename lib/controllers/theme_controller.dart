// lib/controllers/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeController extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _fs = FirebaseFirestore.instance;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void _apply(String theme) {
    switch (theme) {
      case 'light': _themeMode = ThemeMode.light; break;
      case 'dark':  _themeMode = ThemeMode.dark;  break;
      default:      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> loadUserTheme() async {
    final u = _auth.currentUser;
    if (u == null) { _apply('system'); return; }
    final snap = await _fs.collection('users').doc(u.uid).get();
    _apply((snap.data()?['theme'] ?? 'system') as String);
  }

  Future<void> updateTheme(String theme) async {
    final u = _auth.currentUser;
    if (u == null) return;
    // 1) apply immediately (instant UI change)
    _apply(theme);
    // 2) persist
    await _fs.collection('users').doc(u.uid).update({'theme': theme});
  }
}
