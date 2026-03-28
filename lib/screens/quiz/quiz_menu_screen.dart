import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import 'quiz_match_screen.dart';
import 'quiz_play_screen.dart';
import 'quiz_see_pick_screen.dart';
import 'quiz_trace_screen.dart';

class QuizMenuScreen extends StatelessWidget {
  const QuizMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizModes = [
      {
        'title': 'Dengar & Pilih',
        'icon': Icons.hearing_rounded,
        'color': AppTheme.jilid1,
        'desc': 'Dengar suara, pilih huruf yang benar',
        'mode': 'listen_pick',
        'ready': true,
      },
      {
        'title': 'Lihat & Pilih Suara',
        'icon': Icons.visibility_rounded,
        'color': AppTheme.jilid2,
        'desc': 'Lihat huruf, pilih nama yang benar',
        'mode': 'see_pick',
        'ready': true,
      },
      {
        'title': 'Pasangkan',
        'icon': Icons.compare_arrows_rounded,
        'color': AppTheme.jilid4,
        'desc': 'Pasangkan huruf dengan suaranya',
        'mode': 'match',
        'ready': true,
      },
      {
        'title': 'Tulis Ulang',
        'icon': Icons.draw_rounded,
        'color': AppTheme.jilid5,
        'desc': 'Trace huruf yang ditampilkan',
        'mode': 'trace',
        'ready': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kuis Hijaiyah',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: quizModes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final mode = quizModes[index];
          final isReady = mode['ready'] as bool;
          final color = mode['color'] as Color;

          return GestureDetector(
            onTap: () {
              final modeStr = mode['mode'] as String;
              switch (modeStr) {
                case 'see_pick':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const QuizSeePickScreen()),
                  );
                case 'match':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const QuizMatchScreen()),
                  );
                case 'trace':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const QuizTraceScreen()),
                  );
                default:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizPlayScreen(mode: modeStr),
                    ),
                  );
              }
            },
            child: AnimatedOpacity(
              opacity: isReady ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        mode['icon'] as IconData,
                        color: color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                mode['title'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!isReady) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Segera',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mode['desc'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isReady
                          ? Icons.chevron_right_rounded
                          : Icons.lock_outline_rounded,
                      color: isReady ? Colors.grey[400] : Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
