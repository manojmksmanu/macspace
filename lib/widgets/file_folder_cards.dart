import 'dart:io';
import 'package:flutter/material.dart';
import '../models/storage_item.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';
import 'confirm_delete_modal.dart';
import 'image_preview_modal.dart';

class LargestFoldersCard extends StatelessWidget {
  final List<StorageFolder> folders;
  final VoidCallback? onViewAll;

  const LargestFoldersCard({
    super.key,
    required this.folders,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseListCard(
      title: 'Largest Folders',
      onViewAll: onViewAll,
      children: folders.map((folder) {
        return _buildFolderRow(context, folder);
      }).toList(),
    );
  }

  Widget _buildFolderRow(BuildContext context, StorageFolder folder) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11.0),
      child: InkWell(
        onTap: () => SystemStorageService.revealInFinder(folder.path),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.folder_rounded,
                color: Color(0xFF0284C7),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    folder.path,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${folder.sizeGB.toStringAsFixed(1)} GB',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LargestFilesCard extends StatelessWidget {
  final List<StorageFile> files;
  final VoidCallback? onViewAll;

  const LargestFilesCard({
    super.key,
    required this.files,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseListCard(
      title: 'Largest Files',
      onViewAll: onViewAll,
      children: files.map((file) {
        return _buildFileRow(context, file);
      }).toList(),
    );
  }

  Widget _buildFileRow(BuildContext context, StorageFile file) {
    final expandedPath = file.path.replaceAll('~', Platform.environment['HOME'] ?? '');
    final isImage = SystemStorageService.isImageFile(file.name) || SystemStorageService.isImageFile(expandedPath);
    final diskFile = File(expandedPath);

    return GestureDetector(
      onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition, file),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 11.0),
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
          child: Row(
            children: [
              isImage && diskFile.existsSync()
                  ? Container(
                      width: 32,
                      height: 32,
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
                            color: file.iconColor.withValues(alpha: 0.12),
                            child: Icon(file.icon, color: file.iconColor, size: 18),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: file.iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        file.icon,
                        color: file.iconColor,
                        size: 18,
                      ),
                    ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            file.name,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isImage)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'IMAGE',
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      file.path,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF94A3B8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                SystemStorageService.formatFileSizeGB(file.sizeGB),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isImage ? AppTheme.emeraldGreen : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position, StorageFile file) {
    final expandedPath = file.path.replaceAll('~', Platform.environment['HOME'] ?? '');
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
      if (value == null) return;
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
          break;
        case 'delete':
          ConfirmDeleteModal.show(
            context: context,
            itemName: file.name,
            itemPath: expandedPath,
            itemSize: '${file.sizeGB} GB',
            onMoveToTrash: () => SystemStorageService.moveToTrash(expandedPath),
            onConfirmPermanentDelete: () => SystemStorageService.deletePermanently(expandedPath),
          );
          break;
      }
    });
  }
}

class RecentLargeFilesCard extends StatelessWidget {
  final List<StorageFile> files;
  final VoidCallback? onViewAll;

  const RecentLargeFilesCard({
    super.key,
    required this.files,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseListCard(
      title: 'Recent Large Files',
      onViewAll: onViewAll,
      children: files.map((file) {
        return _buildFileRow(context, file);
      }).toList(),
    );
  }

  Widget _buildFileRow(BuildContext context, StorageFile file) {
    final expandedPath = file.path.replaceAll('~', Platform.environment['HOME'] ?? '');
    final isImage = SystemStorageService.isImageFile(file.name) || SystemStorageService.isImageFile(expandedPath);
    final diskFile = File(expandedPath);

    return Padding(
      padding: const EdgeInsets.only(bottom: 11.0),
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
        child: Row(
          children: [
            isImage && diskFile.existsSync()
                ? Container(
                    width: 32,
                    height: 32,
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
                          color: file.iconColor.withValues(alpha: 0.12),
                          child: Icon(file.icon, color: file.iconColor, size: 18),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: file.iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      file.icon,
                      color: file.iconColor,
                      size: 18,
                    ),
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    file.path,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              SystemStorageService.formatFileSizeGB(file.sizeGB),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isImage ? AppTheme.emeraldGreen : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BaseListCard extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final List<Widget> children;

  const _BaseListCard({
    required this.title,
    this.onViewAll,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: onViewAll,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
