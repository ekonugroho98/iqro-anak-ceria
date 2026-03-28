import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/song_model.dart';
import '../../providers/settings_provider.dart';
import '../../services/ad_service.dart';
import 'song_player_screen.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  /// Durasi aktual per song.id, diisi async dari file MP3.
  /// Selama belum diisi, tampilkan nilai fallback dari SongModel.durationSeconds.
  final Map<String, int> _actualDurations = {};

  @override
  void initState() {
    super.initState();
    _loadAllDurations();
  }

  // ─── Load durasi aktual dari file MP3 ─────────────────────────────────────

  Future<void> _loadAllDurations() async {
    final probe = AudioPlayer();
    try {
      for (final song in SongModel.songs) {
        try {
          await probe.setSource(AssetSource(song.audioPath));
          final duration = await probe.getDuration();
          if (duration != null && mounted) {
            setState(() => _actualDurations[song.id] = duration.inSeconds);
          }
        } catch (_) {
          // Gagal baca satu lagu → skip, gunakan fallback durationSeconds
        }
      }
    } finally {
      await probe.dispose();
    }
  }

  // ─── Durasi efektif: aktual dari MP3 atau fallback hardcoded ──────────────

  int _getDuration(SongModel song) =>
      _actualDurations[song.id] ?? song.durationSeconds;

  // ─── Format durasi menjadi mm:ss ─────────────────────────────────────────

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ─── Dialog tonton video untuk unlock lagu ───────────────────────────────

  Future<void> _onLockedTap(
    BuildContext context,
    SongModel song,
    bool isPremium,
  ) async {
    if (isPremium) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SongPlayerScreen(song: song)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: song.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  song.arabicDecor,
                  style: TextStyle(
                    fontSize: 22,
                    color: song.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                song.title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: const Text(
          'Tonton video untuk membuka lagu ini?',
          style: TextStyle(fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Batalkan'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            icon: const Icon(Icons.play_circle_outline, size: 20),
            label: const Text('Tonton Gratis'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final rewarded = await AdService().showRewarded();
    if (!context.mounted) return;

    if (rewarded) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SongPlayerScreen(song: song)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video belum tersedia, coba lagi nanti.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── Artwork kotak berwarna ───────────────────────────────────────────────

  Widget _buildArtwork(SongModel song, {double size = 64}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: song.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: song.color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Center(
        child: Text(
          song.arabicDecor,
          style: TextStyle(
            fontSize: size * 0.45,
            color: song.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ─── Badge status ─────────────────────────────────────────────────────────

  Widget _buildBadge(bool isLocked, bool isPremium) {
    if (!isLocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.correct.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.correct, width: 1),
        ),
        child: Text(
          'GRATIS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.correct,
          ),
        ),
      );
    }

    if (isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.premium.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.premium, width: 1),
        ),
        child: Text(
          'PREMIUM',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: const Text(
        'TERKUNCI 🔒',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ─── Card lagu ────────────────────────────────────────────────────────────

  Widget _buildSongCard(
    BuildContext context,
    SongModel song,
    bool isPremium,
  ) {
    final bool isAccessible = !song.isLocked || isPremium;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (isAccessible) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SongPlayerScreen(song: song)),
            );
          } else {
            _onLockedTap(context, song, isPremium);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Artwork
              _buildArtwork(song),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.artist,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatDuration(_getDuration(song)),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildBadge(song.isLocked, isPremium),
                      ],
                    ),
                  ],
                ),
              ),
              // Ikon aksi
              const SizedBox(width: 8),
              Icon(
                isAccessible
                    ? Icons.play_circle_filled_rounded
                    : Icons.lock_rounded,
                color: isAccessible ? song.color : Colors.grey.shade400,
                size: 36,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isPremium = settings.isPremium;
        final songs = SongModel.songs;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text(
              'Lagu & Nasyid',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
          ),
          body: Column(
            children: [
              // Header info
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.music_note_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${songs.length} lagu tersedia',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Daftar lagu
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    return _buildSongCard(context, songs[index], isPremium);
                  },
                ),
              ),
              // Tombol Premium di bawah
              if (!isPremium)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Dapatkan semua lagu dengan Premium!',
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppTheme.primary,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.premium,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        icon: const Text(
                          '★',
                          style: TextStyle(fontSize: 18),
                        ),
                        label: const Text(
                          'Premium',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
