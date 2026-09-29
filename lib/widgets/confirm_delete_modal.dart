import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'deletion_loading_modal.dart';

class ConfirmDeleteModal extends StatelessWidget {
  final String itemName;
  final String itemPath;
  final String itemSize;
  final FutureOr<void> Function()? onConfirmPermanentDelete;
  final FutureOr<void> Function()? onMoveToTrash;

  const ConfirmDeleteModal({
    super.key,
    required this.itemName,
    required this.itemPath,
    required this.itemSize,
    this.onConfirmPermanentDelete,
    this.onMoveToTrash,
  });

  static Future<void> show({
    required BuildContext context,
    required String itemName,
    required String itemPath,
    required String itemSize,
    FutureOr<void> Function()? onConfirmPermanentDelete,
    FutureOr<void> Function()? onMoveToTrash,
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
        width: 520,
        padding: const EdgeInsets.all(22),
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
                        'Confirm Delete Action',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Target item and disk space:',
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
              'Choose whether to move this item to Trash or permanently erase it from disk.',
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
            const SizedBox(height: 22),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textSecondary,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                if (onMoveToTrash != null) ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await DeletionLoadingModal.show(
                        context: context,
                        title: 'Moving to Trash...',
                        subTitle: 'Moving $itemName ($itemSize) to Trash...',
                        onDeleteTask: () async {
                          await Future.sync(() => onMoveToTrash?.call());
                          return true;
                        },
                      );
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 15),
                    label: const Text('Move to Trash'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (onConfirmPermanentDelete != null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await DeletionLoadingModal.show(
                        context: context,
                        title: 'Deleting Permanently...',
                        subTitle: 'Erasing $itemName ($itemSize) from disk...',
                        onDeleteTask: () async {
                          await Future.sync(() => onConfirmPermanentDelete?.call());
                          return true;
                        },
                      );
                    },
                    icon: const Icon(Icons.delete_forever_rounded, size: 15),
                    label: const Text('Delete Permanently'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.coralRose,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: AppTheme.coralRose.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
