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
    return Dialog(
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
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
                    children: const [
                      Text(
                        'Permanent Delete Warning',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
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
            const Text(
              'Are you sure you want to permanently delete this file from your Mac? It will be erased completely without moving to Trash.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Item Details Badge Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined, color: AppTheme.textMuted, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textWhite,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          itemPath,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSubtle,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    itemSize,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textWhite,
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
                    foregroundColor: AppTheme.textSubtle,
                    side: const BorderSide(color: AppTheme.borderColor),
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
