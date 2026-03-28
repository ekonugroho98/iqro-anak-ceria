import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

/// Data class satu game dalam portofolio Anak Ceria.
class _GameItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isCurrent;
  final String? playStoreUrl; // null = belum publish

  const _GameItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isCurrent = false,
    this.playStoreUrl, // ignore: unused_element_parameter
  });
}

/// Halaman cross-promosi yang menampilkan 6 game portofolio Anak Ceria.
///
/// Tap game yang belum publish → snackbar "Segera hadir!".
/// Tap game saat ini → tidak ada aksi.
class CrossPromoScreen extends StatelessWidget {
  const CrossPromoScreen({super.key});

  static const List<_GameItem> _games = [
    _GameItem(
      title: 'Iqro Anak Ceria',
      subtitle: 'Belajar huruf hijaiyah',
      icon: Icons.menu_book_rounded,
      color: AppTheme.primary,
      isCurrent: true,
      // TODO: Isi URL saat sudah publish ke Play Store
      // playStoreUrl: 'https://play.google.com/store/apps/details?id=com.anakceria.iqro_anak_ceria',
    ),
    _GameItem(
      title: 'Mewarnai Anak Ceria',
      subtitle: 'Mewarnai gambar lucu',
      icon: Icons.brush_rounded,
      color: Color(0xFF009688),
    ),
    _GameItem(
      title: 'Bubble Pop Ceria',
      subtitle: 'Pecahkan gelembung seru',
      icon: Icons.bubble_chart_rounded,
      color: Color(0xFF00BCD4),
    ),
    _GameItem(
      title: 'Suara Binatang Anak',
      subtitle: 'Kenali suara hewan',
      icon: Icons.pets_rounded,
      color: Color(0xFFFF9800),
    ),
    _GameItem(
      title: 'Puzzle Anak Cerdas',
      subtitle: 'Susun puzzle edukatif',
      icon: Icons.extension_rounded,
      color: Color(0xFF9C27B0),
    ),
    _GameItem(
      title: 'Tracing Anak Ceria',
      subtitle: 'Latihan menulis huruf',
      icon: Icons.draw_rounded,
      color: Color(0xFFE91E63),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Game Anak Ceria',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
          // Header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.12),
                  AppTheme.primary.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.apps_rounded,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dari Anak Ceria Studio',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF222222),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Game edukatif untuk anak Muslim',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Grid 2 kolom
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.88,
              ),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                return _GameCard(
                  game: _games[index],
                  onTap: () => _onGameTap(context, _games[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onGameTap(BuildContext context, _GameItem game) {
    if (game.isCurrent) return; // Sudah di sini, tidak perlu aksi

    if (game.playStoreUrl != null) {
      // TODO: Buka url_launcher ke Play Store saat sudah publish
      // launchUrl(Uri.parse(game.playStoreUrl!));
      return;
    }

    // Belum publish
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.schedule_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${game.title} — Segera hadir!',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: game.color,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Kartu Game ───────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  final _GameItem game;
  final VoidCallback onTap;

  const _GameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: game.isCurrent
                ? game.color
                : game.color.withValues(alpha: 0.2),
            width: game.isCurrent ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: game.color.withValues(alpha: game.isCurrent ? 0.2 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Konten utama
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ikon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: game.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(game.icon, color: game.color, size: 36),
                  ),

                  const SizedBox(height: 12),

                  // Judul
                  Text(
                    game.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: game.isCurrent
                          ? game.color
                          : const Color(0xFF333333),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Subtitle
                  Text(
                    game.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Badge "Kamu di sini" untuk game saat ini
            if (game.isCurrent)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: game.color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Kamu di sini',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),

            // Badge "SEGERA HADIR" untuk game belum publish
            if (!game.isCurrent && game.playStoreUrl == null)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: game.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: game.color.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'SEGERA HADIR',
                      style: TextStyle(
                        color: game.color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
