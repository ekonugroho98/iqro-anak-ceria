import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/jilid_data.dart';
import '../../providers/progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/premium/premium_screen.dart';
import '../../services/ad_service.dart';
import '../../widgets/common/parental_gate_dialog.dart';
import 'learn_screen.dart';

class JilidSelectScreen extends StatelessWidget {
  const JilidSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pilih Jilid',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            final color = AppTheme.jilidColors[index];
            final totalPages = JilidData.getPages(index).length;

            // Gabung dua provider sekaligus agar rebuild efisien
            return Consumer2<ProgressProvider, SettingsProvider>(
              builder: (ctx, progress, settings, __) {
                final isLocked = !settings.isJilidUnlocked(index);
                final learned = progress.learnedCount(index);
                final pct = totalPages > 0 ? learned / totalPages : 0.0;

                return GestureDetector(
                  onTap: () => _onJilidTap(ctx, index, isLocked),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
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
                        // Dekorasi lingkaran latar
                        Positioned(
                          right: -16,
                          top: -16,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                        // Overlay kunci (semi-transparan)
                        if (isLocked)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),

                        // Konten utama
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Baris atas: judul + ikon kunci/play
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Jilid ${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.black
                                          .withValues(alpha: 0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isLocked
                                          ? Icons.lock_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(),

                              // Jumlah halaman
                              Text(
                                '$totalPages halaman',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.white.withValues(alpha: 0.85),
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: isLocked ? 0.0 : pct,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.3),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                  minHeight: 5,
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Label status
                              Text(
                                isLocked
                                    ? 'Terkunci 🔒'
                                    : learned == 0
                                        ? 'Mulai belajar!'
                                        : '$learned / $totalPages dipelajari',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _onJilidTap(BuildContext context, int index, bool isLocked) {
    if (isLocked) {
      _showLockedDialog(context, index);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LearnScreen(jilidIndex: index),
        ),
      );
    }
  }

  void _showLockedDialog(BuildContext context, int jilidIndex) {
    final color = AppTheme.jilidColors[jilidIndex];

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_rounded, color: color, size: 24),
            const SizedBox(width: 8),
            const Text('Jilid Terkunci'),
          ],
        ),
        content: Text(
          'Jilid ${jilidIndex + 1} belum dibuka.\n\n'
          'Tonton 1 video iklan untuk membuka jilid ini secara gratis, '
          'atau upgrade ke Premium untuk akses semua jilid sekaligus!',
        ),
        actions: [
          // Tombol batal
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Nanti'),
          ),

          // Tombol premium
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final allowed = await ParentalGateDialog.show(context);
              if (allowed && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                );
              }
            },
            icon: const Icon(Icons.star_rounded,
                color: AppTheme.premium, size: 16),
            label: const Text(
              'Premium',
              style: TextStyle(color: AppTheme.premium),
            ),
          ),

          // Tombol tonton iklan rewarded
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogCtx); // tutup dialog dulu

              // Tampilkan loading
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final earned = await AdService().showRewarded();

              // Tutup loading
              if (context.mounted) Navigator.of(context).pop();

              if (earned && context.mounted) {
                // Unlock jilid di SettingsProvider
                await context
                    .read<SettingsProvider>()
                    .unlockJilid(jilidIndex);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Jilid ${jilidIndex + 1} berhasil dibuka! 🎉'),
                      backgroundColor: color,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                  // Langsung masuk ke jilid yang baru dibuka
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LearnScreen(jilidIndex: jilidIndex),
                    ),
                  );
                }
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        'Iklan tidak tersedia, coba lagi sebentar.'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            icon: const Icon(Icons.play_circle_rounded, size: 18),
            label: const Text('Tonton Gratis'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
