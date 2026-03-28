import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/jilid_data.dart';
import '../../models/jilid_page.dart';
import '../../providers/progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/ad_service.dart';
import '../../services/audio_service.dart';

/// Halaman belajar huruf hijaiyah per jilid.
///
/// Menampilkan satu huruf besar di tengah layar dengan tombol speaker,
/// navigasi prev/next, dan progress bar. Setiap huruf yang didengar
/// pertama kali otomatis ditandai sudah dipelajari + animasi bintang.
class LearnScreen extends StatefulWidget {
  final int jilidIndex;
  final int initialPage;

  const LearnScreen({
    super.key,
    required this.jilidIndex,
    this.initialPage = 0,
  });

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen>
    with TickerProviderStateMixin {
  late final List<JilidPage> _pages;
  late int _currentIndex;
  final AudioService _audio = AudioService();

  // ── Animasi huruf (scale + fade saat pindah halaman) ──────────────────────
  late final AnimationController _letterCtrl;
  late final Animation<double> _letterScale;
  late final Animation<double> _letterOpacity;

  // ── Animasi tombol speaker (tekan = sedikit mengecil) ─────────────────────
  late final AnimationController _speakerCtrl;
  late final Animation<double> _speakerScale;

  // ── Animasi reward bintang (muncul + melayang ke atas) ────────────────────
  late final AnimationController _starCtrl;
  late final Animation<double> _starOpacity;
  late final Animation<Offset> _starSlide;
  bool _showStar = false;

  @override
  void initState() {
    super.initState();
    _pages = JilidData.getPages(widget.jilidIndex);
    _currentIndex = widget.initialPage.clamp(0, _pages.length - 1);

    // Huruf: muncul dengan efek bouncing dari skala kecil
    _letterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _letterScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _letterCtrl, curve: Curves.elasticOut),
    );
    _letterOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _letterCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _letterCtrl.forward();

