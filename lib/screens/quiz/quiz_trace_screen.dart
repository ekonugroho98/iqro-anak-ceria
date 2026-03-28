import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../providers/progress_provider.dart';
import '../../services/audio_service.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

/// Kuis "Tulis Ulang" — trace huruf yang ditampilkan di canvas.
class QuizTraceScreen extends StatefulWidget {
  const QuizTraceScreen({super.key});

  @override
  State<QuizTraceScreen> createState() => _QuizTraceState();
}

class _QuizTraceState extends State<QuizTraceScreen>
    with SingleTickerProviderStateMixin {
  static const _totalLetters = 10;

  final _audio = AudioService();
  final _rng = Random();

  late List<int> _letterOrder; // indeks 0-27 yang akan ditrace
  int _current = 0;
  int _score = 0;
  bool _finished = false;

  // Titik-titik trace yang digambar user
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  // Animasi fade-in huruf panduan saat "show hint"
  late final AnimationController _hintCtrl;
  late final Animation<double> _hintAnim;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _letterOrder = List.generate(28, (i) => i)
      ..shuffle(_rng)
      ..take(_totalLetters).toList();
    _letterOrder = _letterOrder.take(_totalLetters).toList();

    _hintCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _hintAnim = CurvedAnimation(parent: _hintCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _hintCtrl.dispose();
    super.dispose();
  }

  // ── Logic ─────────────────────────────────────────────────────────────────

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  void _onPanStart(DragStartDetails d) {
    setState(() => _currentStroke = [d.localPosition]);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _currentStroke.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails d) {
    if (_currentStroke.isNotEmpty) {
      setState(() {
        _strokes.add(List.of(_currentStroke));
        _currentStroke = [];
      });
    }
  }

  void _toggleHint() {
    setState(() => _showHint = !_showHint);
    if (_showHint) {
      _hintCtrl.forward(from: 0);
    } else {
      _hintCtrl.reverse();
    }
  }

  void _onDone() {
    if (_strokes.isEmpty) return; // tidak ada coretan

    final letterIndex = _letterOrder[_current];
    _audio.playSfx(SfxType.correct);
    _audio.playHuruf(
      'assets/audio/hijaiyah/${AppConstants.hijaiyahNames[letterIndex].toLowerCase().replaceAll("'", "")}.mp3',
      arabicText: AppConstants.hijaiyahArabic[letterIndex],
      letterName: AppConstants.hijaiyahNames[letterIndex],
    );

    setState(() => _score++);

    final nextIndex = _current + 1;
    if (nextIndex >= _totalLetters) {
      context.read<ProgressProvider>().addStars(_score);
      setState(() => _finished = true);
    } else {
      setState(() {
        _current = nextIndex;
        _strokes.clear();
        _currentStroke = [];
        _showHint = false;
      });
      _hintCtrl.reset();
    }
  }

  void _restart() {
    setState(() {
      _letterOrder = List.generate(28, (i) => i)
        ..shuffle(_rng)
        ..take(_totalLetters).toList();
      _letterOrder = _letterOrder.take(_totalLetters).toList();
      _current = 0;
      _score = 0;
      _finished = false;
      _strokes.clear();
      _currentStroke = [];
      _showHint = false;
    });
    _hintCtrl.reset();
  }

  int get _earnedStars {
    if (_score >= 8) return 3;
    if (_score >= 5) return 2;
    return 1;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_finished) return _buildResult();
    return _buildTrace();
  }

  Widget _buildTrace() {
    final letterIndex = _letterOrder[_current];
    final arabic = AppConstants.hijaiyahArabic[letterIndex];
    final name = AppConstants.hijaiyahNames[letterIndex];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tulis Ulang',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: AppTheme.premium, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Huruf ${_current + 1} dari $_totalLetters',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${((_current + 1) / _totalLetters * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_current + 1) / _totalLetters,
                backgroundColor: Colors.grey[200],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),

            // Nama huruf
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Tulis huruf: $name',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Canvas area
            Expanded(
              child: Stack(
                children: [
                  // Hint overlay (huruf samar)
                  if (_showHint)
                    Positioned.fill(
                      child: FadeTransition(
                        opacity: _hintAnim,
                        child: Center(
                          child: Text(
                            arabic,
                            style: TextStyle(
                              fontSize: 180,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              height: 1.0,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                    ),

                  // Drawing canvas
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: _TracePainter(
                            strokes: _strokes,
                            currentStroke: _currentStroke,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),

                  // Referensi huruf kecil di pojok kanan atas
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          arabic,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            height: 1.1,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tombol aksi
            Row(
              children: [
                // Hapus
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Hapus',
                  color: AppTheme.incorrect,
                  onTap: _clearCanvas,
                ),
                const SizedBox(width: 10),
                // Hint
                _ActionButton(
                  icon: _showHint
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  label: _showHint ? 'Tutup' : 'Tampilkan',
                  color: Colors.orange,
                  onTap: _toggleHint,
                ),
                const SizedBox(width: 10),
                // Selesai
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _strokes.isEmpty ? null : _onDone,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.correct,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final stars = _earnedStars;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _score >= 8 ? '🏆' : _score >= 5 ? '🎉' : '💪',
                style: const TextStyle(fontSize: 72),
              ),
              const SizedBox(height: 12),
              Text(
                _score >= 8
                    ? 'Luar Biasa!'
                    : _score >= 5
                        ? 'Bagus!'
                        : 'Terus Semangat!',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_score / $_totalLetters huruf berhasil ditulis',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final filled = i < stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      filled
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: filled ? AppTheme.premium : Colors.grey[300],
                      size: 52,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '+$_score bintang ditambahkan!',
                style: const TextStyle(
                  color: AppTheme.premium,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Kembali'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _restart,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Main Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _TracePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  const _TracePainter({
    required this.strokes,
    required this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> pts) {
      if (pts.isEmpty) return;
      if (pts.length == 1) {
        canvas.drawCircle(pts[0], 3, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        return;
      }
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final stroke in strokes) {
      drawStroke(stroke);
    }
    drawStroke(currentStroke);
  }

  @override
  bool shouldRepaint(_TracePainter old) =>
      old.strokes != strokes || old.currentStroke != currentStroke;
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
