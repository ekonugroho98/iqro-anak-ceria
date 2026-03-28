import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../providers/progress_provider.dart';
import '../../services/audio_service.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class _SeePickQuestion {
  /// Index di AppConstants.hijaiyah* (0–27) untuk jawaban benar
  final int correctIndex;

  /// 4 index pilihan (sudah diacak, termasuk jawaban benar)
  final List<int> choices;

  const _SeePickQuestion({
    required this.correctIndex,
    required this.choices,
  });
}

enum _SeePickState { playing, correct, wrong, finished }

// ─── Screen ───────────────────────────────────────────────────────────────────

class QuizSeePickScreen extends StatefulWidget {
  const QuizSeePickScreen({super.key});

  @override
  State<QuizSeePickScreen> createState() => _QuizSeePickState();
}

class _QuizSeePickState extends State<QuizSeePickScreen>
    with TickerProviderStateMixin {
  static const _totalQuestions = 10;

  final _audio = AudioService();
  late List<_SeePickQuestion> _questions;

  int _current = 0;
  int _score = 0;
  int _selected = -1;
  _SeePickState _state = _SeePickState.playing;
  Timer? _nextTimer;

  // Animasi bouncing pada kartu jawaban benar
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceScale;

  // Animasi shake pada kartu jawaban salah
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  // Warna kartu pilihan: hijau, biru, oranye, ungu
  static const _cardColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
  ];

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions();

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.95), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -7.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: 0.0), weight: 10),
    ]).animate(_shakeCtrl);

    // Putar audio saat soal pertama muncul
    WidgetsBinding.instance.addPostFrameCallback((_) => _playQuestion());
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    _bounceCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Logic ─────────────────────────────────────────────────────────────────

  List<_SeePickQuestion> _generateQuestions() {
    final rng = Random();
    final indices = List.generate(28, (i) => i)..shuffle(rng);

    return List.generate(_totalQuestions, (i) {
      final correct = indices[i % 28];
      final pool = [...indices]..remove(correct)..shuffle(rng);
      final choices = [correct, pool[0], pool[1], pool[2]]..shuffle(rng);
      return _SeePickQuestion(correctIndex: correct, choices: choices);
    });
  }

  void _playQuestion() {
    final idx = _questions[_current].correctIndex;
    final name = AppConstants.hijaiyahNames[idx];
    _audio.playHuruf(
      'assets/audio/hijaiyah/${name.toLowerCase().replaceAll("'", "")}.mp3',
      arabicText: AppConstants.hijaiyahArabic[idx],
      letterName: name,
    );
  }

  void _onChoiceTap(int choiceIndex) {
    if (_state != _SeePickState.playing) return;

    final q = _questions[_current];
    final isCorrect = q.choices[choiceIndex] == q.correctIndex;

    setState(() {
      _selected = choiceIndex;
      _state = isCorrect ? _SeePickState.correct : _SeePickState.wrong;
      if (isCorrect) _score++;
    });

    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
      _audio.playSfx(SfxType.correct);
      _audio.playSfx(SfxType.star);
    } else {
      _shakeCtrl.forward(from: 0);
      _audio.playSfx(SfxType.incorrect);
    }

    final delay = isCorrect ? 1500 : 2200;
    _nextTimer = Timer(Duration(milliseconds: delay), _nextQuestion);
  }

  void _nextQuestion() {
    _nextTimer?.cancel();
    final nextIndex = _current + 1;

    if (nextIndex >= _totalQuestions) {
      context.read<ProgressProvider>().addStars(_score);
      setState(() => _state = _SeePickState.finished);
    } else {
      setState(() {
        _current = nextIndex;
        _selected = -1;
        _state = _SeePickState.playing;
      });
      _bounceCtrl.reset();
      _shakeCtrl.reset();
      _playQuestion();
    }
  }

  void _restart() {
    _nextTimer?.cancel();
    setState(() {
      _questions = _generateQuestions();
      _current = 0;
      _score = 0;
      _selected = -1;
      _state = _SeePickState.playing;
    });
    _bounceCtrl.reset();
    _shakeCtrl.reset();
    _playQuestion();
  }

  int get _earnedStars {
    if (_score >= 8) return 3;
    if (_score >= 5) return 2;
    return 1;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_state == _SeePickState.finished) return _buildResult();
    return _buildQuiz();
  }

  Widget _buildQuiz() {
    final q = _questions[_current];
    final isAnswered =
        _state == _SeePickState.correct || _state == _SeePickState.wrong;

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
          'Lihat & Pilih Suara',
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
            // ── Progress bar ────────────────────────────────────────────────
            _SeePickProgress(current: _current, total: _totalQuestions),
            const SizedBox(height: 20),

            // ── Kartu soal ──────────────────────────────────────────────────
            _SeePickQuestionCard(
              arabicLetter: AppConstants.hijaiyahArabic[q.correctIndex],
              onSpeakerTap: _playQuestion,
            ),
            const SizedBox(height: 24),

            // ── Grid 4 pilihan ──────────────────────────────────────────────
            Expanded(
              child: _SeePickChoiceGrid(
                choices: q.choices,
                correctIndex: q.correctIndex,
                selected: _selected,
                isAnswered: isAnswered,
                cardColors: _cardColors,
                bounceScale: _bounceScale,
                shakeAnim: _shakeAnim,
                onTap: _onChoiceTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final stars = _earnedStars;
    final pct = (_score / _totalQuestions * 100).round();

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
                '$_score / $_totalQuestions soal benar  ($pct%)',
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

// ─── Progress Bar ─────────────────────────────────────────────────────────────

class _SeePickProgress extends StatelessWidget {
  final int current;
  final int total;

  const _SeePickProgress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Soal ${current + 1} dari $total',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${((current + 1) / total * 100).round()}%',
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
            value: (current + 1) / total,
            backgroundColor: Colors.grey[200],
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// ─── Question Card ────────────────────────────────────────────────────────────

class _SeePickQuestionCard extends StatelessWidget {
  final String arabicLetter;
  final VoidCallback onSpeakerTap;

  const _SeePickQuestionCard({
    required this.arabicLetter,
    required this.onSpeakerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Huruf apa ini?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Huruf Arab besar
          Text(
            arabicLetter,
            style: const TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.1,
            ),
            textDirection: TextDirection.rtl,
          ),

          const SizedBox(height: 8),

          // Tombol dengar ulang
          GestureDetector(
            onTap: onSpeakerTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up_rounded,
                      size: 18, color: AppTheme.primary),
                  SizedBox(width: 6),
                  Text(
                    'Tap untuk dengar ulang',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Choice Grid ──────────────────────────────────────────────────────────────

class _SeePickChoiceGrid extends StatelessWidget {
  final List<int> choices;
  final int correctIndex;
  final int selected;
  final bool isAnswered;
  final List<Color> cardColors;
  final Animation<double> bounceScale;
  final Animation<double> shakeAnim;
  final void Function(int) onTap;

  const _SeePickChoiceGrid({
    required this.choices,
    required this.correctIndex,
    required this.selected,
    required this.isAnswered,
    required this.cardColors,
    required this.bounceScale,
    required this.shakeAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildCard(0)),
              const SizedBox(width: 14),
              Expanded(child: _buildCard(1)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildCard(2)),
              const SizedBox(width: 14),
              Expanded(child: _buildCard(3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(int choiceIndex) {
    final letterIndex = choices[choiceIndex];
    final isCorrect = letterIndex == correctIndex;
    final isSelected = selected == choiceIndex;

    Color cardColor = cardColors[choiceIndex];
    IconData? badge;

    if (isAnswered) {
      if (isCorrect) {
        cardColor = AppTheme.correct;
        badge = Icons.check_circle_rounded;
      } else if (isSelected) {
        cardColor = AppTheme.incorrect;
        badge = Icons.cancel_rounded;
      } else {
        cardColor = cardColor.withValues(alpha: 0.35);
      }
    }

    Widget card = GestureDetector(
      onTap: () => onTap(choiceIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isAnswered && !isCorrect && !isSelected
              ? []
              : [
                  BoxShadow(
                    color: cardColor.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -12,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Text(
                AppConstants.hijaiyahNames[letterIndex],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isAnswered && !isCorrect && !isSelected
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (badge != null)
              Positioned(
                top: 10,
                right: 10,
                child: Icon(badge, color: Colors.white, size: 24),
              ),
          ],
        ),
      ),
    );

    if (isAnswered && isCorrect) {
      card = AnimatedBuilder(
        animation: bounceScale,
        builder: (_, child) =>
            Transform.scale(scale: bounceScale.value, child: child),
        child: card,
      );
    }

    if (isAnswered && isSelected && !isCorrect) {
      card = AnimatedBuilder(
        animation: shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(shakeAnim.value, 0),
          child: child,
        ),
        child: card,
      );
    }

    return card;
  }
}
