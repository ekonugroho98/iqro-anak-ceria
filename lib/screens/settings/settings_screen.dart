import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../premium/premium_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Audio ──────────────────────────────────────────────
              _buildSection('Audio', [
                SwitchListTile(
                  value: settings.musicOn,
                  onChanged: (_) => settings.toggleMusic(),
                  title: const Text('Musik Latar'),
                  secondary: _IconBox(
                    icon: Icons.music_note_rounded,
                    color: AppTheme.primary,
                  ),
                ),
                SwitchListTile(
                  value: settings.sfxOn,
                  onChanged: (_) => settings.toggleSfx(),
                  title: const Text('Efek Suara'),
                  secondary: _IconBox(
                    icon: Icons.volume_up_rounded,
                    color: AppTheme.primary,
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // ── Premium ────────────────────────────────────────────
              _buildSection('Premium', [
                if (settings.isPremium)
                  // Status aktif
                  ListTile(
                    leading: _IconBox(
                      icon: Icons.verified_rounded,
                      color: AppTheme.primary,
                    ),
                    title: const Text(
                      'Premium Aktif',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Semua fitur premium tersedia'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'AKTIF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  // Tombol beli premium
                  ListTile(
                    leading: _IconBox(
                      icon: Icons.star_rounded,
                      color: AppTheme.premium,
                    ),
                    title: const Text('Beli Premium'),
                    subtitle: const Text('Hapus iklan & buka semua konten'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PremiumScreen()),
                    ),
                  ),

                // Restore purchase
                ListTile(
                  leading: _IconBox(
                    icon: Icons.restore_rounded,
                    color: Colors.blue,
                  ),
                  title: const Text('Pulihkan Pembelian'),
                  subtitle: const Text('Kembalikan pembelian sebelumnya'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    // TODO: implementasi restore purchase via in_app_purchase
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Tidak ada pembelian yang ditemukan.'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                ),
              ]),

              const SizedBox(height: 20),

              // ── Tentang ────────────────────────────────────────────
              _buildSection('Tentang', [
                ListTile(
                  leading: _IconBox(
                    icon: Icons.info_outline_rounded,
                    color: AppTheme.primary,
                  ),
                  title: const Text('Iqro Anak Ceria'),
                  subtitle: const Text('Versi 1.0.0'),
                ),
              ]),

              const SizedBox(height: 12),

              // Catatan COPPA
              Center(
                child: Text(
                  'Aplikasi ini mematuhi kebijakan COPPA\n'
                  'dan Google Play Families Policy.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
