import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_theme.dart';

/// Dialog verifikasi orang tua menggunakan soal matematika sederhana.
///
/// Gunakan [ParentalGateDialog.show(context)] → mengembalikan `true` jika
/// berhasil menjawab dengan benar, `false` jika dibatalkan.
///
/// Sesuai COPPA / Google Play Families Policy: orang tua harus melewati gate
/// sebelum mengakses pengaturan atau melakukan pembelian.
class ParentalGateDialog extends StatefulWidget {
  const ParentalGateDialog({super.key});

  /// Tampilkan dialog dan tunggu hasilnya.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ParentalGateDialog(),
    );
    return result ?? false;
  }

  @override
  State<ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<ParentalGateDialog>
    with SingleTickerProviderStateMixin {
  late int _a;
  late int _b;
  late int _answer;
  final _controller = TextEditingController();
  String? _errorText;
  bool _shaking = false;

  // Animasi getar saat salah
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    _shakeCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _shakeCtrl.reset();
        if (mounted) setState(() => _shaking = false);
      }
    });
    _generate();
  }

  void _generate() {
    final rand = Random();
    _a = rand.nextInt(8) + 2; // 2–9
    _b = rand.nextInt(8) + 2; // 2–9
    _answer = _a + _b;
  }

  void _verify() {
    final input = int.tryParse(_controller.text.trim());
    if (input == null) {
      setState(() => _errorText = 'Masukkan angka yang valid');
      return;
    }
    if (input == _answer) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorText = 'Jawaban salah, coba lagi';
        _controller.clear();
        _generate();
        _shaking = true;
      });
      _shakeCtrl.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.family_restroom_rounded,
                color: AppTheme.primary,
                size: 32,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Area Orang Tua',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Jawab soal matematika untuk melanjutkan.\n'
              'Ini memastikan hanya orang dewasa yang mengakses menu ini.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 22),

            // Soal matematika
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) {
                final offset = _shaking
                    ? ((_shakeAnim.value * 3).toInt() % 2 == 0 ? 8.0 : -8.0) *
                        _shakeAnim.value
                    : 0.0;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '$_a  +  $_b  =  ?',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Input jawaban
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Jawaban...',
                errorText: _errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppTheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onSubmitted: (_) => _verify(),
            ),

            const SizedBox(height: 22),

            // Tombol aksi
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: Colors.grey[350]!),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _verify,
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
                      'Konfirmasi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
