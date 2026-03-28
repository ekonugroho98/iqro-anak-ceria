import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../models/song_model.dart';

/// Halaman pemutar lagu dengan gradient background, artwork berputar + glow,
/// equalizer animasi, dan navigasi prev/next lagu.
class SongPlayerScreen extends StatefulWidget {
  final SongModel song;

  const SongPlayerScreen({super.key, required this.song});

  @override
  State<SongPlayerScreen> createState() => _SongPlayerScreenState();
}

class _SongPlayerScreenState extends State<SongPlayerScreen>
    with TickerProviderStateMixin {
  // ─── Audio Player ─────────────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  int _currentSecond = 0;
  bool _playerReady = false;
  int _actualDurationSeconds = 0;

  // ─── Animasi ──────────────────────────────────────────────────────────────
  late final AnimationController _rotationController;
  late final AnimationController _equalizerController;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  // Offset stagger tiap bar equalizer (0.0 – 1.0)
  static const List<double> _eqOffsets = [0.0, 0.3, 0.6, 0.15, 0.45];

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _equalizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _initPlayer();
  }

  // ─── Inisialisasi AudioPlayer ─────────────────────────────────────────────

  Future<void> _initPlayer() async {
    _player.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() => _currentSecond = position.inSeconds);
    });

    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final playing = state == PlayerState.playing;
      setState(() => _isPlaying = playing);
      if (playing) {
        _rotationController.repeat();
        _equalizerController.repeat(reverse: true);
        _glowController.repeat(reverse: true);
      } else {
        _rotationController.stop();
        _equalizerController.stop();
        _glowController.stop();
        _glowController.reverse();
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _currentSecond = _durationSeconds;
      });
      _rotationController.stop();
      _equalizerController.stop();
      _glowController
        ..stop()
        ..reverse();
    });

    try {
      await _player.setSource(AssetSource(widget.song.audioPath));
      final duration = await _player.getDuration();
      if (mounted) {
        setState(() {
          _playerReady = true;
          _actualDurationSeconds =
              duration?.inSeconds ?? widget.song.durationSeconds;
        });
      }
    } catch (e) {
      debugPrint('[Player] setSource error: $e');
      if (mounted) {
        setState(() {
          _playerReady = true; // tetap bisa tap, biar ada feedback
          _actualDurationSeconds = widget.song.durationSeconds;
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _rotationController.dispose();
    _equalizerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  int get _durationSeconds =>
      _actualDurationSeconds > 0
          ? _actualDurationSeconds
          : widget.song.durationSeconds;

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  int get _songIndex =>
      SongModel.songs.indexWhere((s) => s.id == widget.song.id);

  // ─── Kontrol ──────────────────────────────────────────────────────────────

  Future<void> _togglePlay() async {
    if (!_playerReady) return;
    if (_currentSecond >= _durationSeconds) {
      await _player.seek(Duration.zero);
      await _player.resume();
      return;
    }
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  Future<void> _onRewind() async {
    final newSec = (_currentSecond - 10).clamp(0, _durationSeconds);
    await _player.seek(Duration(seconds: newSec));
    setState(() => _currentSecond = newSec);
  }

  Future<void> _onFastForward() async {
    final newSec = (_currentSecond + 10).clamp(0, _durationSeconds);
    if (newSec >= _durationSeconds) {
      await _player.seek(Duration(seconds: _durationSeconds - 1));
      setState(() => _currentSecond = _durationSeconds - 1);
    } else {
      await _player.seek(Duration(seconds: newSec));
      setState(() => _currentSecond = newSec);
    }
  }

  void _onPrevSong() {
    final idx = _songIndex;
    if (idx <= 0) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SongPlayerScreen(song: SongModel.songs[idx - 1]),
      ),
    );
  }

  void _onNextSong() {
    final idx = _songIndex;
    if (idx >= SongModel.songs.length - 1) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SongPlayerScreen(song: SongModel.songs[idx + 1]),
      ),
    );
  }

  Future<void> _onSliderChanged(double value) async {
    final sec = value.toInt();
    setState(() => _currentSecond = sec);
    await _player.seek(Duration(seconds: sec));
  }

  // ─── Widgets ──────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
            onPressed: () => Navigator.pop(context),
            tooltip: 'Kembali',
          ),
          Expanded(
            child: Text(
              widget.song.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Spacer agar judul benar-benar di tengah
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildArtwork() {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _glowAnimation]),
      builder: (_, child) {
        final glowRadius = 20.0 + _glowAnimation.value * 30.0;
        final glowAlpha = 0.25 + _glowAnimation.value * 0.25;
        return Transform.rotate(
          angle: _rotationController.value * 2 * math.pi,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              color: widget.song.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: widget.song.color.withValues(alpha: 0.55),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.song.color.withValues(alpha: glowAlpha),
                  blurRadius: glowRadius,
                  spreadRadius: _glowAnimation.value * 6,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            widget.song.arabicDecor,
            style: TextStyle(
              fontSize: 90,
              color: widget.song.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Icon(
              Icons.music_note_rounded,
              color: widget.song.color.withValues(alpha: 0.55),
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            widget.song.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.song.artist,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final duration = _durationSeconds.toDouble();
    final current = _currentSecond.toDouble().clamp(0.0, duration);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: widget.song.color,
              inactiveTrackColor: widget.song.color.withValues(alpha: 0.2),
              thumbColor: widget.song.color,
              overlayColor: widget.song.color.withValues(alpha: 0.15),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: current,
              min: 0,
              max: duration > 0 ? duration : 1,
              onChanged: _onSliderChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmt(_currentSecond),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _fmt(_durationSeconds),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Equalizer animasi — 5 bar naik-turun saat play, flat saat pause.
  Widget _buildEqualizer() {
    return AnimatedBuilder(
      animation: _equalizerController,
      builder: (_, __) {
        return SizedBox(
          height: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (i) {
              final phase = (_equalizerController.value + _eqOffsets[i]) % 1.0;
              final height = _isPlaying
                  ? 8.0 + math.sin(phase * math.pi) * 20.0
                  : 6.0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: 5,
                  height: height,
                  decoration: BoxDecoration(
                    color: widget.song.color.withValues(
                      alpha: _isPlaying ? 0.85 : 0.3,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    final bool isDone = _currentSecond >= _durationSeconds;
    final int idx = _songIndex;
    final bool hasPrev = idx > 0;
    final bool hasNext = idx < SongModel.songs.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Prev song
        Opacity(
          opacity: hasPrev ? 1.0 : 0.3,
          child: IconButton(
            onPressed: hasPrev ? _onPrevSong : null,
            icon: const Icon(Icons.skip_previous_rounded),
            iconSize: 36,
            color: widget.song.color,
            tooltip: 'Lagu sebelumnya',
          ),
        ),
        const SizedBox(width: 4),

        // Rewind 10s
        IconButton(
          onPressed: _onRewind,
          icon: const Icon(Icons.replay_10_rounded),
          iconSize: 34,
          color: widget.song.color,
          tooltip: 'Mundur 10 detik',
        ),
        const SizedBox(width: 8),

        // Play / Pause / Replay
        GestureDetector(
          onTap: _playerReady ? _togglePlay : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: widget.song.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.song.color.withValues(
                    alpha: _isPlaying ? 0.5 : 0.3,
                  ),
                  blurRadius: _isPlaying ? 20 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _playerReady
                ? Icon(
                    isDone
                        ? Icons.replay_rounded
                        : (_isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                    color: Colors.white,
                    size: 40,
                  )
                : const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),

        // Fast-forward 10s
        IconButton(
          onPressed: _onFastForward,
          icon: const Icon(Icons.forward_10_rounded),
          iconSize: 34,
          color: widget.song.color,
          tooltip: 'Maju 10 detik',
        ),
        const SizedBox(width: 4),

        // Next song
        Opacity(
          opacity: hasNext ? 1.0 : 0.3,
          child: IconButton(
            onPressed: hasNext ? _onNextSong : null,
            icon: const Icon(Icons.skip_next_rounded),
            iconSize: 36,
            color: widget.song.color,
            tooltip: 'Lagu berikutnya',
          ),
        ),
      ],
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.song.color.withValues(alpha: 0.35),
                  widget.song.color.withValues(alpha: 0.08),
                  const Color(0xFFFAF8F0),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // ── Konten ────────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // AppBar transparan
                _buildAppBar(),

                const Spacer(flex: 2),

                // Artwork berputar + glow
                Center(child: _buildArtwork()),

                const Spacer(flex: 2),

                // Judul & Artis
                _buildTitleSection(),

                const Spacer(flex: 1),

                // Progress bar
                _buildProgressBar(),

                const SizedBox(height: 4),

                // Equalizer animasi
                _buildEqualizer(),

                const SizedBox(height: 12),

                // Kontrol prev/rewind/play/forward/next
                _buildControls(),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
