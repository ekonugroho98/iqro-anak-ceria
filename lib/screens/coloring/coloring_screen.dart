import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../services/audio_service.dart';

// ─── Tool enum ────────────────────────────────────────────────────────────────

enum _Tool { brushSmall, brushLarge, fill, eraser }

// ─── Data: satu sapuan kuas ───────────────────────────────────────────────────

class _Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;

  const _Stroke({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
  });
}

// ─── Command pattern untuk Undo ───────────────────────────────────────────────

sealed class _DrawAction {}

final class _StrokeAction extends _DrawAction {
  final _Stroke stroke;
  _StrokeAction(this.stroke);
}

final class _FillAction extends _DrawAction {
  final Color prevColor;
  _FillAction(this.prevColor);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ColoringScreen extends StatefulWidget {
  final int letterIndex;

  const ColoringScreen({super.key, required this.letterIndex});

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen>
    with SingleTickerProviderStateMixin {
  final _canvasKey = GlobalKey();
  final _audio = AudioService();

  // Drawing state
  final List<_Stroke> _strokes = [];
  final List<_DrawAction> _history = [];
  List<Offset> _currentPoints = [];
  Color _bgColor = Colors.white;
  Color _selectedColor = const Color(0xFF2196F3);
  _Tool _tool = _Tool.brushSmall;

  // Save state
  bool _isSaving = false;

  // Celebration animation
  late final AnimationController _celebCtrl;
  late final Animation<double> _celebScale;
  late final Animation<double> _celebOpacity;
  bool _showCelebration = false;

  // 12 warna palet (gratis)
  static const _palette = [
    Color(0xFFE53935), Color(0xFFFF6F00), Color(0xFFFDD835), Color(0xFF43A047),
    Color(0xFF1E88E5), Color(0xFF8E24AA), Color(0xFFEC407A), Color(0xFF00ACC1),
    Color(0xFF7CB342), Color(0xFF6D4C41), Color(0xFF546E7A), Color(0xFF212121),
  ];

  static const _brushSmall = 8.0;
  static const _brushLarge = 28.0;
  static const _eraserSize = 40.0;

  @override
  void initState() {
    super.initState();
    _celebCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _celebScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_celebCtrl);
    _celebOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_celebCtrl);
    _celebCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _celebCtrl.reset();
        if (mounted) setState(() => _showCelebration = false);
      }
    });
  }

  @override
  void dispose() {
    _celebCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  double get _strokeWidth => switch (_tool) {
        _Tool.brushSmall => _brushSmall,
        _Tool.brushLarge => _brushLarge,
        _Tool.eraser => _eraserSize,
        _Tool.fill => 0,
      };

  // ── Gesture handlers ─────────────────────────────────────────────────────

  void _onTapCanvas() {
    if (_tool != _Tool.fill) return;
    final prev = _bgColor;
    setState(() {
      _bgColor = _selectedColor;
      _history.add(_FillAction(prev));
    });
    _audio.playSfx(SfxType.tap);
  }

  void _onPanStart(DragStartDetails d) {
    if (_tool == _Tool.fill) return;
    setState(() => _currentPoints = [d.localPosition]);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_tool == _Tool.fill) return;
    setState(() => _currentPoints = [..._currentPoints, d.localPosition]);
  }

  void _onPanEnd(DragEndDetails _) {
    if (_tool == _Tool.fill || _currentPoints.isEmpty) return;
    final stroke = _Stroke(
      points: List.from(_currentPoints),
      color: _selectedColor,
      width: _strokeWidth,
      isEraser: _tool == _Tool.eraser,
    );
    setState(() {
      _strokes.add(stroke);
      _history.add(_StrokeAction(stroke));
      _currentPoints = [];
    });
    _audio.playSfx(SfxType.tap);
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _undo() {
    if (_history.isEmpty) return;
    final action = _history.removeLast();
    setState(() {
      if (action is _StrokeAction) {
        _strokes.remove(action.stroke);
      } else if (action is _FillAction) {
        _bgColor = action.prevColor;
      }
    });
  }

  void _clear() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mulai Ulang?'),
        content: const Text('Semua warna yang sudah dibuat akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _strokes.clear();
                _history.clear();
                _bgColor = Colors.white;
                _currentPoints = [];
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.incorrect,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Mulai Ulang'),
          ),
        ],
      ),
    );
  }

  void _celebrate() {
    final name = AppConstants.hijaiyahNames[widget.letterIndex];
    _audio.playHuruf(
        'audio/hijaiyah/${name.toLowerCase().replaceAll("'", "")}.mp3');
    _audio.playSfx(SfxType.complete);
    setState(() => _showCelebration = true);
    _celebCtrl.forward();
  }

  Future<void> _saveImage() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Canvas tidak ditemukan');

      final image = await boundary.toImage(pixelRatio: 2.0);
      // ignore: unused_local_variable
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      // TODO: Simpan bytes ke galeri menggunakan package image_gallery_saver:
      // await ImageGallerySaver.saveImage(bytes!.buffer.asUint8List(), name: 'hijaiyah_$letterIndex');

      _celebrate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Gambar berhasil disimpan!'),
            backgroundColor: AppTheme.correct,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final letter = AppConstants.hijaiyahArabic[widget.letterIndex];
    final name = AppConstants.hijaiyahNames[widget.letterIndex];
    final accent = Color(AppConstants.hijaiyahColors[widget.letterIndex]);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mewarnai $name',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.undo_rounded,
              color: _history.isEmpty ? Colors.grey[300] : Colors.grey[700],
            ),
            onPressed: _history.isEmpty ? null : _undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.grey[700]),
            onPressed: _clear,
            tooltip: 'Mulai ulang',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Canvas ──────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: RepaintBoundary(
                      key: _canvasKey,
                      child: GestureDetector(
                        onTap: _onTapCanvas,
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: _ColoringPainter(
                            strokes: _strokes,
                            currentPoints: _currentPoints,
                            currentColor: _selectedColor,
                            currentWidth: _strokeWidth,
                            isEraser: _tool == _Tool.eraser,
                            bgColor: _bgColor,
                            arabicChar: letter,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Tool bar ────────────────────────────────────────────────
              _ToolBar(
                selected: _tool,
                accent: accent,
                onSelect: (t) => setState(() => _tool = t),
              ),

              // ── Color palette ────────────────────────────────────────────
              _ColorPalette(
                palette: _palette,
                selected: _selectedColor,
                onSelect: (c) => setState(() {
                  _selectedColor = c;
                  if (_tool == _Tool.eraser) _tool = _Tool.brushSmall;
                }),
              ),

              // ── Save button ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveImage,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_alt_rounded),
                    label: Text(_isSaving ? 'Menyimpan...' : '✨  Simpan Mewarnai'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Celebration overlay ──────────────────────────────────────────
          if (_showCelebration) _CelebrationOverlay(
            letter: letter,
            name: name,
            scaleAnim: _celebScale,
            opacityAnim: _celebOpacity,
          ),
        ],
      ),
    );
  }
}

