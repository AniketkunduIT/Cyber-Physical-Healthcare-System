import 'package:flutter/material.dart';

import '../models/voice_note_model.dart';
import '../theme/app_theme.dart';

class VoiceNoteCard extends StatelessWidget {
  final VoiceNoteModel note;
  final VoidCallback? onDelete;

  const VoiceNoteCard({
    super.key,
    required this.note,
    this.onDelete,
  });

  // Fixed bar heights that mimic a frozen waveform snapshot
  static const List<double> _bars = [
    4, 8, 14, 20, 28, 22, 16, 26, 32, 24, 18, 30,
    34, 20, 12, 26, 30, 18, 10, 22, 16, 10, 14, 6,
  ];

  String get _formattedTime {
    final h = note.recordedAt.hour;
    final m = note.recordedAt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'pm' : 'am';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.voiceBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Play button
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.brandPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),

          // Duration + Waveform + Timestamp — expands to fill available space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform row with timestamp at the end
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Waveform bars
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(_bars.length, (i) {
                            final h = (_bars[i] * 0.8).clamp(3.0, 28.0);
                            return Container(
                              width: 3,
                              height: h,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Timestamp
                    Text(
                      _formattedTime,
                      style: const TextStyle(
                        color: AppColors.voiceDuration,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Duration label
                Text(
                  note.formattedDuration,
                  style: const TextStyle(
                    color: Color(0xFFE2D9FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Delete × button
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
