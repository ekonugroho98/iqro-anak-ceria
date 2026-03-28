/// Data satu halaman dalam jilid Iqro
class JilidPage {
  final String arabic;    // Karakter Arab yang ditampilkan layar
  final String name;      // Nama huruf dalam bahasa Indonesia
  final String audioPath; // Path relatif dari assets/ (contoh: audio/hijaiyah/alif.mp3)
  final String? hint;     // Petunjuk harakat / pengucapan (opsional)

  const JilidPage({
    required this.arabic,
    required this.name,
    required this.audioPath,
    this.hint,
  });
}
