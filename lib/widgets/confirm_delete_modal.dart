import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConfirmDeleteModal extends StatelessWidget {
  final String itemName;
  final String itemPath;
  final String itemSize;
  final VoidCallback onConfirmPermanentDelete;
  final VoidCallback onMoveToTrash;

  const ConfirmDeleteModal({
    super.key,
    required this.itemName,
    required this.itemPath,
    required this.itemSize,
    required this.onConfirmPermanentDelete,
    required this.onMoveToTrash,
  });

  static Future<void> show({
    required BuildContext context,
    required String itemName,
    required String itemPath,
    required String itemSize,
    required VoidCallback onConfirmPermanentDelete,
    required VoidCallback onMoveToTrash,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ConfirmDeleteModal(
        itemName: itemName,
        itemPath: itemPath,
        itemSize: itemSize,
        onConfirmPermanentDelete: onConfirmPermanentDelete,
        onMoveToTrash: onMoveToTrash,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppTheme.cardBg : AppTheme.cardBgLight;
    final itemBg = isDark ? AppTheme.bgDark : AppTheme.bgLight;
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final textPrimary = isDark ? AppTheme.textWhite : AppTheme.textDark;
    final textSecondary = isDark ? AppTheme.textSubtle : AppTheme.textMutedLight;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.coralRose.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.coralRose.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.coralRose,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permanent Delete Warning',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'This action cannot be undone!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.coralRose,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Are you sure you want to permanently delete this file from your Mac? It will be erased completely without moving to Trash.',
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Item Details Badge Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: itemBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.insert_drive_file_outlined, color: textSecondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          itemPath,
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    itemSize,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textSecondary,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onMoveToTrash();
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Move to Trash'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirmPermanentDelete();
                  },
                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                  label: const Text('Permanent Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.coralRose,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppTheme.coralRose.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
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
