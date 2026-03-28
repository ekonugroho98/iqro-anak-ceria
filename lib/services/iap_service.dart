import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/app_constants.dart';

/// Service IAP (In-App Purchase) singleton untuk Google Play.
///
/// Pola identik dengan [AdService] — inisialisasi di main() sebelum runApp,
/// lalu PremiumScreen mengeset [onPurchaseUpdated] / [onPurchaseError]
/// sebelum memanggil [buyProduct] atau [restorePurchases].
///
/// ## Catatan Emulator
/// [InAppPurchase.isAvailable] mengembalikan `false` di emulator standar
/// karena tidak ada Google Play Services. [isAvailable] akan `false` dan
/// semua tombol beli akan disabled — ini behavior yang benar, bukan bug.
/// Untuk testing nyata butuh device fisik + akun tester di Play Console.
class IapService {
  static final IapService _instance = IapService._();
  factory IapService() => _instance;
  IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> _products = [];
  bool _isAvailable = false;

  List<ProductDetails> get products => List.unmodifiable(_products);
  bool get isAvailable => _isAvailable;

  /// Dipanggil oleh PremiumScreen di initState sebelum transaksi.
  /// Dicleared di dispose() agar tidak ada dangling reference.
  void Function(PurchaseDetails)? onPurchaseUpdated;

  /// Dipanggil dengan pesan error saat pembelian gagal.
  /// String kosong berarti user membatalkan sendiri (bukan error nyata).
  void Function(String)? onPurchaseError;

  // ID produk IAP yang didaftarkan di Google Play Console
  static const Set<String> _productIds = {
    AppConstants.iapRemoveAds,
    AppConstants.iapPremiumPlus,
    AppConstants.iapBundleAll,
  };

  // ─── Inisialisasi ──────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      debugPrint('[IAP] Google Play Store tidak tersedia');
      return;
    }

    // Mulai dengarkan stream pembelian (berlaku sepanjang lifetime app)
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object error) {
        debugPrint('[IAP] Stream error: $error');
      },
    );

    await queryProducts();
    debugPrint('[IAP] Initialized — ${_products.length} produk tersedia');
  }

  // ─── Query Produk ──────────────────────────────────────────────────────────

  /// Ambil info produk (harga, nama) dari Google Play.
  /// Harga disesuaikan otomatis dengan lokasi pengguna.
  Future<List<ProductDetails>> queryProducts() async {
    if (!_isAvailable) return [];
    try {
      final response = await _iap.queryProductDetails(_productIds);
      if (response.error != null) {
        debugPrint('[IAP] Query error: ${response.error}');
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[IAP] Produk tidak ditemukan: ${response.notFoundIDs}');
      }
      _products = response.productDetails;
      debugPrint('[IAP] Produk: ${_products.map((p) => '${p.id}=${p.price}').toList()}');
      return _products;
    } catch (e) {
      debugPrint('[IAP] queryProducts error: $e');
      return [];
    }
  }

  // ─── Beli Produk ───────────────────────────────────────────────────────────

  /// Mulai proses pembelian. Hasil datang via stream → [onPurchaseUpdated] / [onPurchaseError].
  Future<void> buyProduct(ProductDetails product) async {
    if (!_isAvailable) return;
    try {
      final param = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('[IAP] buyProduct error: $e');
      onPurchaseError?.call('Gagal memulai pembelian. Coba lagi.');
    }
  }

  // ─── Restore Pembelian ─────────────────────────────────────────────────────

  /// Pulihkan pembelian sebelumnya. Hasil datang via stream.
  /// Jika tidak ada pembelian, stream tidak mengirim item apapun.
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[IAP] restorePurchases error: $e');
      onPurchaseError?.call('Gagal memulihkan pembelian. Coba lagi.');
    }
  }

  // ─── Handler Stream ────────────────────────────────────────────────────────

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final details in purchases) {
      debugPrint('[IAP] Update: ${details.productID} → ${details.status}');

      switch (details.status) {
        case PurchaseStatus.pending:
          // Loading sudah ditampilkan di PremiumScreen — tidak perlu aksi
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Wajib acknowledge ke Google Play agar tidak auto-refund setelah 3 hari
          if (details.pendingCompletePurchase) {
            await _iap.completePurchase(details);
          }
          onPurchaseUpdated?.call(details);

        case PurchaseStatus.error:
          final msg = details.error?.message ?? 'Terjadi kesalahan saat pembelian.';
          debugPrint('[IAP] Error: $msg');
          onPurchaseError?.call(msg);

        case PurchaseStatus.canceled:
          // User membatalkan sendiri — kirim string kosong agar screen tahu
          // ini canceled (bukan error) dan tidak menampilkan pesan error
          onPurchaseError?.call('');
      }
    }
  }

  // ─── Dispose ───────────────────────────────────────────────────────────────

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
