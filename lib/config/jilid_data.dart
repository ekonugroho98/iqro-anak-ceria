import '../models/jilid_page.dart';
import 'app_constants.dart';

/// Konten setiap jilid Iqro.
///
/// Jilid 1 : 28 huruf hijaiyah + fathah (lengkap)
/// Jilid 2 : 28 huruf × 3 harakat (fathah, kasrah, dhammah)
/// Jilid 3 : 28 huruf × 3 tanwin (fathatain, kasratain, dhammatain)
/// Jilid 4 : 28 huruf × 3 mad (alif, ya, waw)
/// Jilid 5 : Sukun (28) + Tasydid (10) + Waqaf/kata contoh (10)
/// Jilid 6 : Kata dasar (12) + Frasa (8) + Ayat pendek (10)
class JilidData {
  JilidData._();

  static List<JilidPage> getPages(int jilidIndex) {
    switch (jilidIndex) {
      case 0:
        return _jilid1;
      case 1:
        return _jilid2;
      case 2:
        return _jilid3;
      case 3:
        return _jilid4;
      case 4:
        return _jilid5;
      case 5:
        return _jilid6;
      default:
        return [];
    }
  }

  // ─── Jilid 1 ────────────────────────────────────────────────────────────────
  // 28 huruf tunggal dengan harakat fathah
  static final List<JilidPage> _jilid1 = [
    for (int i = 0; i < AppConstants.hijaiyahNames.length; i++)
      JilidPage(
        // Huruf + fathah (U+064E)
        arabic: '${AppConstants.hijaiyahArabic[i]}\u064E',
        name: AppConstants.hijaiyahNames[i],
        audioPath:
            'audio/hijaiyah/${_slug(AppConstants.hijaiyahNames[i])}.m4a',
        hint: 'Fathah → dibaca "a"',
      ),
  ];

  // ─── Jilid 2 ────────────────────────────────────────────────────────────────
  // 10 huruf pertama × 3 harakat (placeholder — konten lengkap menyusul)
  static final List<JilidPage> _jilid2 = [
    for (int i = 0; i < 10; i++) ...[
      JilidPage(
        arabic: '${AppConstants.hijaiyahArabic[i]}\u064E', // fathah
        name: '${AppConstants.hijaiyahNames[i]} - Fathah',
        audioPath:
            'audio/hijaiyah/jilid2/${_slug(AppConstants.hijaiyahNames[i])}_fathah.mp3',
        hint: 'Fathah → "a"',
      ),
      JilidPage(
        arabic: '${AppConstants.hijaiyahArabic[i]}\u0650', // kasrah
        name: '${AppConstants.hijaiyahNames[i]} - Kasrah',
        audioPath:
            'audio/hijaiyah/jilid2/${_slug(AppConstants.hijaiyahNames[i])}_kasrah.mp3',
        hint: 'Kasrah → "i"',
      ),
      JilidPage(
        arabic: '${AppConstants.hijaiyahArabic[i]}\u064F', // dhammah
        name: '${AppConstants.hijaiyahNames[i]} - Dhammah',
        audioPath:
            'audio/hijaiyah/jilid2/${_slug(AppConstants.hijaiyahNames[i])}_dhammah.mp3',
        hint: 'Dhammah → "u"',
      ),
    ],
  ];

