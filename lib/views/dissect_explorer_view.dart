import 'dart:io';
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
  TreemapNode? _activeRootNode;
  final List<TreemapNode> _breadcrumbs = [];

  // Dev Bloat Filters
  bool _filterNode = true;
  bool _filterXcode = true;
  bool _filterDocker = false;

  // File Types Filter
  final Set<String> _selectedTypes = {'Video', 'Image', 'Doc', 'Dev', 'Archive', 'Other'};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final d = await SystemStorageService.fetchChexyData();
    if (mounted) {
      setState(() {
        _data = d;
        _activeRootNode = d.rootTreemapNode;
        _breadcrumbs.clear();
        _breadcrumbs.add(d.rootTreemapNode);
        _hoveredNode = d.rootTreemapNode.children.isNotEmpty ? d.rootTreemapNode.children.first : d.rootTreemapNode;
        _isLoading = false;
      });
    }
  }

  Future<void> _scanHome() async {
    if (_data == null) return;
    final homeNode = _data!.rootTreemapNode.children.firstWhere(
      (n) => n.name == 'Users',
      orElse: () => _data!.rootTreemapNode,
    );
    setState(() {
      _activeRootNode = homeNode;
      _breadcrumbs.clear();
      _breadcrumbs.add(_data!.rootTreemapNode);
      if (homeNode != _data!.rootTreemapNode) {
        _breadcrumbs.add(homeNode);
      }
      _hoveredNode = homeNode.children.isNotEmpty ? homeNode.children.first : homeNode;
    });
  }

  Future<void> _chooseCustomFolder() async {
    try {
      final res = await Process.run('osascript', [
        '-e',
        'POSIX path of (choose folder with prompt "Select folder on your Mac to analyze storage:")'
      ]);
      if (res.exitCode == 0) {
        final path = res.stdout.toString().trim();
        if (path.isNotEmpty) {
          setState(() => _isLoading = true);
          final node = await SystemStorageService.scanCustomFolder(path);
          if (node != null && mounted) {
            setState(() {
              _activeRootNode = node;
              _breadcrumbs.clear();
              _breadcrumbs.add(node);
              _hoveredNode = node.children.isNotEmpty ? node.children.first : node;
              _isLoading = false;
            });
          } else if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      }
    } catch (e) {
      debugPrint("Error choosing custom folder: $e");
    }
  }

  void _navigateToNode(TreemapNode node) {
    setState(() {
      _activeRootNode = node;
      if (!_breadcrumbs.contains(node)) {
        _breadcrumbs.add(node);
      } else {
        final idx = _breadcrumbs.indexOf(node);
        _breadcrumbs.removeRange(idx + 1, _breadcrumbs.length);
      }
      _hoveredNode = node.children.isNotEmpty ? node.children.first : node;
    });
  }

  void _navigateUp() {
    if (_breadcrumbs.length > 1) {
      setState(() {
        _breadcrumbs.removeLast();
        _activeRootNode = _breadcrumbs.last;
        _hoveredNode = _activeRootNode!.children.isNotEmpty ? _activeRootNode!.children.first : _activeRootNode;
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
    _loadData();
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
    _loadData();
  }

  List<TreemapNode> _filterChildren(List<TreemapNode> children) {
    return children.where((child) {
      final nameLower = child.name.toLowerCase();
      if (!_filterNode && (nameLower.contains('node') || nameLower.contains('npm'))) {
        return false;
      }
      if (!_filterXcode && (nameLower.contains('xcode') || nameLower.contains('deriveddata'))) {
        return false;
      }
      if (!_filterDocker && nameLower.contains('docker')) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppTheme.cardBgTranslucent : AppTheme.cardBgLight;
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final textPrimary = isDark ? AppTheme.textWhite : AppTheme.textDark;
    final textSecondary = isDark ? AppTheme.textSubtle : AppTheme.textMutedLight;

    if (_isLoading || _data == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.cyanGlow));
    }

    final d = _data!;
    final activeRoot = _activeRootNode ?? d.rootTreemapNode;
    final filteredChildren = _filterChildren(activeRoot.children);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar Control Panel
          SizedBox(
            width: 250,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                  ),
                ],
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
                      elevation: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _scanHome,
                    icon: const Icon(Icons.home_rounded, size: 16),
                    label: const Text('Scan Home'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      minimumSize: const Size(double.infinity, 38),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _chooseCustomFolder,
                    icon: const Icon(Icons.folder_open_rounded, size: 16),
                    label: const Text('Choose Folder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      minimumSize: const Size(double.infinity, 38),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DISK STORAGE GAUGE
                  Text('DISK STORAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 1.1)),
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
                              backgroundColor: borderColor,
                              color: AppTheme.cyanGlow,
                            ),
                            Text(
                              '${d.usedPercentage.toInt()}%',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total: ${d.totalGB} GB', style: TextStyle(fontSize: 11, color: textSecondary)),
                          Text('Used: ${d.usedGB} GB', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary)),
                          Text('Free: ${d.freeGB} GB', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.cyanGlow)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // DEV BLOAT FILTERS
                  Text('DEV BLOAT FILTERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 1.1)),
                  const SizedBox(height: 8),
                  _buildFilterCheckbox('Node.js', _filterNode, (val) => setState(() => _filterNode = val), textPrimary),
                  _buildFilterCheckbox('Xcode Caches', _filterXcode, (val) => setState(() => _filterXcode = val), textPrimary),
                  _buildFilterCheckbox('Docker Images', _filterDocker, (val) => setState(() => _filterDocker = val), textPrimary),
                  const SizedBox(height: 20),

                  // FILE TYPES LEGEND
                  Text('FILE TYPES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 1.1)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
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

          // Main Treemap Panel
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Status & Breadcrumb Trail Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const Icon(Icons.grid_view_rounded, color: AppTheme.cyanGlow, size: 20),
                              const SizedBox(width: 8),
                              for (int i = 0; i < _breadcrumbs.length; i++) ...[
                                if (i > 0)
                                  Icon(Icons.chevron_right_rounded, size: 16, color: textSecondary),
                                InkWell(
                                  onTap: () => _navigateToNode(_breadcrumbs[i]),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Text(
                                      _breadcrumbs[i].name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: i == _breadcrumbs.length - 1 ? FontWeight.w800 : FontWeight.w600,
                                        color: i == _breadcrumbs.length - 1 ? textPrimary : AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              Text(
                                ' • ${activeRoot.sizeGB} GB',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_breadcrumbs.length > 1)
                        OutlinedButton.icon(
                          onPressed: _navigateUp,
                          icon: const Icon(Icons.arrow_upward_rounded, size: 14),
                          label: const Text('Up Level'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Interactive Treemap Container
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF070A10) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: filteredChildren.isEmpty
                            ? Center(
                                child: Text(
                                  'No items inside ${activeRoot.name}',
                                  style: TextStyle(color: textSecondary, fontSize: 13),
                                ),
                              )
                            : Row(
                                children: filteredChildren.map((childNode) {
                                  return Expanded(
                                    flex: (childNode.sizeGB * 10).toInt().clamp(5, 100),
                                    child: _buildTreemapBox(childNode, currentLevel: 0),
                                  );
                                }).toList(),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Selected / Hovered Node Action Bar
                  if (_hoveredNode != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgDark : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.folder_open_rounded, color: AppTheme.cyanGlow, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _hoveredNode!.name,
                                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${_hoveredNode!.path} • ${_hoveredNode!.sizeGB} GB • ${_hoveredNode!.fileCount} item(s)',
                                        style: TextStyle(fontSize: 11, color: textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              if (_hoveredNode!.children.isNotEmpty && _hoveredNode != activeRoot)
                                ElevatedButton.icon(
                                  onPressed: () => _navigateToNode(_hoveredNode!),
                                  icon: const Icon(Icons.zoom_in_rounded, size: 15),
                                  label: const Text('Drill Down'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 2,
                                  ),
                                ),
                              const SizedBox(width: 8),
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

  Widget _buildFilterCheckbox(String label, bool value, ValueChanged<bool> onChanged, Color textPrimary) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            activeColor: AppTheme.primaryBlue,
            onChanged: (v) => onChanged(v ?? false),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: textPrimary)),
      ],
    );
  }

  Widget _buildTypeChip(String label, Color color) {
    final isSelected = _selectedTypes.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTypes.remove(label);
          } else {
            _selectedTypes.add(label);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreemapBox(TreemapNode node, {required int currentLevel}) {
    final isHovered = _hoveredNode?.path == node.path;
    final filteredChildren = _filterChildren(node.children);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredNode = node),
      child: GestureDetector(
        onTap: () {
          setState(() => _hoveredNode = node);
        },
        onDoubleTap: () {
          if (node.children.isNotEmpty) {
            _navigateToNode(node);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double height = constraints.maxHeight;

            // Only render sub-children if currentLevel < 1 and there is ample room (width >= 75px, height >= 60px)
            final bool renderSubChildren = currentLevel < 1 && filteredChildren.isNotEmpty && width >= 75 && height >= 60;

            Widget childContent;
            if (renderSubChildren) {
              childContent = Column(
                children: filteredChildren.map((c) {
                  return Expanded(
                    flex: (c.sizeGB * 10).toInt().clamp(5, 100),
                    child: _buildTreemapBox(c, currentLevel: currentLevel + 1),
                  );
                }).toList(),
              );
            } else {
              childContent = const SizedBox.shrink();
            }

            final paddingVal = height < 28 ? 2.0 : 5.0;

            return Container(
              margin: const EdgeInsets.all(2),
              padding: EdgeInsets.all(paddingVal),
              decoration: BoxDecoration(
                color: isHovered ? node.color.withValues(alpha: 0.95) : node.color.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isHovered ? Colors.white : node.color.withValues(alpha: 0.85),
                  width: isHovered ? 2.5 : 1,
                ),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color: node.color.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Compact single-line rendering for small height tiles
                  if (height < 36) ...[
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${node.name} • ${node.sizeGB} GB',
                          style: TextStyle(
                            fontSize: width < 50 ? 9 : 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Standard dual-line rendering for generous height tiles
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            node.name,
                            style: TextStyle(
                              fontSize: width < 50 ? 9.5 : (width < 90 ? 11 : 12),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                        if (node.children.isNotEmpty && width >= 60)
                          const Icon(Icons.subdirectory_arrow_right_rounded, color: Colors.white70, size: 12),
                      ],
                    ),
                    if (height >= 44 && width >= 45) ...[
                      const SizedBox(height: 1),
                      Text(
                        '${node.sizeGB} GB',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ],
                  ],

                  if (renderSubChildren) Expanded(child: childContent),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
