/// Model data progres belajar anak.
/// Disimpan ke SharedPreferences dalam format JSON.
class ProgressModel {
  // Key: jilidIndex (0-based), Value: set index halaman yang sudah dipelajari
  final Map<int, Set<int>> learnedPages;
  final int totalStars;

  const ProgressModel({
    required this.learnedPages,
    required this.totalStars,
  });

  factory ProgressModel.empty() => const ProgressModel(
        learnedPages: {},
        totalStars: 0,
      );

  bool isPageLearned(int jilidIndex, int pageIndex) =>
      learnedPages[jilidIndex]?.contains(pageIndex) ?? false;

  int learnedCount(int jilidIndex) =>
      learnedPages[jilidIndex]?.length ?? 0;

  ProgressModel copyWith({
    Map<int, Set<int>>? learnedPages,
    int? totalStars,
  }) =>
      ProgressModel(
        learnedPages: learnedPages ?? this.learnedPages,
        totalStars: totalStars ?? this.totalStars,
      );

  Map<String, dynamic> toJson() => {
        'learnedPages': learnedPages.map(
          (k, v) => MapEntry(k.toString(), v.toList()),
        ),
        'totalStars': totalStars,
      };

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['learnedPages'] as Map<String, dynamic>?) ?? {};
    return ProgressModel(
      learnedPages: raw.map(
        (k, v) => MapEntry(int.parse(k), Set<int>.from(v as List)),
      ),
      totalStars: (json['totalStars'] as int?) ?? 0,
    );
  }
}
