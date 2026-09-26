import 'package:flutter/material.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_delete_modal.dart';

class DissectExplorerView extends StatefulWidget {
  const DissectExplorerView({super.key});

  @override
  State<DissectExplorerView> createState() => _DissectExplorerViewState();
}

class _DissectExplorerViewState extends State<DissectExplorerView> {
  bool _isLoading = true;
  ChexyStorageData? _data;
  TreemapNode? _hoveredNode;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final d = await SystemStorageService.fetchChexyData();
    if (mounted) {
      setState(() {
        _data = d;
        _isLoading = false;
        _hoveredNode = d.rootTreemapNode.children.first;
      });
    }
  }

  void _handleTrashNode(TreemapNode node) async {
    final success = await SystemStorageService.moveToTrash(node.path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Moved ${node.name} to Trash' : 'Could not move ${node.name} to Trash'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _handleDeleteNode(TreemapNode node) async {
    final success = await SystemStorageService.deletePermanently(node.path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Permanently deleted ${node.name}' : 'Could not delete ${node.name}'),
        backgroundColor: AppTheme.coralRose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _data == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.cyanGlow));
    }

    final d = _data!;
    final root = d.rootTreemapNode;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar Control Panel (DissectMac Screenshot 2)
          SizedBox(
            width: 250,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardBgTranslucent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.search_rounded, size: 16),
                    label: const Text('Scan Full Mac'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.home_rounded, size: 16),
                    label: const Text('Scan Home'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textWhite,
                      minimumSize: const Size(double.infinity, 38),
                      side: const BorderSide(color: AppTheme.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.folder_open_rounded, size: 16),
                    label: const Text('Choose Folder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textWhite,
                      minimumSize: const Size(double.infinity, 38),
                      side: const BorderSide(color: AppTheme.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DISK STORAGE GAUGE
                  const Text('DISK STORAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSubtle, letterSpacing: 1.1)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: d.usedPercentage / 100,
                              strokeWidth: 6,
                              backgroundColor: AppTheme.borderColor,
                              color: AppTheme.cyanGlow,
                            ),
                            Text(
                              '${d.usedPercentage.toInt()}%',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textWhite),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total: ${d.totalGB} GB', style: const TextStyle(fontSize: 11, color: AppTheme.textSubtle)),
                          Text('Used: ${d.usedGB} GB', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textWhite)),
                          Text('Free: ${d.freeGB} GB', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.cyanGlow)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // DEV BLOAT FILTERS
                  const Text('DEV BLOAT FILTERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSubtle, letterSpacing: 1.1)),
                  const SizedBox(height: 8),
                  _buildFilterCheckbox('Node.js', true),
                  _buildFilterCheckbox('Xcode Caches', true),
                  _buildFilterCheckbox('Docker Images', false),
                  const SizedBox(height: 20),

                  // FILE TYPES LEGEND
                  const Text('FILE TYPES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSubtle, letterSpacing: 1.1)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildTypeChip('Video', AppTheme.amberGold),
                      _buildTypeChip('Image', AppTheme.emeraldGreen),
                      _buildTypeChip('Doc', AppTheme.cyanGlow),
                      _buildTypeChip('Dev', AppTheme.purpleGlow),
                      _buildTypeChip('Archive', AppTheme.coralRose),
                      _buildTypeChip('Other', AppTheme.primaryBlue),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Main Interactive Treemap Panel (DissectMac Treemap - Screenshot 2)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardBgTranslucent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Status Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.grid_view_rounded, color: AppTheme.cyanGlow, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Macintosh HD Storage Treemap • ${d.totalGB} GB',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textWhite),
                          ),
                        ],
                      ),
                      if (_hoveredNode != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.cyanGlow.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.cyanGlow.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'Selected: ${_hoveredNode!.path} (${_hoveredNode!.sizeGB} GB • ${_hoveredNode!.fileCount} files)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.cyanGlow),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nested Interactive Treemap Grid (Screenshot 2)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF070A10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: root.children.map((childNode) {
                            return Expanded(
                              flex: (childNode.sizeGB * 10).toInt().clamp(1, 100),
                              child: _buildTreemapBox(childNode),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Hovered Node Actions Bar
                  if (_hoveredNode != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.folder_open_rounded, color: AppTheme.cyanGlow, size: 20),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _hoveredNode!.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textWhite),
                                  ),
                                  Text(
                                    '${_hoveredNode!.path} • ${_hoveredNode!.sizeGB} GB • ${_hoveredNode!.fileCount} files',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSubtle),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.folder_open_rounded, color: AppTheme.cyanGlow, size: 20),
                                tooltip: 'Reveal in Finder',
                                onPressed: () => SystemStorageService.revealInFinder(_hoveredNode!.path),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.primaryBlue, size: 20),
                                tooltip: 'Move to Trash',
                                onPressed: () => _handleTrashNode(_hoveredNode!),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.coralRose, size: 20),
                                tooltip: 'Permanent Delete',
                                onPressed: () {
                                  ConfirmDeleteModal.show(
                                    context: context,
                                    itemName: _hoveredNode!.name,
                                    itemPath: _hoveredNode!.path,
                                    itemSize: '${_hoveredNode!.sizeGB} GB',
                                    onMoveToTrash: () => _handleTrashNode(_hoveredNode!),
                                    onConfirmPermanentDelete: () => _handleDeleteNode(_hoveredNode!),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCheckbox(String label, bool value) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            activeColor: AppTheme.primaryBlue,
            onChanged: (v) {},
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textWhite)),
      ],
    );
  }

  Widget _buildTypeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildTreemapBox(TreemapNode node) {
    final isHovered = _hoveredNode?.path == node.path;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredNode = node),
      child: GestureDetector(
        onTap: () => setState(() => _hoveredNode = node),
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHovered ? node.color.withValues(alpha: 0.9) : node.color.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isHovered ? Colors.white : node.color.withValues(alpha: 0.8),
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                node.name,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${node.sizeGB} GB',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 4),
              if (node.children.isNotEmpty)
                Expanded(
                  child: Row(
                    children: node.children.map((c) {
                      return Expanded(
                        flex: (c.sizeGB * 10).toInt().clamp(1, 100),
                        child: _buildTreemapBox(c),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
