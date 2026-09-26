import 'package:flutter/material.dart';

class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onScanStorage;
  final VoidCallback onFindDuplicates;
  final VoidCallback onCleanCache;
  final VoidCallback onOpenFinder;

  const QuickActionsGrid({
    super.key,
    required this.onScanStorage,
    required this.onFindDuplicates,
    required this.onCleanCache,
    required this.onOpenFinder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
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
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.search_rounded,
                      iconColor: const Color(0xFF2563EB),
                      title: 'Scan Storage',
                      subtitle: 'Scan your Mac for storage usage',
                      onTap: onScanStorage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.copy_rounded,
                      iconColor: const Color(0xFF2563EB),
                      title: 'Find Duplicates',
                      subtitle: 'Locate duplicate files to free up space',
                      onTap: onFindDuplicates,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFF2563EB),
                      title: 'Clean Cache',
                      subtitle: 'Remove cache files safely',
                      onTap: onCleanCache,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.folder_open_rounded,
                      iconColor: const Color(0xFF2563EB),
                      title: 'Open in Finder',
                      subtitle: 'Open selected location in Finder',
                      onTap: onOpenFinder,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