  // ─── Jilid 3 ────────────────────────────────────────────────────────────────
  // Tanwin — 28 huruf × 3 jenis tanwin = 84 halaman
  static final List<JilidPage> _jilid3 = [
    // Seksi 1: Fathatain (◌ً)
    for (int i = 0; i < AppConstants.hijaiyahNames.length; i++)
      JilidPage(
        arabic: '${AppConstants.hijaiyahArabic[i]}\u064B',
        name: '${AppConstants.hijaiyahNames[i]} - Fathatain',
        audioPath:
            'audio/hijaiyah/jilid3/${_slug(AppConstants.hijaiyahNames[i])}_fathatain.mp3',
        hint: 'Tanwin fathah → dibaca "an"',
      ),
    // Seksi 2: Kasratain (◌ٍ)
    for (int i = 0; i < AppConstants.hijaiyahNames.length; i++)
      JilidPage(
        arabic: '${AppConstants.hijaiyahArabic[i]}\u064D',
        name: '${AppConstants.hijaiyahNames[i]} - Kasratain',
        audioPath:
            'audio/hijaiyah/jilid3/${_slug(AppConstants.hijaiyahNames[i])}_kasratain.mp3',
        hint: 'Tanwin kasrah → dibaca "in"',
      ),
    // Seksi 3: Dhammatain (◌ٌ)
    for (int i = 0; i < AppConstants.hijaiyahNames.length; i++)
      JilidPage(
        arabic: '${AppConstants.hijaiyahArabic[i]}\u064C',
        name: '${AppConstants.hijaiyahNames[i]} - Dhammatain',
        audioPath:
            'audio/hijaiyah/jilid3/${_slug(AppConstants.hijaiyahNames[i])}_dhammatain.mp3',
        hint: 'Tanwin dhammah → dibaca "un"',
      ),
  ];

  // ─── Jilid 4 ────────────────────────────────────────────────────────────────
  // Mad/huruf panjang — 28 huruf × 3 jenis mad = 84 halaman
  static final List<JilidPage> _jilid4 = [
    // Seksi 1: Mad Alif — huruf + fathah + alif (ا)
    for (int i = 0; i < AppConstants.hijaiyahNames.length; i++)
      JilidPage(
        arabic: '${AppConstants.hijaiyahArabic[i]}\u064E\u0627',
        name: '${AppConstants.hijaiyahNames[i]} - Mad Alif',
        audioPath:
            'audio/hijaiyah/jilid4/${_slug(AppConstants.hijaiyahNames[i])}_mad_alif.mp3',
        hint: 'Mad alif → panjang 2 harakat, bunyi "aa"',
      ),
    // Seksi 2: Mad Ya — huruf + kasrah + ya (ي)
    for (int i = 0; i < AppConstants.hijaiyahNames.length; i++)
      JilidPage(
        arabic: '${AppConstants.hijaiyahArabic[i]}\u0650\u064A',
        name: '${AppConstants.hijaiyahNames[i]} - Mad Ya',
        audioPath:
            'audio/hijaiyah/jilid4/${_slug(AppConstants.hijaiyahNames[i])}_mad_ya.mp3',
        hint: 'Mad ya → panjang 2 harakat, bunyi "ii"',
      ),
    // Seksi 3: Mad Waw — huruf + dhammah + waw (و)
    for (int i = 0; i < AppConstants.hijaiyahNames.length; i++)
      JilidPage(
        arabic: '${AppConstants.hijaiyahArabic[i]}\u064F\u0648',
        name: '${AppConstants.hijaiyahNames[i]} - Mad Waw',
        audioPath:
            'audio/hijaiyah/jilid4/${_slug(AppConstants.hijaiyahNames[i])}_mad_waw.mp3',
        hint: 'Mad waw → panjang 2 harakat, bunyi "uu"',
      ),
  ];

