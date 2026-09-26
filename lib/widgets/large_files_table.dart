import 'dart:io';
import 'package:flutter/material.dart';
import '../models/storage_item.dart';
import '../theme/app_theme.dart';

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

  void _openInFinder(String path) {
    final expandedPath = path.replaceAll('~', Platform.environment['HOME'] ?? '');
    Process.run('open', [expandedPath]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opened $shortPath in macOS Finder'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String get shortPath => _tabIndex == 0 ? widget.folders.first.path : widget.largestFiles.first.path;

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
          color: AppTheme.bgDark.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.15),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.bgDark.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: file.iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(file.icon, color: file.iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textWhite),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${file.path} • ${file.type}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSubtle),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '${file.sizeGB} GB',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textWhite),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.folder_open_rounded, size: 18, color: AppTheme.cyanGlow),
              tooltip: 'Reveal in Finder',
              onPressed: () => _openInFinder(file.path),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.coralRose),
              tooltip: 'Move to Trash',
              onPressed: () {
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
    );
  }
}
