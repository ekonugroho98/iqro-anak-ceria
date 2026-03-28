import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../providers/settings_provider.dart';
import '../widgets/ads/banner_ad_widget.dart';
import '../widgets/common/parental_gate_dialog.dart';
import 'iqro/jilid_select_screen.dart';
import 'coloring/letter_select_screen.dart';
import 'premium/premium_screen.dart';
import 'quiz/quiz_menu_screen.dart';
import 'settings/settings_screen.dart';
import 'cross_promo/cross_promo_screen.dart';
import 'songs/songs_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                    icon: Icons.settings_rounded,
                    color: Colors.grey,
                    onTap: () async {
                      // Parental gate wajib sebelum masuk pengaturan
                      final allowed =
                          await ParentalGateDialog.show(context);
                      if (allowed && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        );
                      }
                    },
                  ),
                  Column(
                    children: [
                      const Text(
                        'Iqro Anak Ceria',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Belajar mengaji yuk!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  _CircleButton(
                    icon: Icons.star_rounded,
                    color: AppTheme.premium,
                    onTap: () async {
                      // Parental gate sebelum halaman premium
                      final allowed =
                          await ParentalGateDialog.show(context);
                      if (allowed && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PremiumScreen()),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Maskot Alif
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Maskot placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'ا',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assalamu\'alaikum!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ayo belajar huruf hijaiyah hari ini!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Menu Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _MenuCard(
                      title: 'Belajar\nIqro',
                      subtitle: '6 Jilid',
                      icon: Icons.menu_book_rounded,
                      color: AppTheme.jilid1,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const JilidSelectScreen(),
                        ),
                      ),
                    ),
                    _MenuCard(
                      title: 'Mewarnai\nHijaiyah',
                      subtitle: '28 Huruf',
                      icon: Icons.brush_rounded,
                      color: AppTheme.jilid2,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LetterSelectScreen(),
                        ),
                      ),
                    ),
                    _MenuCard(
                      title: 'Kuis\nHijaiyah',
                      subtitle: '4 Mode',
                      icon: Icons.quiz_rounded,
                      color: AppTheme.jilid4,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QuizMenuScreen(),
                        ),
                      ),
                    ),
                    _MenuCard(
                      title: 'Lagu &\nNasyid',
                      subtitle: '5 Lagu',
                      icon: Icons.music_note_rounded,
                      color: AppTheme.jilid5,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SongsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Game lainnya button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CrossPromoScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.apps_rounded, size: 20),
                  label: const Text('Game Anak Ceria Lainnya'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
            ),

            // Banner AdMob — otomatis hilang jika premium aktif
            Consumer<SettingsProvider>(
              builder: (_, settings, __) {
                if (settings.isPremium) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 12),
                  child: BannerAdWidget(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// === Reusable Widgets ===

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background circle decoration
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -10,
              bottom: -10,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}