import 'dart:io';
import 'package:flutter/material.dart';
import '../models/storage_item.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';
import 'confirm_delete_modal.dart';
import 'image_preview_modal.dart';

class LargeFilesTable extends StatefulWidget {
  final List<StorageFolder> folders;
  final List<StorageFile> largestFiles;
  final List<StorageFile> recentFiles;

  const LargeFilesTable({
    super.key,
    required this.folders,
    required this.largestFiles,
    required this.recentFiles,
  });

  @override
  State<LargeFilesTable> createState() => _LargeFilesTableState();
}

class _LargeFilesTableState extends State<LargeFilesTable> {
  int _tabIndex = 0; // 0: Top Folders, 1: Largest Files, 2: Recent Files

  String _getExpandedPath(String path) {
    return path.replaceAll('~', Platform.environment['HOME'] ?? '');
  }

  void _openInFinder(String path) {
    SystemStorageService.revealInFinder(path);
  }

  void _showContextMenuForFile(BuildContext context, Offset position, StorageFile file) {
    final expandedPath = _getExpandedPath(file.path);
    final isImage = SystemStorageService.isImageFile(file.name) || SystemStorageService.isImageFile(expandedPath);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      color: const Color(0xFF1E293B),
      items: [
        PopupMenuItem<String>(
          value: 'open',
          child: const Row(
            children: [
              Icon(Icons.open_in_new_rounded, size: 18, color: AppTheme.cyanGlow),
              SizedBox(width: 10),
              Text('Open File', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'finder',
          child: const Row(
            children: [
              Icon(Icons.folder_copy_rounded, size: 18, color: AppTheme.amberGold),
              SizedBox(width: 10),
              Text('Show in Finder / Folder', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (isImage)
          PopupMenuItem<String>(
            value: 'preview_image',
            child: const Row(
              children: [
                Icon(Icons.image_rounded, size: 18, color: AppTheme.emeraldGreen),
                SizedBox(width: 10),
                Text('Preview Image', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'trash',
          child: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.primaryBlue),
              SizedBox(width: 10),
              Text('Move to Trash', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, size: 18, color: AppTheme.coralRose),
              SizedBox(width: 10),
              Text('Delete Permanently', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null || !mounted) return;
      switch (value) {
        case 'open':
          SystemStorageService.openFile(expandedPath);
          break;
        case 'finder':
          SystemStorageService.revealInFinder(expandedPath);
          break;
        case 'preview_image':
          ImagePreviewModal.show(
            context: context,
            imagePath: expandedPath,
            imageName: file.name,
            fileSizeFormatted: '${file.sizeGB} GB',
          );
          break;
        case 'trash':
          SystemStorageService.moveToTrash(expandedPath);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Moved ${file.name} to Trash'), backgroundColor: AppTheme.primaryBlue),
          );
          break;
        case 'delete':
          ConfirmDeleteModal.show(
            context: context,
            itemName: file.name,
            itemPath: expandedPath,
            itemSize: '${file.sizeGB} GB',
            onMoveToTrash: () => SystemStorageService.moveToTrash(expandedPath),
            onConfirmPermanentDelete: () {
              SystemStorageService.deletePermanently(expandedPath);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted ${file.name} permanently'), backgroundColor: AppTheme.coralRose),
              );
            },
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBgTranslucent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Space Consumer Inspector',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
              ),
              // Segmented Tabs
              Container(
                height: 32,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    _buildTabBtn(0, 'Top Folders'),
                    _buildTabBtn(1, 'Largest Files'),
                    _buildTabBtn(2, 'Recent Files'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items List
          if (_tabIndex == 0)
            ...widget.folders.map((folder) => _buildFolderRow(folder))
          else if (_tabIndex == 1)
            ...widget.largestFiles.map((file) => _buildFileRow(file))
          else
            ...widget.recentFiles.map((file) => _buildFileRow(file)),
        ],
      ),
    );
  }

  Widget _buildTabBtn(int index, String label) {
    final isSelected = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.textWhite : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildFolderRow(StorageFolder folder) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.bgDark.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.folder_rounded, color: AppTheme.primaryBlue, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textWhite),
                  ),
                  Text(
                    folder.path,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSubtle),
                  ),
                ],
              ),
            ),
            Text(
              '${folder.sizeGB} GB',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textWhite),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.folder_open_rounded, size: 18, color: AppTheme.cyanGlow),
              tooltip: 'Reveal in Finder',
              onPressed: () => _openInFinder(folder.path),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileRow(StorageFile file) {
    final expandedPath = _getExpandedPath(file.path);
    final isImage = SystemStorageService.isImageFile(file.name) || SystemStorageService.isImageFile(expandedPath);
    final diskFile = File(expandedPath);

    return GestureDetector(
      onSecondaryTapDown: (details) => _showContextMenuForFile(context, details.globalPosition, file),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.bgDark.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  if (isImage) {
                    ImagePreviewModal.show(
                      context: context,
                      imagePath: expandedPath,
                      imageName: file.name,
                      fileSizeFormatted: '${file.sizeGB} GB',
                    );
                  } else {
                    SystemStorageService.openFile(expandedPath);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: isImage && diskFile.existsSync()
                    ? Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.5)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.file(
                            diskFile,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: file.iconColor.withValues(alpha: 0.15),
                              child: Icon(file.icon, color: file.iconColor, size: 18),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: file.iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(file.icon, color: file.iconColor, size: 18),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (isImage) {
                      ImagePreviewModal.show(
                        context: context,
                        imagePath: expandedPath,
                        imageName: file.name,
                        fileSizeFormatted: '${file.sizeGB} GB',
                      );
                    } else {
                      SystemStorageService.openFile(expandedPath);
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              file.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textWhite),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isImage)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                'IMAGE',
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '${file.path} • ${file.type}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSubtle),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                SystemStorageService.formatFileSizeGB(file.sizeGB),
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: isImage ? AppTheme.emeraldGreen : AppTheme.textWhite),
              ),
              const SizedBox(width: 12),
              if (isImage)
                IconButton(
                  icon: const Icon(Icons.image_rounded, size: 18, color: AppTheme.emeraldGreen),
                  tooltip: 'Preview Image',
                  onPressed: () => ImagePreviewModal.show(
                    context: context,
                    imagePath: expandedPath,
                    imageName: file.name,
                    fileSizeFormatted: '${file.sizeGB} GB',
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.folder_open_rounded, size: 18, color: AppTheme.cyanGlow),
                tooltip: 'Reveal in Finder',
                onPressed: () => _openInFinder(file.path),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.coralRose),
                tooltip: 'Move to Trash',
                onPressed: () {
                  SystemStorageService.moveToTrash(expandedPath);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Moved ${file.name} to Trash'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
