class AppConstants {
  // AdMob Test IDs — ganti dengan ID production sebelum publish
  static const String bannerAdId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdId = 'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedAdId = 'ca-app-pub-3940256099942544/5224354917';

  // IAP Product IDs
  static const String iapRemoveAds = 'remove_ads';
  static const String iapPremiumPlus = 'premium_plus';
  static const String iapBundleAll = 'bundle_anak_ceria';

  // Game settings
  static const int freeJilidCount = 2;
  static const int quizFreeCount = 10;
  static const int interstitialIntervalMinutes = 3;
  static const int rewardedBeforePremiumPrompt = 3;

  // Huruf hijaiyah
  static const List<String> hijaiyahNames = [
    'Alif', 'Ba', 'Ta', 'Tsa', 'Jim', 'Ha', 'Kho',
    'Dal', 'Dzal', 'Ro', 'Zay', 'Sin', 'Syin', 'Shod',
    'Dhod', 'Tho', 'Zho', 'Ain', 'Ghin', 'Fa', 'Qof',
    'Kaf', 'Lam', 'Mim', 'Nun', 'Haa', 'Waw', 'Ya',
  ];

  static const List<String> hijaiyahArabic = [
    'ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ',
    'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص',
    'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق',
    'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي',
  ];

  // Warna untuk huruf hijaiyah di menu
  static const List<int> hijaiyahColors = [
    0xFF4CAF50, 0xFF2196F3, 0xFFFF9800, 0xFFE91E63,
    0xFF9C27B0, 0xFF00BCD4, 0xFFFF5722, 0xFF3F51B5,
    0xFF8BC34A, 0xFFFF4081, 0xFF00897B, 0xFFFFEB3B,
    0xFF673AB7, 0xFFCDDC39, 0xFFF44336, 0xFF03A9F4,
    0xFFFF6F00, 0xFF7B1FA2, 0xFF009688, 0xFFE040FB,
    0xFF1565C0, 0xFFD50000, 0xFF2E7D32, 0xFFFF6D00,
    0xFF6A1B9A, 0xFF0097A7, 0xFFD84315, 0xFF1976D2,
  ];
}