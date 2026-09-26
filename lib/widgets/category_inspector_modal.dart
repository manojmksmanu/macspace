import 'package:flutter/material.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';
import 'confirm_delete_modal.dart';

class CategoryInspectorModal extends StatefulWidget {
  final CategoryCardInfo categoryInfo;

  const CategoryInspectorModal({super.key, required this.categoryInfo});

  static Future<void> show({
    required BuildContext context,
    required CategoryCardInfo categoryInfo,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CategoryInspectorModal(categoryInfo: categoryInfo),
    );
  }

  @override
  State<CategoryInspectorModal> createState() => _CategoryInspectorModalState();
}

class _CategoryInspectorModalState extends State<CategoryInspectorModal> {
  late List<CategoryDetailItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.categoryInfo.items);
  }

  void _handleTrash(CategoryDetailItem item) async {
    final success = await SystemStorageService.moveToTrash(item.path);
    if (mounted) {
      setState(() {
        _items.remove(item);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Moved ${item.name} to Trash' : 'Could not move ${item.name} to Trash'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    }
  }

  void _handlePermanentDelete(CategoryDetailItem item) async {
    final success = await SystemStorageService.deletePermanently(item.path);
    if (mounted) {
      setState(() {
        _items.remove(item);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Permanently deleted ${item.name}' : 'Could not delete ${item.name}'),
          backgroundColor: AppTheme.coralRose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.categoryInfo;

    return Dialog(
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 720,
        height: 580,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cat.color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Inspector: ${cat.title}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        Text(
                          '${cat.subtitle} • Total: ${cat.sizeGB} GB',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Items List
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 44),
                          SizedBox(height: 12),
                          Text(
                            'No Files in Category',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textWhite),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.bgDark.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cat.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(cat.icon, color: cat.color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textWhite,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      item.path,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppTheme.textSubtle,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                item.sizeFormatted,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Action Buttons
                              IconButton(
                                icon: const Icon(Icons.folder_open_rounded, size: 18, color: AppTheme.cyanGlow),
                                tooltip: 'Reveal in Finder',
                                onPressed: () => SystemStorageService.revealInFinder(item.path),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.primaryBlue),
                                tooltip: 'Move to Trash',
                                onPressed: () => _handleTrash(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever_rounded, size: 18, color: AppTheme.coralRose),
                                tooltip: 'Permanent Delete',
                                onPressed: () {
                                  ConfirmDeleteModal.show(
                                    context: context,
                                    itemName: item.name,
                                    itemPath: item.path,
                                    itemSize: item.sizeFormatted,
                                    onMoveToTrash: () => _handleTrash(item),
                                    onConfirmPermanentDelete: () => _handlePermanentDelete(item),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