// ─── Tool Bar ─────────────────────────────────────────────────────────────────

class _ToolBar extends StatelessWidget {
  final _Tool selected;
  final Color accent;
  final void Function(_Tool) onSelect;

  const _ToolBar({
    required this.selected,
    required this.accent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolBtn(icon: Icons.edit_rounded, label: 'Kecil', tool: _Tool.brushSmall, selected: selected, accent: accent, onTap: onSelect),
          _ToolBtn(icon: Icons.brush_rounded, label: 'Besar', tool: _Tool.brushLarge, selected: selected, accent: accent, onTap: onSelect),
          _ToolBtn(icon: Icons.format_color_fill_rounded, label: 'Isi', tool: _Tool.fill, selected: selected, accent: accent, onTap: onSelect),
          _ToolBtn(icon: Icons.auto_fix_normal_rounded, label: 'Hapus', tool: _Tool.eraser, selected: selected, accent: Colors.grey.shade600, onTap: onSelect),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final _Tool tool;
  final _Tool selected;
  final Color accent;
  final void Function(_Tool) onTap;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.tool,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = tool == selected;
    return GestureDetector(
      onTap: () => onTap(tool),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? accent : Colors.grey[500], size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? accent : Colors.grey[500],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Color Palette ────────────────────────────────────────────────────────────

class _ColorPalette extends StatelessWidget {
  final List<Color> palette;
  final Color selected;
  final void Function(Color) onSelect;

  const _ColorPalette({
    required this.palette,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        itemCount: palette.length,
        itemBuilder: (_, i) {
          final c = palette[i];
          final isSelected = selected == c;
          return GestureDetector(
            onTap: () => onSelect(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isSelected ? 38 : 30,
              height: isSelected ? 38 : 30,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : Border.all(color: Colors.transparent),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: c.withValues(alpha: 0.55),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Celebration Overlay ──────────────────────────────────────────────────────

class _CelebrationOverlay extends StatelessWidget {
  final String letter;
  final String name;
  final Animation<double> scaleAnim;
  final Animation<double> opacityAnim;

  const _CelebrationOverlay({
    required this.letter,
    required this.name,
    required this.scaleAnim,
    required this.opacityAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: AnimatedBuilder(
              animation: scaleAnim,
              builder: (_, __) => Opacity(
                opacity: opacityAnim.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scaleAnim.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 30,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎨', style: TextStyle(fontSize: 52)),
                        const SizedBox(height: 8),
                        const Text(
                          'Bagus Sekali!',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 88,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Custom Painter ───────────────────────────────────────────────────────────

class _ColoringPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;
  final bool isEraser;
  final Color bgColor;
  final String arabicChar;

  const _ColoringPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
    required this.isEraser,
    required this.bgColor,
    required this.arabicChar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = bgColor,
    );

    // 2. Completed strokes
    for (final s in strokes) {
      _drawPath(canvas, s.points, s.isEraser ? bgColor : s.color, s.width);
    }

    // 3. Current stroke in progress
    if (currentPoints.isNotEmpty) {
      _drawPath(canvas, currentPoints,
          isEraser ? bgColor : currentColor, currentWidth);
    }

    // 4. Letter guide always on top (faint — 10% opacity)
    _drawGuide(canvas, size);
  }

  void _drawPath(
      Canvas canvas, List<Offset> pts, Color color, double width) {
    if (pts.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (pts.length == 1) {
      canvas.drawCircle(pts.first, width / 2, Paint()..color = color);
      return;
    }

    // Smooth quadratic bezier for soft brush strokes
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length - 1; i++) {
      final mid = Offset(
        (pts[i].dx + pts[i + 1].dx) / 2,
        (pts[i].dy + pts[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(path, paint);
  }

  void _drawGuide(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: arabicChar,
        style: TextStyle(
          fontSize: size.width * 0.72,
          // Very faint — just enough to guide without overwhelming
          color: const Color(0x18000000),
          fontWeight: FontWeight.bold,
          height: 1.15,
        ),
      ),
      textDirection: TextDirection.rtl,
    );
    textPainter.layout(maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_ColoringPainter old) =>
      old.strokes.length != strokes.length ||
      old.currentPoints.length != currentPoints.length ||
      old.bgColor != bgColor ||
      old.isEraser != isEraser;
}
