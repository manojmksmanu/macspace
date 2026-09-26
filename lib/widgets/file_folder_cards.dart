import 'package:flutter/material.dart';
import '../models/storage_item.dart';

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
        return _buildFolderRow(folder);
      }).toList(),
    );
  }

  Widget _buildFolderRow(StorageFolder folder) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11.0),
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
        return _buildFileRow(file);
      }).toList(),
    );
  }

  Widget _buildFileRow(StorageFile file) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: file.iconColor.withOpacity(0.12),
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
            '${file.sizeGB.toStringAsFixed(1)} GB',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
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
        return _buildFileRow(file);
      }).toList(),
    );
  }

  Widget _buildFileRow(StorageFile file) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: file.iconColor.withOpacity(0.12),
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
            '${file.sizeGB.toStringAsFixed(1)} GB',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
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
            color: Colors.black.withOpacity(0.03),
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
