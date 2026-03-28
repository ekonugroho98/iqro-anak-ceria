import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress_model.dart';

/// Provider untuk progres belajar anak.
/// Menyimpan dan memuat data dari SharedPreferences secara otomatis.
class ProgressProvider extends ChangeNotifier {
  static const String _storageKey = 'iqro_progress_v1';

  ProgressModel _data = ProgressModel.empty();

  ProgressModel get data => _data;
  int get totalStars => _data.totalStars;

  // ─── Load / Save ────────────────────────────────────────────────────────────

  /// Muat progres dari local storage. Panggil sekali saat app start.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        _data = ProgressModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Progress] Load error: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_data.toJson()));
    } catch (e) {
      debugPrint('[Progress] Save error: $e');
    }
  }

  // ─── Aksi ───────────────────────────────────────────────────────────────────

  /// Tandai satu halaman sebagai sudah dipelajari.
  ///
  /// Mengembalikan `true` jika ini **pertama kali** halaman tersebut dipelajari
  /// (digunakan untuk memicu animasi bintang di UI).
  Future<bool> markLearned(int jilidIndex, int pageIndex) async {
    if (_data.isPageLearned(jilidIndex, pageIndex)) return false;

    // Salin map agar immutable
    final updatedPages = {
      for (final e in _data.learnedPages.entries)
        e.key: Set<int>.from(e.value),
    };
    updatedPages.putIfAbsent(jilidIndex, () => {});
    updatedPages[jilidIndex]!.add(pageIndex);

    _data = _data.copyWith(
      learnedPages: updatedPages,
      totalStars: _data.totalStars + 1,
    );
    notifyListeners();
    await _save();
    return true;
  }

  /// Tambah bintang secara langsung — digunakan oleh kuis saat selesai
  Future<void> addStars(int count) async {
    if (count <= 0) return;
    _data = _data.copyWith(totalStars: _data.totalStars + count);
    notifyListeners();
    await _save();
  }

  // ─── Query ──────────────────────────────────────────────────────────────────

  bool isLearned(int jilidIndex, int pageIndex) =>
      _data.isPageLearned(jilidIndex, pageIndex);

  int learnedCount(int jilidIndex) => _data.learnedCount(jilidIndex);
}
