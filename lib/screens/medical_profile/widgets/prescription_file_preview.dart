import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// Card showing uploading state or preview of uploaded prescription document.
class PrescriptionFilePreview extends StatelessWidget {
  final bool isUploading;
  final String? fileName;
  final int fileSizeBytes;
  final VoidCallback onRemove;

  const PrescriptionFilePreview({
    super.key,
    required this.isUploading,
    required this.fileName,
    required this.fileSizeBytes,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (isUploading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentPurple,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Uploading prescription…',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (fileName == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.lightPurple,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.insert_drive_file_outlined,
                color: AppColors.accentPurple,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.formatFileSize(fileSizeBytes)} · Uploaded',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 1.0,
                    minHeight: 4,
                    backgroundColor: Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
          ),
        ],
      ),
    );
  }
}
