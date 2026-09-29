import 'package:flutter/material.dart';
import '../models/project_info.dart';
import '../services/project_analyzer_service.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';
import 'confirm_delete_modal.dart';

class ProjectInspectorModal extends StatefulWidget {
  final ProjectInfo project;
  final VoidCallback onProjectUpdated;

  const ProjectInspectorModal({
    super.key,
    required this.project,
    required this.onProjectUpdated,
  });

  static Future<void> show({
    required BuildContext context,
    required ProjectInfo project,
    required VoidCallback onProjectUpdated,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ProjectInspectorModal(
        project: project,
        onProjectUpdated: onProjectUpdated,
      ),
    );
  }

  @override
  State<ProjectInspectorModal> createState() => _ProjectInspectorModalState();
}

class _ProjectInspectorModalState extends State<ProjectInspectorModal> {
  late ProjectInfo _proj;

  @override
  void initState() {
    super.initState();
    _proj = widget.project;
  }

  void _handleCleanSubItem(ProjectCacheSubDetail subItem) {
    ConfirmDeleteModal.show(
      context: context,
      itemName: '${_proj.name} (${subItem.name})',
      itemPath: subItem.path,
      itemSize: subItem.formattedSize,
      onMoveToTrash: () async {
        final ok = await SystemStorageService.moveToTrash(subItem.path);
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Moved ${subItem.name} to Trash'),
              backgroundColor: AppTheme.primaryBlue,
            ),
          );
          widget.onProjectUpdated();
          Navigator.of(context).pop();
        }
      },
      onConfirmPermanentDelete: () async {
        final ok = await ProjectAnalyzerService.deleteCachePath(subItem.path);
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted ${subItem.name} (${subItem.formattedSize})'),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
          widget.onProjectUpdated();
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _handleCleanAllReclaimable() {
    ConfirmDeleteModal.show(
      context: context,
      itemName: 'All Caches & Dependencies for ${_proj.name}',
      itemPath: '${_proj.fullPath} (node_modules, build output & caches)',
      itemSize: _proj.formattedReclaimableSize,
      onMoveToTrash: () async {
        for (final item in _proj.cacheDetails) {
          await SystemStorageService.moveToTrash(item.path);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Moved all ${_proj.name} cache folders to Trash'),
              backgroundColor: AppTheme.primaryBlue,
            ),
          );
          widget.onProjectUpdated();
          Navigator.of(context).pop();
        }
      },
      onConfirmPermanentDelete: () async {
        for (final item in _proj.cacheDetails) {
          await ProjectAnalyzerService.deleteCachePath(item.path);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cleaned ${_proj.formattedReclaimableSize} from ${_proj.name}'),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
          widget.onProjectUpdated();
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final innerBg = isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final totalMB = _proj.totalSizeMB <= 0 ? 1.0 : _proj.totalSizeMB;
    final codePct = (_proj.codeSizeMB / totalMB).clamp(0.05, 1.0);
    final nmPct = (_proj.nodeModulesSizeMB / totalMB).clamp(0.0, 1.0);
    final buildPct = (_proj.buildOutputSizeMB / totalMB).clamp(0.0, 1.0);
    final cachePct = (_proj.cacheSizeMB / totalMB).clamp(0.0, 1.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Modal Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: innerBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _proj.techColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _proj.techColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(_proj.techIcon, color: _proj.techColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _proj.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: _proj.techColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _proj.techColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _proj.techStackName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _proj.techColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _proj.fullPath,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: textSecondary,
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Health Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _proj.healthColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _proj.healthColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.health_and_safety_rounded, color: _proj.healthColor, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status: ${_proj.healthStatus}',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: _proj.healthColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _proj.healthMessage,
                                  style: TextStyle(fontSize: 12, color: textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Stats Bar
                    Row(
                      children: [
                        _buildQuickMetric('Total Project Size', _proj.formattedTotalSize, Icons.folder_rounded, AppTheme.emeraldGreen, isDark, textPrimary, textSecondary),
                        const SizedBox(width: 12),
                        _buildQuickMetric('Reclaimable Space', _proj.formattedReclaimableSize, Icons.cleaning_services_rounded, AppTheme.coralRose, isDark, textPrimary, textSecondary),
                        const SizedBox(width: 12),
                        _buildQuickMetric('Last Updated', _proj.relativeLastUpdated, Icons.history_toggle_off_rounded, AppTheme.amberGold, isDark, textPrimary, textSecondary),
                        const SizedBox(width: 12),
                        _buildQuickMetric('Source Files', '${_proj.totalFiles} files', Icons.insert_drive_file_rounded, AppTheme.primaryBlue, isDark, textPrimary, textSecondary),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Storage Composition Progress Bar
                    Text(
                      'Storage Distribution Breakdown',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 14,
                        child: Row(
                          children: [
                            if (codePct > 0) Expanded(flex: (codePct * 100).toInt() + 1, child: Container(color: AppTheme.primaryBlue)),
                            if (nmPct > 0) Expanded(flex: (nmPct * 100).toInt() + 1, child: Container(color: AppTheme.emeraldGreen)),
                            if (buildPct > 0) Expanded(flex: (buildPct * 100).toInt() + 1, child: Container(color: AppTheme.amberGold)),
                            if (cachePct > 0) Expanded(flex: (cachePct * 100).toInt() + 1, child: Container(color: AppTheme.purpleGlow)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildLegendItem('Source Code', ProjectAnalyzerService.formatSizeMB(_proj.codeSizeMB), AppTheme.primaryBlue, textSecondary),
                        if (_proj.nodeModulesSizeMB > 0)
                          _buildLegendItem('node_modules', ProjectAnalyzerService.formatSizeMB(_proj.nodeModulesSizeMB), AppTheme.emeraldGreen, textSecondary),
                        if (_proj.buildOutputSizeMB > 0)
                          _buildLegendItem('Build Output', ProjectAnalyzerService.formatSizeMB(_proj.buildOutputSizeMB), AppTheme.amberGold, textSecondary),
                        if (_proj.cacheSizeMB > 0)
                          _buildLegendItem('Dev Cache / PyVenv', ProjectAnalyzerService.formatSizeMB(_proj.cacheSizeMB), AppTheme.purpleGlow, textSecondary),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sub-Folders Detailed Breakdown
                    Text(
                      'Detected Heavy Subfolders & Dependencies',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    const SizedBox(height: 10),
                    if (_proj.cacheDetails.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: innerBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'No heavy node_modules or cache folders detected in this project!',
                              style: TextStyle(fontSize: 12.5, color: textSecondary),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: _proj.cacheDetails.map((sub) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: innerBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: sub.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(sub.icon, color: sub.color, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sub.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sub.description,
                                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: sub.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    sub.formattedSize,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: sub.color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                                  tooltip: 'Open in Finder',
                                  color: AppTheme.amberGold,
                                  onPressed: () => SystemStorageService.revealInFinder(sub.path),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _handleCleanSubItem(sub),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 14),
                                  label: const Text('Clean'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: sub.color.withValues(alpha: 0.15),
                                    foregroundColor: sub.color,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: sub.color.withValues(alpha: 0.4)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: innerBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => SystemStorageService.revealInFinder(_proj.fullPath),
                    icon: const Icon(Icons.folder_open_rounded, size: 16),
                    label: const Text('Open Project Directory'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const Spacer(),
                  if (_proj.reclaimableSizeMB > 0.5)
                    ElevatedButton.icon(
                      onPressed: _handleCleanAllReclaimable,
                      icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                      label: Text('Reclaim ${_proj.formattedReclaimableSize}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.coralRose,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMetric(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, String size, Color color, Color textSecondary) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11.5, color: textSecondary),
        ),
        Text(
          size,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
