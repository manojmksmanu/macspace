import 'dart:io';
import 'package:flutter/material.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';

class ImagePreviewModal extends StatelessWidget {
  final String imagePath;
  final String imageName;
  final String? fileSizeFormatted;

  const ImagePreviewModal({
    super.key,
    required this.imagePath,
    required this.imageName,
    this.fileSizeFormatted,
  });

  static Future<void> show({
    required BuildContext context,
    required String imagePath,
    required String imageName,
    String? fileSizeFormatted,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => ImagePreviewModal(
        imagePath: imagePath,
        imageName: imageName,
        fileSizeFormatted: fileSizeFormatted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expandedPath = imagePath.replaceAll('~', Platform.environment['HOME'] ?? '');
    final file = File(expandedPath);
    final exists = file.existsSync();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 750),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image_rounded, color: AppTheme.cyanGlow, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          imageName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          expandedPath,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (fileSizeFormatted != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        fileSizeFormatted!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Quick Actions
                  IconButton(
                    icon: const Icon(Icons.folder_open_rounded, color: AppTheme.cyanGlow, size: 20),
                    tooltip: 'Show in Finder',
                    onPressed: () => SystemStorageService.revealInFinder(expandedPath),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, color: AppTheme.emeraldGreen, size: 20),
                    tooltip: 'Open Image',
                    onPressed: () => SystemStorageService.openFile(expandedPath),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Image Preview Container
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: exists
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            file,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.broken_image_rounded, size: 64, color: AppTheme.coralRose),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Unable to preview image file format',
                                    style: TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () => SystemStorageService.openFile(expandedPath),
                                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                    label: const Text('Open with Default Viewer'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image_not_supported_rounded, size: 64, color: AppTheme.amberGold),
                            const SizedBox(height: 12),
                            const Text(
                              'Image file not found on disk',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