    // Speaker: sedikit mengecil saat ditekan
    _speakerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _speakerScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _speakerCtrl, curve: Curves.easeOut),
    );

    // Bintang: fade in → melayang ke atas → fade out
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _starOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_starCtrl);
    _starSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -3.5),
    ).animate(CurvedAnimation(parent: _starCtrl, curve: Curves.easeOut));
    _starCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _starCtrl.reset();
        if (mounted) setState(() => _showStar = false);
      }
    });
  }

  @override
  void dispose() {
    _letterCtrl.dispose();
    _speakerCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  // ── Kembali + Interstitial ────────────────────────────────────────────────

  /// Tampilkan interstitial (jika kondisi terpenuhi) lalu kembali.
  /// Dipanggil oleh PopScope — menangani baik tombol back di AppBar
  /// maupun gesture/tombol back sistem Android.
  Future<void> _handlePop() async {
    final isPremium =
        context.read<SettingsProvider>().isPremium;
    await AdService().showInterstitialIfReady(isPremium: isPremium);
    if (mounted) Navigator.of(context).pop();
  }

  // ── Navigasi ────────────────────────────────────────────────────────────────

  void _goTo(int index) {
    if (index < 0 || index >= _pages.length) return;
    setState(() => _currentIndex = index);
    _letterCtrl.forward(from: 0);
  }

  // ── Interaksi Speaker ────────────────────────────────────────────────────────

  Future<void> _onSpeakerTap() async {
    // Animasi tekan
    await _speakerCtrl.forward();
    await _speakerCtrl.reverse();

    // Putar audio huruf — TTS Arabic jika file MP3 belum ada
    _audio.playHuruf(
      _pages[_currentIndex].audioPath,
      arabicText: _pages[_currentIndex].arabic,
      letterName: _pages[_currentIndex].name,
    );

    // Tandai dipelajari → tampilkan bintang jika baru pertama kali
    if (!mounted) return;
    final isNew = await context
        .read<ProgressProvider>()
        .markLearned(widget.jilidIndex, _currentIndex);
    if (isNew && mounted) {
      _audio.playSfx(SfxType.star);
      setState(() => _showStar = true);
      _starCtrl.forward();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.jilidColors[widget.jilidIndex];
    final page = _pages[_currentIndex];
    final progress = (_currentIndex + 1) / _pages.length;

    return PopScope(
      // canPop: false agar kita bisa intercept dan tampilkan interstitial
      // sebelum benar-benar keluar dari halaman belajar.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _AppBar(
        jilidIndex: widget.jilidIndex,
        color: color,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _ProgressSection(
                current: _currentIndex,
                total: _pages.length,
                progress: progress,
                color: color,
                jilidIndex: widget.jilidIndex,
              ),
              Expanded(
                child: _LetterSection(
                  page: page,
                  color: color,
                  jilidIndex: widget.jilidIndex,
                  pageIndex: _currentIndex,
                  letterScale: _letterScale,
                  letterOpacity: _letterOpacity,
                  speakerScale: _speakerScale,
                  onSpeakerTap: _onSpeakerTap,
                ),
              ),
              _NavBar(
                currentIndex: _currentIndex,
                total: _pages.length,
                color: color,
                onPrev: () => _goTo(_currentIndex - 1),
                onNext: () => _goTo(_currentIndex + 1),
              ),
            ],
          ),
          // Overlay animasi bintang reward
          if (_showStar)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: SlideTransition(
                    position: _starSlide,
                    child: FadeTransition(
                      opacity: _starOpacity,
                      child: const Text(
                        '⭐ +1',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.premium,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),    // end Scaffold
    );    // end PopScope
  }
}

// ── AppBar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final int jilidIndex;
  final Color color;

  const _AppBar({required this.jilidIndex, required this.color});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Jilid ${jilidIndex + 1}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      centerTitle: true,
      actions: [
        Consumer<ProgressProvider>(
          builder: (_, prov, __) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: AppTheme.premium, size: 22),
                const SizedBox(width: 4),
                Text(
                  '${prov.totalStars}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Progress Section ─────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final int current;
  final int total;
  final double progress;
  final Color color;
  final int jilidIndex;

  const _ProgressSection({
    required this.current,
    required this.total,
    required this.progress,
    required this.color,
    required this.jilidIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${current + 1} / $total',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Consumer<ProgressProvider>(
                builder: (_, prov, __) {
                  final count = prov.learnedCount(jilidIndex);
                  return Text(
                    '$count dipelajari',
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Letter Section ───────────────────────────────────────────────────────────

class _LetterSection extends StatelessWidget {
  final JilidPage page;
  final Color color;
  final int jilidIndex;
  final int pageIndex;
  final Animation<double> letterScale;
  final Animation<double> letterOpacity;
  final Animation<double> speakerScale;
  final VoidCallback onSpeakerTap;

  const _LetterSection({
    required this.page,
    required this.color,
    required this.jilidIndex,
    required this.pageIndex,
    required this.letterScale,
    required this.letterOpacity,
    required this.speakerScale,
    required this.onSpeakerTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // ── Huruf Arab besar ──────────────────────────────────────────
            AnimatedBuilder(
              animation: letterScale,
              builder: (_, __) => Opacity(
                opacity: letterOpacity.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: letterScale.value,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.09),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.35),
                        width: 3,
                      ),
                    ),
                    // Padding dalam circle agar teks tidak menyentuh tepi
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Center(
                        child: AutoSizeText(
                          page.arabic,
                          style: TextStyle(
                            fontSize: 108,
                            fontWeight: FontWeight.bold,
                            color: color,
                            height: 1.1,
                          ),
                          // Skala turun otomatis jika teks terlalu panjang
                          minFontSize: 26,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          wrapWords: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Nama huruf ────────────────────────────────────────────────
            AnimatedBuilder(
              animation: letterOpacity,
              builder: (_, __) => Opacity(
                opacity: letterOpacity.value.clamp(0.0, 1.0),
                child: Text(
                  page.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // ── Hint harakat ──────────────────────────────────────────────
            if (page.hint != null) ...[
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: letterOpacity,
                builder: (_, __) => Opacity(
                  opacity: letterOpacity.value.clamp(0.0, 1.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      page.hint!,
                      style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 36),

            // ── Tombol speaker ────────────────────────────────────────────
            AnimatedBuilder(
              animation: speakerScale,
              builder: (_, __) => Transform.scale(
                scale: speakerScale.value,
                child: GestureDetector(
                  onTap: onSpeakerTap,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Tap untuk dengar pelafalan',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),

            const SizedBox(height: 16),

            // ── Badge sudah dipelajari ────────────────────────────────────
            Consumer<ProgressProvider>(
              builder: (_, prov, __) {
                final learned = prov.isLearned(jilidIndex, pageIndex);
                return AnimatedOpacity(
                  opacity: learned ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppTheme.correct, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Sudah dipelajari!',
                        style: TextStyle(
                          color: AppTheme.correct,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Navigation Bar ───────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final int currentIndex;
  final int total;
  final Color color;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _NavBar({
    required this.currentIndex,
    required this.total,
    required this.color,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < total - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            label: 'Sebelumnya',
            icon: Icons.arrow_back_ios_rounded,
            color: color,
            enabled: hasPrev,
            onTap: onPrev,
            isNext: false,
          ),
          _PageIndicator(
            current: currentIndex,
            total: total,
            color: color,
          ),
          _NavButton(
            label: 'Berikutnya',
            icon: Icons.arrow_forward_ios_rounded,
            color: color,
            enabled: hasNext,
            onTap: onNext,
            isNext: true,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  final bool isNext;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.25,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: enabled ? color.withValues(alpha: 0.12) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: isNext
                ? [
                    Text(label,
                        style: TextStyle(
                            color: enabled ? color : Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(width: 4),
                    Icon(icon,
                        color: enabled ? color : Colors.grey, size: 15),
                  ]
                : [
                    Icon(icon,
                        color: enabled ? color : Colors.grey, size: 15),
                    const SizedBox(width: 4),
                    Text(label,
                        style: TextStyle(
                            color: enabled ? color : Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
          ),
        ),
      ),
    );
  }
}

/// Indikator posisi: titik-titik kecil (≤7 halaman) atau teks "x / total"
class _PageIndicator extends StatelessWidget {
  final int current;
  final int total;
  final Color color;

  const _PageIndicator({
    required this.current,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (total <= 7) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          total,
          (i) => _Dot(isActive: i == current, color: color),
        ),
      );
    }
    // Halaman terlalu banyak → tampilkan teks
    return Text(
      '${current + 1} / $total',
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool isActive;
  final Color color;

  const _Dot({required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: isActive ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? color : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
