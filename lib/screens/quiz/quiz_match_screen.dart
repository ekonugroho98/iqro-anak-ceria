import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../providers/progress_provider.dart';
import '../../services/audio_service.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class QuizMatchScreen extends StatefulWidget {
  const QuizMatchScreen({super.key});

  @override
  State<QuizMatchScreen> createState() => _QuizMatchState();
}

class _QuizMatchState extends State<QuizMatchScreen>
    with TickerProviderStateMixin {
  static const _totalSets = 8;
  static const _pairsPerSet = 3;

  final _audio = AudioService();
  final _rng = Random();

  // State per set
  late List<int> _leftLetters; // 3 index huruf di kolom kiri
  late List<int> _rightLetters; // 3 index huruf di kolom kanan (shuffled)
  late Map<int, int> _rightToLeft; // rightSlot → leftSlot (untuk cek kecocokan)

  int? _selectedLeft; // slot kiri yang sedang dipilih (0-2)
  final Set<int> _matchedLeft = {};
  final Set<int> _matchedRight = {};
  int? _wrongRight; // slot kanan yang baru saja salah (shake)

  int _currentSet = 0;
  int _score = 0;
  bool _finished = false;

  // Animasi shake untuk jawaban salah (kanan)
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 10),
    ]).animate(_shakeCtrl);

    _generateSet();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Logic ─────────────────────────────────────────────────────────────────

  void _generateSet() {
    // Pilih 3 huruf acak unik
    final all = List.generate(28, (i) => i)..shuffle(_rng);
    _leftLetters = all.take(_pairsPerSet).toList();

    // Kanan = urutan acak dari kiri
    final rightOrder = List.of(_leftLetters)..shuffle(_rng);
    _rightLetters = rightOrder;

    // Map: posisi kanan → posisi kiri
    _rightToLeft = {};
    for (int r = 0; r < _pairsPerSet; r++) {
      final leftSlot = _leftLetters.indexOf(_rightLetters[r]);
      _rightToLeft[r] = leftSlot;
    }

    _selectedLeft = null;
    _matchedLeft.clear();
    _matchedRight.clear();
    _wrongRight = null;
  }

  void _onLeftTap(int leftSlot) {
    if (_matchedLeft.contains(leftSlot)) return;
    setState(() => _selectedLeft = leftSlot);
    _audio.playSfx(SfxType.tap);
  }

  void _onRightTap(int rightSlot) {
    if (_matchedRight.contains(rightSlot)) return;
    if (_selectedLeft == null) return;

    final expectedLeft = _rightToLeft[rightSlot];

    if (expectedLeft == _selectedLeft) {
      // Benar
      setState(() {
        _matchedLeft.add(_selectedLeft!);
        _matchedRight.add(rightSlot);
        _selectedLeft = null;
      });
      _audio.playSfx(SfxType.correct);

      // Cek apakah semua pasangan sudah cocok
      if (_matchedLeft.length == _pairsPerSet) {
        setState(() => _score++);
        _audio.playSfx(SfxType.star);

        // Lanjut ke set berikutnya setelah 1 detik
        Timer(const Duration(milliseconds: 1000), () {
          final nextSet = _currentSet + 1;
          if (nextSet >= _totalSets) {
            context.read<ProgressProvider>().addStars(_score);
            setState(() => _finished = true);
          } else {
            setState(() {
              _currentSet = nextSet;
              _generateSet();
            });
          }
        });
      }
    } else {
      // Salah
      setState(() {
        _wrongRight = rightSlot;
        _selectedLeft = null;
      });
      _audio.playSfx(SfxType.incorrect);
      _shakeCtrl.forward(from: 0);

      Timer(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _wrongRight = null);
          _shakeCtrl.reset();
        }
      });
    }
  }

  void _restart() {
    setState(() {
      _currentSet = 0;
      _score = 0;
      _finished = false;
      _generateSet();
    });
  }

  int get _earnedStars {
    if (_score >= 7) return 3;
    if (_score >= 4) return 2;
    return 1;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_finished) return _buildResult();
    return _buildQuiz();
  }

  Widget _buildQuiz() {
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
          'Pasangkan',
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          children: [
            // ── Header set + progress ────────────────────────────────────────
            Text(
              'Set ${_currentSet + 1} dari $_totalSets',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_currentSet + 1) / _totalSets,
                backgroundColor: Colors.grey[200],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),

            // ── Instruksi ────────────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tap huruf di kiri, lalu namanya di kanan!',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),

            // ── Pasangan kiri & kanan ────────────────────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_pairsPerSet, (i) {
                  return _buildPairRow(i);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPairRow(int rowIndex) {
    return Row(
      children: [
        // Kolom kiri: kartu huruf Arab
        Expanded(child: _buildLeftCard(rowIndex)),
        const SizedBox(width: 24),
        // Kolom kanan: kartu nama huruf
        Expanded(child: _buildRightCard(rowIndex)),
      ],
    );
  }

  Widget _buildLeftCard(int leftSlot) {
    final letterIndex = _leftLetters[leftSlot];
    final isSelected = _selectedLeft == leftSlot;
    final isMatched = _matchedLeft.contains(leftSlot);
    final color = Color(AppConstants.hijaiyahColors[letterIndex]);

    Color bgColor;
    if (isMatched) {
      bgColor = AppTheme.correct;
    } else if (isSelected) {
      bgColor = const Color(0xFF2196F3);
    } else {
      bgColor = color;
    }

    return GestureDetector(
      onTap: isMatched ? null : () => _onLeftTap(leftSlot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: isMatched ? bgColor.withValues(alpha: 0.7) : bgColor,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: isMatched
              ? []
              : [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: isMatched
              ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 36)
              : Text(
                  AppConstants.hijaiyahArabic[letterIndex],
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                  textDirection: TextDirection.rtl,
                ),
        ),
      ),
    );
  }

  Widget _buildRightCard(int rightSlot) {
    final letterIndex = _rightLetters[rightSlot];
    final isMatched = _matchedRight.contains(rightSlot);
    final isWrong = _wrongRight == rightSlot;

    Color bgColor;
    if (isMatched) {
      bgColor = AppTheme.correct;
    } else if (isWrong) {
      bgColor = AppTheme.incorrect;
    } else if (_selectedLeft != null) {
      bgColor = const Color(0xFFFFF9C4); // kuning muda — hint bisa dipilih
    } else {
      bgColor = Colors.white;
    }

    Widget card = GestureDetector(
      onTap: isMatched ? null : () => _onRightTap(rightSlot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMatched
                ? AppTheme.correct
                : isWrong
                    ? AppTheme.incorrect
                    : Colors.grey[300]!,
            width: isMatched || isWrong ? 2.5 : 1.5,
          ),
          boxShadow: isMatched || isWrong
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Center(
          child: isMatched
              ? const Icon(Icons.check_rounded,
                  color: AppTheme.correct, size: 32)
              : Text(
                  AppConstants.hijaiyahNames[letterIndex],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isWrong ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );

    // Animasi shake jika salah
    if (isWrong) {
      card = AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(_shakeAnim.value, 0),
          child: child,
        ),
        child: card,
      );
    }

    return card;
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
                _score >= 7 ? '🏆' : _score >= 4 ? '🎉' : '💪',
                style: const TextStyle(fontSize: 72),
              ),
              const SizedBox(height: 12),
              Text(
                _score >= 7
                    ? 'Luar Biasa!'
                    : _score >= 4
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
                '$_score / $_totalSets set berhasil dipasangkan',
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
