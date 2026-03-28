import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Tipe sound effect yang tersedia
enum SfxType { correct, incorrect, complete, tap, star }

/// Service audio singleton untuk seluruh aplikasi.
///
/// ## Pelafalan Huruf
/// Menggunakan **dua lapisan**:
/// 1. **File MP3** (prioritas utama) — taruh di `assets/audio/hijaiyah/`.
///    Nama file mengikuti [audioPath] dari [JilidPage] (contoh: `alif.mp3`).
/// 2. **TTS Arabic fallback** — jika file belum ada, mesin TTS bawaan Android
///    akan mengucapkan teks Arab secara otomatis.
///
/// ## SFX & Musik
/// Uncomment blok `try { }` setelah menaruh file di `assets/audio/sfx/` dan `assets/audio/music/`.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _hurufPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  bool _isEnabled = true;
  bool _ttsReady = false;

  bool get isEnabled => _isEnabled;

  void setEnabled(bool value) {
    _isEnabled = value;
    if (!value) stopBgMusic();
  }

  // ─── Inisialisasi TTS ────────────────────────────────────────────────────────

  Future<void> _ensureTts() async {
    if (_ttsReady) return;
    try {
      // Bahasa Arab Saudi — pastikan TTS engine mendukung Arabic
      await _tts.setLanguage('ar-SA');
      // Kecepatan lambat (0.0–1.0) agar anak dapat menangkap bunyi
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      // Nada sedikit lebih tinggi agar terdengar lebih jelas
      await _tts.setPitch(1.1);
      _ttsReady = true;
      debugPrint('[Audio] TTS Arabic siap');
    } catch (e) {
      debugPrint('[Audio] TTS init error: $e');
    }
  }

  // ─── Pelafalan Huruf ─────────────────────────────────────────────────────────

  /// Putar pelafalan satu huruf hijaiyah.
  ///
  /// - [audioPath] : path file MP3 di assets (diputar jika file ada)
  /// - [arabicText]: teks Arab untuk TTS fallback (contoh: 'أَ', 'بَ')
  /// - [letterName] : nama huruf Indonesia untuk log (contoh: 'Alif')
  ///
  /// **Prioritas**: file MP3 → TTS Arab → tidak ada suara
  Future<void> playHuruf(
    String audioPath, {
    String? arabicText,
    String? letterName,
  }) async {
    if (!_isEnabled) return;

    // ── Prioritas 1: File MP3 ────────────────────────────────────────────────
    // Uncomment blok ini setelah file audio ditaruh di assets/audio/hijaiyah/
    //
    try {
      await _hurufPlayer.stop();
      await _hurufPlayer.play(AssetSource(audioPath));
      return; // sukses → tidak perlu TTS
    } catch (e) {
      debugPrint('[Audio] File tidak ditemukan ($audioPath), pakai TTS');
    }

    // ── Prioritas 2: TTS Arabic fallback ────────────────────────────────────
    if (arabicText != null && arabicText.isNotEmpty) {
      await _ensureTts();
      try {
        await _tts.stop();
        await _tts.speak(arabicText);
        debugPrint('[Audio] TTS: ${letterName ?? arabicText}');
      } catch (e) {
        debugPrint('[Audio] TTS speak error: $e');
      }
    } else {
      debugPrint('[Audio] Huruf: $audioPath (tidak ada audio/TTS)');
    }
  }

  // ─── Sound Effect ────────────────────────────────────────────────────────────

  Future<void> playSfx(SfxType type) async {
    if (!_isEnabled) return;
    final path = _sfxPaths[type]!;
    debugPrint('[Audio] SFX: $path');
    // Uncomment setelah file SFX ditaruh di assets/audio/sfx/
    // try {
    //   await _sfxPlayer.stop();
    //   await _sfxPlayer.play(AssetSource(path));
    // } catch (e) {
    //   debugPrint('[Audio] playSfx error: $e');
    // }
  }

  // ─── Musik Latar ─────────────────────────────────────────────────────────────

  Future<void> playBgMusic(String path) async {
    if (!_isEnabled) return;
    debugPrint('[Audio] BG Music: $path');
    // Uncomment setelah file musik ditaruh di assets/audio/music/
    // try {
    //   await _bgPlayer.setReleaseMode(ReleaseMode.loop);
    //   await _bgPlayer.play(AssetSource(path));
    // } catch (e) {
    //   debugPrint('[Audio] playBgMusic error: $e');
    // }
  }

  Future<void> stopBgMusic() async {
    await _tts.stop();
    // await _bgPlayer.stop();
  }

  void dispose() {
    _hurufPlayer.dispose();
    _sfxPlayer.dispose();
    _bgPlayer.dispose();
    _tts.stop();
  }

  // ─── Path File ───────────────────────────────────────────────────────────────

  static const Map<SfxType, String> _sfxPaths = {
    SfxType.correct: 'audio/sfx/correct.mp3',
    SfxType.incorrect: 'audio/sfx/incorrect.mp3',
    SfxType.complete: 'audio/sfx/complete.mp3',
    SfxType.tap: 'audio/sfx/tap.mp3',
    SfxType.star: 'audio/sfx/star.mp3',
  };
}
