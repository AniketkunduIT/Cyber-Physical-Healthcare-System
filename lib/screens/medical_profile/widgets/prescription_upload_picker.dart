import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/dashed_border_card.dart';

/// Dashed card and quick-action buttons for selecting a prescription image/file.
class PrescriptionUploadPicker extends StatelessWidget {
  final VoidCallback onUploadTap;
  final VoidCallback onTakePhotoTap;
  final VoidCallback onGalleryTap;

  const PrescriptionUploadPicker({
    super.key,
    required this.onUploadTap,
    required this.onTakePhotoTap,
    required this.onGalleryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DashedBorderCard(
          color: const Color(0xFF8B5CF6),
          strokeWidth: 1.5,
          dashLength: 7,
          gap: 5,
          borderRadius: 18,
          onTap: onUploadTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.file_upload_outlined,
                    color: AppColors.accentPurple,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap to upload prescription',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'JPG, PNG or PDF · up to 10 MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Take Photo',
                icon: Icons.camera_alt_outlined,
                backgroundColor: AppColors.photoBg,
                foregroundColor: AppColors.photoText,
                onTap: onTakePhotoTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Gallery',
                icon: Icons.image_outlined,
                backgroundColor: AppColors.galleryBg,
                foregroundColor: AppColors.galleryText,
                onTap: onGalleryTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foregroundColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
