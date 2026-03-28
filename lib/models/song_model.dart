import 'package:flutter/material.dart' show Color;

/// Data class untuk satu lagu / nasyid.
///
/// [audioPath] menggunakan path relatif dari folder assets/
/// (tanpa awalan 'assets/') karena AudioPlayers memakai AssetSource.
class SongModel {
  final String id;
  final String title;
  final String artist;
  final int durationSeconds;

  /// Path relatif dari assets/, contoh: 'audio/music/alif_ba_ta.mp3'
  final String audioPath;
  final bool isLocked;
  final String arabicDecor;
  final Color color;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    required this.audioPath,
    required this.isLocked,
    required this.arabicDecor,
    required this.color,
  });

  // ─── 5 Lagu Hijaiyah ──────────────────────────────────────────────────────

  static List<SongModel> get songs => [
        // ── GRATIS 1 ──────────────────────────────────────────────────────────
        SongModel(
          id: 'alif_ba_ta',
          title: 'Alif Ba Ta',
          artist: 'Iqro Anak Ceria',
          durationSeconds: 120,
          audioPath: 'audio/music/alif_ba_ta.mp3',
          isLocked: false,
          arabicDecor: 'أ',
          color: const Color(0xFF4CAF50),
        ),

        // ── GRATIS 2 ──────────────────────────────────────────────────────────
        SongModel(
          id: 'ayo_mengaji',
          title: 'Ayo Belajar Mengaji',
          artist: 'Iqro Anak Ceria',
          durationSeconds: 105,
          audioPath: 'audio/music/ayo_mengaji.mp3',
          isLocked: false,
          arabicDecor: 'ب',
          color: const Color(0xFF2196F3),
        ),

        // ── PREMIUM 3 ─────────────────────────────────────────────────────────
        SongModel(
          id: 'hijaiyah_sayang',
          title: 'Huruf Hijaiyah Ku Sayang',
          artist: 'Iqro Anak Ceria',
          durationSeconds: 130,
          audioPath: 'audio/music/hijaiyah_sayang.mp3',
          isLocked: true,
          arabicDecor: 'ح',
          color: const Color(0xFFFF9800),
        ),

        // ── PREMIUM 4 ─────────────────────────────────────────────────────────
        SongModel(
          id: 'bismillah_belajar',
          title: 'Bismillah Belajar',
          artist: 'Iqro Anak Ceria',
          durationSeconds: 110,
          audioPath: 'audio/music/bismillah.mp3',
          isLocked: true,
          arabicDecor: 'بِ',
          color: const Color(0xFF9C27B0),
        ),

        // ── PREMIUM 5 ─────────────────────────────────────────────────────────
        SongModel(
          id: 'sholawat_anak',
          title: 'Sholawat Anak Ceria',
          artist: 'Iqro Anak Ceria',
          durationSeconds: 140,
          audioPath: 'audio/music/sholawat.mp3',
          isLocked: true,
          arabicDecor: 'صَ',
          color: const Color(0xFFE91E63),
        ),
      ];
}