  // ─── Jilid 5 ────────────────────────────────────────────────────────────────
  // Sukun, Tasydid, Tanda Baca — 48 halaman
  static final List<JilidPage> _jilid5 = [
    // Seksi 1: Sukun — 28 huruf + sukun (ْ)
    for (int i = 0; i < AppConstants.hijaiyahNames.length; i++)
      JilidPage(
        arabic: '${AppConstants.hijaiyahArabic[i]}\u0652',
        name: '${AppConstants.hijaiyahNames[i]} - Sukun',
        audioPath:
            'audio/hijaiyah/jilid5/${_slug(AppConstants.hijaiyahNames[i])}_sukun.mp3',
        hint: 'Sukun → huruf mati, tidak berbunyi vokal',
      ),

    // Seksi 2: Tasydid — 10 huruf umum (ba, ta, jim, dal, ra, sin, ain, fa, kaf, mim)
    // Indeks: ba=1, ta=2, jim=4, dal=7, ro=9, sin=11, ain=17, fa=19, kaf=21, mim=23
    for (final i in [1, 2, 4, 7, 9, 11, 17, 19, 21, 23])
      JilidPage(
        arabic: '${AppConstants.hijaiyahArabic[i]}\u0651\u064E',
        name: '${AppConstants.hijaiyahNames[i]} Tasydid',
        audioPath:
            'audio/hijaiyah/jilid5/${_slug(AppConstants.hijaiyahNames[i])}_tasydid.mp3',
        hint: 'Tasydid → huruf dobel, tekan lebih kuat',
      ),

    // Seksi 3: Waqaf / Kata contoh — 10 halaman
    const JilidPage(
      arabic: '\u0645\u064E\u0646\u0652',
      name: 'Man',
      audioPath: 'audio/hijaiyah/jilid5/man.mp3',
      hint: 'Contoh sukun di akhir kata: man',
    ),
    const JilidPage(
      arabic: '\u0645\u0650\u0646\u0652',
      name: 'Min',
      audioPath: 'audio/hijaiyah/jilid5/min.mp3',
      hint: 'Contoh sukun di akhir kata: min',
    ),
    const JilidPage(
      arabic: '\u0639\u064E\u0646\u0652',
      name: 'An',
      audioPath: 'audio/hijaiyah/jilid5/an.mp3',
      hint: 'Contoh sukun di akhir kata: an',
    ),
    const JilidPage(
      arabic: '\u0641\u0650\u064A',
      name: 'Fii',
      audioPath: 'audio/hijaiyah/jilid5/fii.mp3',
      hint: 'Kata depan "di dalam"',
    ),
    const JilidPage(
      arabic: '\u0625\u0650\u0644\u064E\u0649',
      name: 'Ilaa',
      audioPath: 'audio/hijaiyah/jilid5/ilaa.mp3',
      hint: 'Kata depan "ke"',
    ),
    const JilidPage(
      arabic: '\u0645\u064E\u0639\u064E',
      name: 'Maa',
      audioPath: 'audio/hijaiyah/jilid5/maa.mp3',
      hint: 'Kata depan "bersama"',
    ),
    const JilidPage(
      arabic: '\u0647\u064E\u0644\u0652',
      name: 'Hal',
      audioPath: 'audio/hijaiyah/jilid5/hal.mp3',
      hint: 'Kata tanya',
    ),
    const JilidPage(
      arabic: '\u0644\u064E\u0645\u0652',
      name: 'Lam',
      audioPath: 'audio/hijaiyah/jilid5/lam.mp3',
      hint: 'Kata negasi lampau',
    ),
    const JilidPage(
      arabic: '\u0642\u064E\u062F\u0652',
      name: 'Qad',
      audioPath: 'audio/hijaiyah/jilid5/qad.mp3',
      hint: 'Kata penegas',
    ),
    const JilidPage(
      arabic: '\u0644\u064E\u0646\u0652',
      name: 'Lan',
      audioPath: 'audio/hijaiyah/jilid5/lan.mp3',
      hint: 'Kata negasi masa depan',
    ),
  ];

