import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_constants.dart';

/// Menyimpan pengaturan aplikasi: status premium, audio, dan jilid yang
/// sudah di-unlock via rewarded ad.
class SettingsProvider extends ChangeNotifier {
  static const _key = 'iqro_settings_v1';

  bool _isPremium = false;
  bool _musicOn = true;
  bool _sfxOn = true;
  Set<int> _unlockedJilids = {};

  bool get isPremium => _isPremium;
  bool get musicOn => _musicOn;
  bool get sfxOn => _sfxOn;

  // ─── Load / Save ─────────────────────────────────────────────────────────

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;

      final map = jsonDecode(raw) as Map<String, dynamic>;
      _isPremium = (map['isPremium'] as bool?) ?? false;
      _musicOn = (map['musicOn'] as bool?) ?? true;
      _sfxOn = (map['sfxOn'] as bool?) ?? true;
      _unlockedJilids = {
        ...((map['unlockedJilids'] as List?)?.map((e) => e as int) ?? []),
      };
      notifyListeners();
    } catch (e) {
      debugPrint('[Settings] Load error: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'isPremium': _isPremium,
          'musicOn': _musicOn,
          'sfxOn': _sfxOn,
          'unlockedJilids': _unlockedJilids.toList(),
        }),
      );
    } catch (e) {
      debugPrint('[Settings] Save error: $e');
    }
  }

  // ─── Aksi ─────────────────────────────────────────────────────────────────

  Future<void> toggleMusic() async {
    _musicOn = !_musicOn;
    notifyListeners();
    await _save();
  }

  Future<void> toggleSfx() async {
    _sfxOn = !_sfxOn;
    notifyListeners();
    await _save();
  }

  /// Set status premium. Jika true, tidak perlu track unlock individual.
  Future<void> setPremium(bool value) async {
    _isPremium = value;
    notifyListeners();
    await _save();
  }

  /// Unlock jilid spesifik via rewarded ad.
  Future<void> unlockJilid(int jilidIndex) async {
    if (_unlockedJilids.contains(jilidIndex)) return;
    _unlockedJilids.add(jilidIndex);
    notifyListeners();
    await _save();
  }

  // ─── Query ────────────────────────────────────────────────────────────────

  /// Jilid terbuka jika: (1) gratis, (2) premium aktif, atau (3) sudah di-unlock.
  bool isJilidUnlocked(int jilidIndex) {
    if (jilidIndex < AppConstants.freeJilidCount) return true;
    if (_isPremium) return true;
    return _unlockedJilids.contains(jilidIndex);
  }
}
