import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../services/iap_service.dart';

/// Halaman pembelian paket premium.
///
/// Menggunakan [IapService] untuk transaksi nyata via Google Play.
/// Di emulator (tanpa Google Play Services), toko tidak tersedia dan
/// tombol beli akan disabled — ini behavior yang benar, bukan bug.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isLoading = false;
  List<ProductDetails> _products = [];

  @override
  void initState() {
    super.initState();

    // Set callback sebelum transaksi dimulai
    IapService().onPurchaseUpdated = _handlePurchaseSuccess;
    IapService().onPurchaseError = _handlePurchaseError;

    // Ambil produk dari cache (sudah di-query saat initialize())
    _loadProducts();
  }

  @override
  void dispose() {
    // Clear callback agar tidak ada dangling reference ke widget yang sudah unmounted
    IapService().onPurchaseUpdated = null;
    IapService().onPurchaseError = null;
    super.dispose();
  }

  // ─── Load Produk ─────────────────────────────────────────────────────────

  Future<void> _loadProducts() async {
    final products = await IapService().queryProducts();
    if (mounted) {
      setState(() => _products = products);
    }
  }

  /// Cari ProductDetails berdasarkan IAP ID. Null jika belum load / tidak ditemukan.
  ProductDetails? _findProduct(String iapId) {
    try {
      return _products.firstWhere((p) => p.id == iapId);
    } catch (_) {
      return null;
    }
  }

  // ─── Aksi Beli ───────────────────────────────────────────────────────────

  Future<void> _onBuy(String iapId) async {
    if (_isLoading) return;

    final product = _findProduct(iapId);
    if (product == null) {
      // Produk belum load dari Play Store — coba query ulang
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Menghubungi toko... Coba lagi dalam sebentar.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      await _loadProducts();
      return;
    }

    setState(() => _isLoading = true);
    await IapService().buyProduct(product);
    // Hasil datang via callback onPurchaseUpdated / onPurchaseError
  }

  // ─── Aksi Restore ────────────────────────────────────────────────────────

  Future<void> _onRestore() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    await IapService().restorePurchases();

    // Tunggu 5 detik — jika tidak ada callback masuk, berarti tidak ada pembelian
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;
    if (_isLoading) {
      // Tidak ada pembelian yang ditemukan
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tidak ada pembelian sebelumnya yang ditemukan.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ─── Handler Callback dari IapService ────────────────────────────────────

  Future<void> _handlePurchaseSuccess(PurchaseDetails details) async {
    if (!mounted) return;
    setState(() => _isLoading = false);

    final settings = context.read<SettingsProvider>();
    await settings.setPremium(true);

    if (!mounted) return;
    _showSuccessDialog();
  }

  void _handlePurchaseError(String message) {
    if (!mounted) return;
    setState(() => _isLoading = false);

    // String kosong = user membatalkan sendiri — tidak perlu tampilkan error
    if (message.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Dialog Sukses ────────────────────────────────────────────────────────

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.correct.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.correct,
                  size: 46,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Terima Kasih!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Premium sudah aktif.\nSelamat belajar tanpa gangguan!',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // tutup dialog sukses
                    Navigator.of(context).pop(); // kembali ke home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mulai Belajar!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isStoreAvailable = IapService().isAvailable;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.background,
          body: Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return CustomScrollView(
                slivers: [
                  // ── AppBar dengan gradien ────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 210,
                    pinned: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF00897B), Color(0xFF004D40)],
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 30),
                              Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.premium
                                        .withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  color: AppTheme.premium,
                                  size: 42,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Iqro Anak Ceria Premium',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Belajar tanpa batas, tanpa iklan',
                                style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Konten ──────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        children: [
                          // Banner toko tidak tersedia (emulator / no Play Services)
                          if (!isStoreAvailable) ...[
                            _StoreUnavailableBanner(),
                            const SizedBox(height: 16),
                          ],

                          // Badge premium aktif
                          if (settings.isPremium) ...[
                            _PremiumActiveCard(),
                            const SizedBox(height: 20),
                          ],

                          // ── Paket 1: Hapus Iklan ─────────────────────────
                          _PackageCard(
                            icon: Icons.do_not_disturb_rounded,
                            title: 'Hapus Iklan',
                            price: 'Rp 15.000',
                            priceUsd: '\$0.99',
                            livePrice: _findProduct(AppConstants.iapRemoveAds)
                                ?.price,
                            color: const Color(0xFF1E88E5),
                            benefits: const [
                              'Hapus semua banner iklan',
                              'Hapus iklan sela (interstitial)',
                              'Belajar tanpa gangguan',
                            ],
                            isActive: settings.isPremium,
                            isStoreAvailable: isStoreAvailable,
                            onBuy: () =>
                                _onBuy(AppConstants.iapRemoveAds),
                          ),

                          const SizedBox(height: 16),

                          // ── Paket 2: Premium Plus (terlaris) ─────────────
                          _PackageCard(
                            icon: Icons.workspace_premium_rounded,
                            title: 'Premium Plus',
                            price: 'Rp 29.000',
                            priceUsd: '\$1.99',
                            livePrice: _findProduct(AppConstants.iapPremiumPlus)
                                ?.price,
                            color: AppTheme.primary,
                            benefits: const [
                              'Semua manfaat Hapus Iklan',
                              'Buka semua 6 jilid Iqro',
                              'Semua pack warna mewarnai',
                              'Kuis tanpa batas soal',
                            ],
                            isBestValue: true,
                            isActive: settings.isPremium,
                            isStoreAvailable: isStoreAvailable,
                            onBuy: () =>
                                _onBuy(AppConstants.iapPremiumPlus),
                          ),

                          const SizedBox(height: 16),

                          // ── Paket 3: Bundel ──────────────────────────────
                          _PackageCard(
                            icon: Icons.apps_rounded,
                            title: 'Bundel Anak Ceria',
                            price: 'Rp 49.000',
                            priceUsd: '\$2.99',
                            livePrice: _findProduct(AppConstants.iapBundleAll)
                                ?.price,
                            color: AppTheme.jilid6,
                            benefits: const [
                              'Semua manfaat Premium Plus',
                              '6 Game Anak Ceria sekaligus',
                              'Hemat lebih dari 60%',
                              'Update konten gratis selamanya',
                            ],
                            isActive: settings.isPremium,
                            isStoreAvailable: isStoreAvailable,
                            onBuy: () =>
                                _onBuy(AppConstants.iapBundleAll),
                          ),

                          const SizedBox(height: 28),

                          // Tombol restore
                          OutlinedButton.icon(
                            onPressed: (!isStoreAvailable || _isLoading)
                                ? null
                                : _onRestore,
                            icon: const Icon(Icons.restore_rounded, size: 18),
                            label: const Text('Pulihkan Pembelian'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(color: Colors.grey[400]!),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Catatan hukum
                          Text(
                            'Pembelian ditagih ke akun Google Play.\n'
                            'Pembelian berlaku seumur hidup (tidak berlangganan).',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // ── Loading Overlay ────────────────────────────────────────────────
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.45),
            child: Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Memproses...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Jangan tutup aplikasi',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Widget Pembantu ──────────────────────────────────────────────────────────

/// Banner yang muncul saat Google Play Store tidak tersedia (emulator / offline).
class _StoreUnavailableBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.store_mall_directory_rounded,
              color: Colors.orange[700], size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Toko Google Play tidak tersedia.\n'
              'Pastikan perangkat terhubung ke internet dan memiliki Google Play Services.',
              style: TextStyle(fontSize: 12, color: Colors.orange[800]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumActiveCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF26A69A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Aktif!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Kamu menikmati semua fitur premium',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'AKTIF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String price;
  final String priceUsd;

  /// Harga live dari Google Play (null = belum load / Play Store tidak tersedia)
  final String? livePrice;

  final Color color;
  final List<String> benefits;
  final bool isBestValue;
  final bool isActive;
  final bool isStoreAvailable;
  final VoidCallback onBuy;

  const _PackageCard({
    required this.icon,
    required this.title,
    required this.price,
    required this.priceUsd,
    required this.color,
    required this.benefits,
    required this.isActive,
    required this.isStoreAvailable,
    required this.onBuy,
    this.livePrice,
    this.isBestValue = false,
  });

  @override
  Widget build(BuildContext context) {
    // Tampilkan harga live jika tersedia, fallback ke harga hardcoded
    final displayPrice = livePrice ?? price;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isBestValue ? color : Colors.grey[200]!,
              width: isBestValue ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isBestValue ? 0.18 : 0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ikon + nama + harga
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              displayPrice,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            // Tampilkan harga USD sebagai referensi hanya jika menggunakan harga hardcoded
                            if (livePrice == null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '($priceUsd)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Divider(color: Colors.grey[150]),
              const SizedBox(height: 10),

              // Manfaat
              ...benefits.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: color,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tombol
              SizedBox(
                width: double.infinity,
                child: isActive
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Sudah Aktif'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: isStoreAvailable ? onBuy : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isStoreAvailable
                              ? 'Beli — $displayPrice'
                              : 'Toko Tidak Tersedia',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),

        // Badge "TERLARIS"
        if (isBestValue)
          Positioned(
            top: -13,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'TERLARIS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