  // ─── Jilid 6 ────────────────────────────────────────────────────────────────
  // Kata dan Kalimat — 30 halaman
  static final List<JilidPage> _jilid6 = const [
    // Seksi 1: Kata dasar (12 kata)
    JilidPage(
      arabic: '\u0628\u064E\u0627\u0628\u064C',
      name: 'Baabun',
      audioPath: 'audio/hijaiyah/jilid6/baabun.mp3',
      hint: 'Artinya: pintu',
    ),
    JilidPage(
      arabic: '\u0643\u0650\u062A\u064E\u0627\u0628\u064C',
      name: 'Kitaabun',
      audioPath: 'audio/hijaiyah/jilid6/kitaabun.mp3',
      hint: 'Artinya: kitab/buku',
    ),
    JilidPage(
      arabic: '\u0642\u064E\u0644\u064E\u0645\u064C',
      name: 'Qalamun',
      audioPath: 'audio/hijaiyah/jilid6/qalamun.mp3',
      hint: 'Artinya: pena',
    ),
    JilidPage(
      arabic: '\u0628\u064E\u064A\u0652\u062A\u064C',
      name: 'Baitun',
      audioPath: 'audio/hijaiyah/jilid6/baitun.mp3',
      hint: 'Artinya: rumah',
    ),
    JilidPage(
      arabic: '\u0645\u064E\u0633\u0652\u062C\u0650\u062F\u064C',
      name: 'Masjidun',
      audioPath: 'audio/hijaiyah/jilid6/masjidun.mp3',
      hint: 'Artinya: masjid',
    ),
    JilidPage(
      arabic: '\u0645\u064E\u062F\u0652\u0631\u064E\u0633\u064E\u0629\u064C',
      name: 'Madrasatun',
      audioPath: 'audio/hijaiyah/jilid6/madrasatun.mp3',
      hint: 'Artinya: sekolah',
    ),
    JilidPage(
      arabic: '\u0648\u064E\u0644\u064E\u062F\u064C',
      name: 'Waladun',
      audioPath: 'audio/hijaiyah/jilid6/waladun.mp3',
      hint: 'Artinya: anak laki-laki',
    ),
    JilidPage(
      arabic: '\u0628\u0650\u0646\u0652\u062A\u064C',
      name: 'Bintun',
      audioPath: 'audio/hijaiyah/jilid6/bintun.mp3',
      hint: 'Artinya: anak perempuan',
    ),
    JilidPage(
      arabic: '\u0623\u064F\u0645\u0651\u064C',
      name: 'Ummun',
      audioPath: 'audio/hijaiyah/jilid6/ummun.mp3',
      hint: 'Artinya: ibu',
    ),
    JilidPage(
      arabic: '\u0623\u064E\u0628\u064C',
      name: 'Abun',
      audioPath: 'audio/hijaiyah/jilid6/abun.mp3',
      hint: 'Artinya: ayah',
    ),
    JilidPage(
      arabic: '\u0645\u064E\u0627\u0621\u064C',
      name: 'Maaun',
      audioPath: 'audio/hijaiyah/jilid6/maaun.mp3',
      hint: 'Artinya: air',
    ),
    JilidPage(
      arabic: '\u0646\u064F\u0648\u0631\u064C',
      name: 'Nuurun',
      audioPath: 'audio/hijaiyah/jilid6/nuurun.mp3',
      hint: 'Artinya: cahaya',
    ),

    // Seksi 2: Frasa dan kalimat pendek (8 kalimat)
    JilidPage(
      arabic: '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064F\u0647\u0650',
      name: 'Bismillah',
      audioPath: 'audio/hijaiyah/jilid6/bismillah.mp3',
      hint: 'Dengan nama Allah',
    ),
    JilidPage(
      arabic: '\u0627\u0644\u0652\u062D\u064E\u0645\u0652\u062F\u064F \u0644\u0650\u0644\u0651\u064F\u0647\u0650',
      name: 'Alhamdulillah',
      audioPath: 'audio/hijaiyah/jilid6/alhamdulillah.mp3',
      hint: 'Segala puji bagi Allah',
    ),
    JilidPage(
      arabic: '\u0627\u0644\u0644\u0651\u064F\u0647\u064F \u0623\u064E\u0643\u0652\u0628\u064E\u0631\u064F',
      name: 'Allahu Akbar',
      audioPath: 'audio/hijaiyah/jilid6/allahu_akbar.mp3',
      hint: 'Allah Maha Besar',
    ),
    JilidPage(
      arabic: '\u0633\u064F\u0628\u0652\u062D\u064E\u0627\u0646\u064E \u0627\u0644\u0644\u0651\u064F\u0647\u0650',
      name: 'Subhanallah',
      audioPath: 'audio/hijaiyah/jilid6/subhanallah.mp3',
      hint: 'Maha Suci Allah',
    ),
    JilidPage(
      arabic: '\u0644\u064E\u0627 \u0625\u0650\u0644\u064E\u0647\u064E \u0625\u0650\u0644\u0651\u064E\u0627 \u0627\u0644\u0644\u0651\u064F\u0647\u064F',
      name: 'Laa Ilaaha Illallah',
      audioPath: 'audio/hijaiyah/jilid6/lailahaillallah.mp3',
      hint: 'Tiada tuhan selain Allah',
    ),
    JilidPage(
      arabic: '\u0623\u064E\u0633\u0652\u062A\u064E\u063A\u0652\u0641\u0650\u0631\u064F \u0627\u0644\u0644\u0651\u064F\u0647\u064E',
      name: 'Astaghfirullah',
      audioPath: 'audio/hijaiyah/jilid6/astaghfirullah.mp3',
      hint: 'Aku mohon ampun kepada Allah',
    ),
    JilidPage(
      arabic: '\u0625\u0650\u0646\u0652 \u0634\u064E\u0627\u0621\u064E \u0627\u0644\u0644\u0651\u064F\u0647\u064F',
      name: 'Insya Allah',
      audioPath: 'audio/hijaiyah/jilid6/insya_allah.mp3',
      hint: 'Jika Allah menghendaki',
    ),
    JilidPage(
      arabic: '\u0645\u064E\u0627\u0634\u064E\u0627\u0621\u064E \u0627\u0644\u0644\u0651\u064F\u0647\u064F',
      name: 'Masya Allah',
      audioPath: 'audio/hijaiyah/jilid6/masya_allah.mp3',
      hint: 'Sungguh atas kehendak Allah',
    ),

    // Seksi 3: Ayat pendek (10 ayat)
    JilidPage(
      arabic: '\u0642\u064F\u0644\u0652 \u0647\u064F\u0648\u064E \u0627\u0644\u0644\u0651\u064F\u0647\u064F \u0623\u064E\u062D\u064E\u062F\u064C',
      name: 'Qul Huwallahu Ahad',
      audioPath: 'audio/hijaiyah/jilid6/qul_huwallahu_ahad.mp3',
      hint: 'Al-Ikhlas: 1 — Katakanlah, Dialah Allah Yang Maha Esa',
    ),
    JilidPage(
      arabic: '\u0627\u0644\u0644\u0651\u064F\u0647\u064F \u0627\u0644\u0635\u0651\u064E\u0645\u064E\u062F\u064F',
      name: 'Allahush Shamad',
      audioPath: 'audio/hijaiyah/jilid6/allahush_shamad.mp3',
      hint: 'Al-Ikhlas: 2 — Allah tempat bergantung',
    ),
    JilidPage(
      arabic: '\u0648\u064E\u0642\u064F\u0644\u0652 \u0631\u064E\u0628\u0651\u0650 \u0632\u0650\u062F\u0652\u0646\u0650\u064A\u0652 \u0639\u0650\u0644\u0652\u0645\u064B\u0627',
      name: 'Wa qul rabbi zidni ilmaa',
      audioPath: 'audio/hijaiyah/jilid6/rabbi_zidni_ilma.mp3',
      hint: 'Thaha:114 — Dan katakanlah: Tuhanku, tambahkanlah ilmu kepadaku',
    ),
    JilidPage(
      arabic: '\u0631\u064E\u0628\u0651\u064E\u0646\u064E\u0627 \u0622\u062A\u0650\u0646\u064E\u0627 \u0641\u0650\u064A \u0627\u0644\u062F\u064F\u0651\u0646\u0652\u064A\u064E\u0627 \u062D\u064E\u0633\u064E\u0646\u064E\u0629\u064B',
      name: 'Rabbana aatina fiddunya',
      audioPath: 'audio/hijaiyah/jilid6/rabbana_aatina.mp3',
      hint: 'Al-Baqarah:201 — Doa kebaikan dunia akhirat',
    ),
    JilidPage(
      arabic: '\u0642\u064F\u0644\u0652 \u0623\u064E\u0639\u064F\u0648\u0630\u064F \u0628\u0650\u0631\u064E\u0628\u0651\u0650 \u0627\u0644\u0652\u0641\u064E\u0644\u064E\u0642\u0650',
      name: 'Qul Audzubirobbilfalaq',
      audioPath: 'audio/hijaiyah/jilid6/qul_audzubirobbilfalaq.mp3',
      hint: 'Al-Falaq: 1',
    ),
    JilidPage(
      arabic: '\u0642\u064F\u0644\u0652 \u0623\u064E\u0639\u064F\u0648\u0630\u064F \u0628\u0650\u0631\u064E\u0628\u0651\u0650 \u0627\u0644\u0646\u0651\u064E\u0627\u0633\u0650',
      name: 'Qul Audzubirabbinnas',
      audioPath: 'audio/hijaiyah/jilid6/qul_audzubirabbinnas.mp3',
      hint: 'An-Nas: 1',
    ),
    JilidPage(
      arabic: '\u0625\u0650\u0646\u0651\u064E\u0627 \u0623\u064E\u0639\u0652\u0637\u064E\u064A\u0652\u0646\u064E\u0627\u0643\u064E \u0627\u0644\u0652\u0643\u064E\u0648\u0652\u062B\u064E\u0631\u064E',
      name: 'Innaa Atainakal Kautsar',
      audioPath: 'audio/hijaiyah/jilid6/innaa_atainakal_kautsar.mp3',
      hint: 'Al-Kautsar: 1',
    ),
    JilidPage(
      arabic: '\u0641\u064E\u0635\u064E\u0644\u0651\u0650 \u0644\u0650\u0631\u064E\u0628\u0651\u0650\u0643\u064E \u0648\u064E\u0627\u0646\u0652\u062D\u064E\u0631\u0652',
      name: 'Fashalli lirabbika wanhar',
      audioPath: 'audio/hijaiyah/jilid6/fashalli_lirabbika.mp3',
      hint: 'Al-Kautsar: 2',
    ),
    JilidPage(
      arabic: '\u0623\u064E\u0644\u064E\u0645\u0652 \u062A\u064E\u0631\u064E \u0643\u064E\u064A\u0652\u0641\u064E \u0641\u064E\u0639\u064E\u0644\u064E \u0631\u064E\u0628\u0651\u064F\u0643\u064E',
      name: 'Alam tara kaifa faala rabbuk',
      audioPath: 'audio/hijaiyah/jilid6/alam_tara_kaifa.mp3',
      hint: 'Al-Fiil: 1',
    ),
    JilidPage(
      arabic: '\u0648\u064E\u0627\u0644\u0652\u0639\u064E\u0635\u0652\u0631\u0650 \u0625\u0650\u0646\u0651\u064E \u0627\u0644\u0652\u0625\u0650\u0646\u0652\u0633\u064E\u0627\u0646\u064E \u0644\u064E\u0641\u0650\u064A \u062E\u064F\u0633\u0652\u0631\u0653',
      name: 'Wal ashr innal insana lafi khusr',
      audioPath: 'audio/hijaiyah/jilid6/wal_ashr.mp3',
      hint: 'Al-Asr: 1-2',
    ),
  ];

  // ─── Helper ─────────────────────────────────────────────────────────────────

  /// Ubah nama huruf ke format nama file (lowercase, tanpa spesial karakter)
  static String _slug(String name) =>
      name.toLowerCase().replaceAll("'", '').replaceAll(' ', '_').replaceAll('-', '_');
}
