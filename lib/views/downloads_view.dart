import 'dart:io';
import 'package:flutter/material.dart';
import '../models/storage_item.dart';
import '../services/system_storage_service.dart';
import '../services/user_preferences_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_delete_modal.dart';
import '../widgets/cute_app_loader.dart';
import '../widgets/image_preview_modal.dart';

class DownloadsView extends StatefulWidget {
  const DownloadsView({super.key});

  @override
  State<DownloadsView> createState() => _DownloadsViewState();
}

class _DownloadsViewState extends State<DownloadsView> {
  List<StorageFile> _allFiles = [];
  List<StorageFile> _filteredFiles = [];
  final Set<StorageFile> _selectedFiles = {};

  bool _loading = true;
  ViewMode _viewMode = ViewMode.grid;
  GridCardSize _gridCardSize = GridCardSize.medium;
  bool _isMultiSelectEnabled = false;

  String _searchQuery = '';
  String _selectedFilterCategory = 'all'; // all, image, video, doc, archive, app
  String _sortOption = 'size_desc'; // size_desc, size_asc, name_asc

  final TextEditingController _searchController = TextEditingController();
  StorageFile? _hoveredFile;

  @override
  void initState() {
    super.initState();
    _loadPreferencesAndData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferencesAndData() async {
    await UserPreferencesService.init();
    final savedMode = UserPreferencesService.getViewMode();
    final savedSize = UserPreferencesService.getGridCardSize();
    final savedSort = UserPreferencesService.getSortOption();

    if (mounted) {
      setState(() {
        _viewMode = savedMode;
        _gridCardSize = savedSize;
        _sortOption = savedSort;
      });
    }

    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final list = await SystemStorageService.fetchRealDownloads();
    if (mounted) {
      setState(() {
        _allFiles = list;
        _selectedFiles.clear();
        _applyFiltersAndSort();
        _loading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    List<StorageFile> result = List.from(_allFiles);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result.where((f) => f.name.toLowerCase().contains(q) || f.path.toLowerCase().contains(q)).toList();
    }

    if (_selectedFilterCategory != 'all') {
      result = result.where((f) {
        final pathLower = (f.path.isNotEmpty ? f.path : f.name).toLowerCase();
        switch (_selectedFilterCategory) {
          case 'image':
            return SystemStorageService.isImageFile(pathLower);
          case 'video':
            return pathLower.endsWith('.mp4') || pathLower.endsWith('.mov') || pathLower.endsWith('.mkv') || pathLower.endsWith('.avi');
          case 'doc':
            return pathLower.endsWith('.pdf') || pathLower.endsWith('.docx') || pathLower.endsWith('.txt') || pathLower.endsWith('.xlsx') || pathLower.endsWith('.csv');
          case 'archive':
            return pathLower.endsWith('.zip') || pathLower.endsWith('.dmg') || pathLower.endsWith('.pkg') || pathLower.endsWith('.tar.gz') || pathLower.endsWith('.iso');
          case 'app':
            return pathLower.endsWith('.app');
          default:
            return true;
        }
      }).toList();
    }

    switch (_sortOption) {
      case 'size_desc':
        result.sort((a, b) => b.sizeGB.compareTo(a.sizeGB));
        break;
      case 'size_asc':
        result.sort((a, b) => a.sizeGB.compareTo(b.sizeGB));
        break;
      case 'name_asc':
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }

    _filteredFiles = result;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFiltersAndSort();
    });
  }

  void _onCategoryFilterSelected(String cat) {
    setState(() {
      _selectedFilterCategory = cat;
      _applyFiltersAndSort();
    });
  }

  void _onSortChanged(String sort) {
    setState(() {
      _sortOption = sort;
      _applyFiltersAndSort();
    });
    UserPreferencesService.setSortOption(sort);
  }

  void _onViewModeChanged(ViewMode mode) {
    setState(() => _viewMode = mode);
    UserPreferencesService.setViewMode(mode);
  }

  void _onGridCardSizeChanged(GridCardSize size) {
    setState(() => _gridCardSize = size);
    UserPreferencesService.setGridCardSize(size);
  }

  String _getExpandedPath(String pathOrName) {
    final home = Platform.environment['HOME'] ?? '';
    if (pathOrName.startsWith('~/')) {
      return pathOrName.replaceAll('~', home);
    }
    if (pathOrName.startsWith('/')) {
      return pathOrName;
    }
    return '$home/Downloads/$pathOrName';
  }

  void _toggleSelection(StorageFile f) {
    setState(() {
      if (_selectedFiles.contains(f)) {
        _selectedFiles.remove(f);
      } else {
        _selectedFiles.add(f);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedFiles.length == _filteredFiles.length) {
        _selectedFiles.clear();
      } else {
        _selectedFiles.clear();
        _selectedFiles.addAll(_filteredFiles);
      }
    });
  }

  void _handleTrashSelected() async {
    if (_selectedFiles.isEmpty) return;
    final listToTrash = List<StorageFile>.from(_selectedFiles);
    int count = 0;

    for (final f in listToTrash) {
      final expandedPath = _getExpandedPath(f.path.isNotEmpty ? f.path : f.name);
      final success = await SystemStorageService.moveToTrash(expandedPath);
      if (success) count++;
    }

    if (mounted) {
      setState(() {
        _allFiles.removeWhere((f) => listToTrash.contains(f));
        _selectedFiles.clear();
        _applyFiltersAndSort();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved $count items to Trash'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    }
  }

  void _handleDeleteSelectedPermanently() async {
    if (_selectedFiles.isEmpty) return;
    final listToDelete = List<StorageFile>.from(_selectedFiles);
    final totalGB = listToDelete.fold<double>(0, (sum, f) => sum + f.sizeGB);
    final formattedSize = SystemStorageService.formatFileSizeGB(totalGB);

    ConfirmDeleteModal.show(
      context: context,
      itemName: '${listToDelete.length} Selected Downloads',
      itemPath: '~/Downloads',
      itemSize: formattedSize,
      onMoveToTrash: _handleTrashSelected,
      onConfirmPermanentDelete: () async {
        int count = 0;
        for (final f in listToDelete) {
          final expandedPath = _getExpandedPath(f.path.isNotEmpty ? f.path : f.name);
          final success = await SystemStorageService.deletePermanently(expandedPath);
          if (success) count++;
        }

        if (mounted) {
          setState(() {
            _allFiles.removeWhere((f) => listToDelete.contains(f));
            _selectedFiles.clear();
            _applyFiltersAndSort();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permanently deleted $count items ($formattedSize)'),
              backgroundColor: AppTheme.coralRose,
            ),
          );
        }
      },
    );
  }

  void _showContextMenu(BuildContext context, Offset position, StorageFile f) async {
    final expandedPath = _getExpandedPath(f.path.isNotEmpty ? f.path : f.name);
    final isImage = SystemStorageService.isImageFile(f.name) || SystemStorageService.isImageFile(expandedPath);
    final isFolder = Directory(expandedPath).existsSync();
    final isSelected = _selectedFiles.contains(f);
    final formattedSize = SystemStorageService.formatFileSizeGB(f.sizeGB);

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      color: const Color(0xFF1E293B),
      items: [
        PopupMenuItem<String>(
          value: 'select',
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_box_outlined : Icons.check_box_outline_blank_rounded,
                size: 18,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 10),
              Text(
                isSelected ? 'Deselect Item' : 'Select Item',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'open',
          child: Row(
            children: [
              Icon(
                isFolder ? Icons.folder_open_rounded : Icons.open_in_new_rounded,
                size: 18,
                color: AppTheme.cyanGlow,
              ),
              const SizedBox(width: 10),
              Text(
                isFolder ? 'Open Folder' : 'Open File',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
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
    );

    if (value == null || !mounted) return;
    switch (value) {
      case 'select':
        _toggleSelection(f);
        break;
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
          imageName: f.name,
          fileSizeFormatted: formattedSize,
        );
        break;
      case 'trash':
        SystemStorageService.moveToTrash(expandedPath);
        setState(() {
          _allFiles.remove(f);
          _selectedFiles.remove(f);
          _applyFiltersAndSort();
        });
        break;
      case 'delete':
        ConfirmDeleteModal.show(
          context: context,
          itemName: f.name,
          itemPath: expandedPath,
          itemSize: formattedSize,
          onMoveToTrash: () {
            SystemStorageService.moveToTrash(expandedPath);
            setState(() {
              _allFiles.remove(f);
              _selectedFiles.remove(f);
              _applyFiltersAndSort();
            });
          },
          onConfirmPermanentDelete: () {
            SystemStorageService.deletePermanently(expandedPath);
            setState(() {
              _allFiles.remove(f);
              _selectedFiles.remove(f);
              _applyFiltersAndSort();
            });
          },
        );
        break;
    }
  }

  String _getFileExtensionTag(String name) {
    final parts = name.split('.');
    if (parts.length > 1) {
      final ext = parts.last.toUpperCase();
      if (ext.length <= 5) return ext;
    }
    return 'FILE';
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'PNG':
      case 'JPG':
      case 'JPEG':
      case 'WEBP':
      case 'GIF':
      case 'SVG':
      case 'HEIC':
        return AppTheme.emeraldGreen;
      case 'MP4':
      case 'MOV':
      case 'MKV':
        return AppTheme.purpleGlow;
      case 'PDF':
      case 'DOCX':
      case 'TXT':
        return AppTheme.cyanGlow;
      case 'ZIP':
      case 'DMG':
      case 'PKG':
        return AppTheme.amberGold;
      case 'APP':
        return AppTheme.primaryBlue;
      default:
        return AppTheme.primaryBlue;
    }
  }

  Widget _buildItemIconOrImage(StorageFile f, {double size = 44}) {
    final expandedPath = _getExpandedPath(f.path.isNotEmpty ? f.path : f.name);
    final isImage = SystemStorageService.isImageFile(f.name) || SystemStorageService.isImageFile(expandedPath);
    final file = File(expandedPath);

    if (isImage && file.existsSync()) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: f.iconColor.withValues(alpha: 0.18),
                child: Icon(f.icon, color: f.iconColor, size: size * 0.5),
              );
            },
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: f.iconColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: f.iconColor.withValues(alpha: 0.3)),
      ),
      child: Icon(f.icon, color: f.iconColor, size: size * 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgCanvas = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBgColor = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.9) : Colors.white;
    final innerCardBg = isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final selectedTotalGB = _selectedFiles.fold<double>(0, (sum, f) => sum + f.sizeGB);
    final selectedSizeFmt = SystemStorageService.formatFileSizeGB(selectedTotalGB);

    if (_loading) {
      return const Center(
        child: CuteAppLoader(
          message: 'Scanning Downloads Folder...',
          subMessage: 'Retrieving media, archives, installers & documents',
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgCanvas,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Downloads Folder Analyzer',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Showing ${_filteredFiles.length} of ${_allFiles.length} items in ~/Downloads',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),

                // Controls Group: Multi-Select, Grid Size, Grid/List Mode, Refresh
                Row(
                  children: [
                    // Multi-Select Toggle Button
                    Tooltip(
                      message: 'Toggle Multi-Select Mode',
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isMultiSelectEnabled = !_isMultiSelectEnabled;
                            if (!_isMultiSelectEnabled) _selectedFiles.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isMultiSelectEnabled || _selectedFiles.isNotEmpty
                                ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                                : cardBgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isMultiSelectEnabled || _selectedFiles.isNotEmpty
                                  ? AppTheme.primaryBlue
                                  : borderColor,
                              width: 1.2,
                            ),
                            boxShadow: _isMultiSelectEnabled
                                ? [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.25), blurRadius: 8)]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.select_all_rounded,
                                size: 16,
                                color: _isMultiSelectEnabled || _selectedFiles.isNotEmpty ? AppTheme.primaryBlue : textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Multi-Select',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isMultiSelectEnabled || _selectedFiles.isNotEmpty ? AppTheme.primaryBlue : textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Grid Card Size Density Switcher (S, M, L, XL) - Only in Grid Mode!
                    if (_viewMode == ViewMode.grid) ...[
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            _buildGridSizeBtn(GridCardSize.small, 'S', 'Small Cards (Compact)'),
                            _buildGridSizeBtn(GridCardSize.medium, 'M', 'Medium Cards (Standard)'),
                            _buildGridSizeBtn(GridCardSize.large, 'L', 'Large Cards (Detailed)'),
                            _buildGridSizeBtn(GridCardSize.xlarge, 'XL', 'Hero Cards (Extra Bada)'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],

                    // View Mode Switcher (Grid vs List) - Persisted!
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Tooltip(
                            message: 'List View',
                            child: InkWell(
                              onTap: () => _onViewModeChanged(ViewMode.list),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: _viewMode == ViewMode.list ? AppTheme.primaryBlue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _viewMode == ViewMode.list
                                      ? [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.3), blurRadius: 6)]
                                      : [],
                                ),
                                child: Icon(
                                  Icons.format_list_bulleted_rounded,
                                  size: 18,
                                  color: _viewMode == ViewMode.list ? Colors.white : textSecondary,
                                ),
                              ),
                            ),
                          ),
                          Tooltip(
                            message: 'Grid View',
                            child: InkWell(
                              onTap: () => _onViewModeChanged(ViewMode.grid),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: _viewMode == ViewMode.grid ? AppTheme.primaryBlue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _viewMode == ViewMode.grid
                                      ? [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.3), blurRadius: 6)]
                                      : [],
                                ),
                                child: Icon(
                                  Icons.grid_view_rounded,
                                  size: 18,
                                  color: _viewMode == ViewMode.grid ? Colors.white : textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh_rounded, size: 17),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search Bar, Filter Pills & Sort Selector Row
            Row(
              children: [
                // Live Search Input Box
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.cyanGlow.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search_rounded, size: 16, color: AppTheme.cyanGlow),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Search files by name or type...',
                              hintStyle: TextStyle(fontSize: 12.5, color: textSecondary),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          InkWell(
                            onTap: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black12,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.textSubtle),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Quick Filter Category Segmented Pill Bar
                Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: innerCardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFilterPill('all', 'All Files', Icons.folder_copy_rounded, isDark),
                        _buildFilterPill('image', 'Images', Icons.image_rounded, isDark),
                        _buildFilterPill('video', 'Videos', Icons.movie_rounded, isDark),
                        _buildFilterPill('doc', 'Docs', Icons.description_rounded, isDark),
                        _buildFilterPill('archive', 'Archives', Icons.archive_rounded, isDark),
                        _buildFilterPill('app', 'Apps', Icons.apps_rounded, isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Sort Dropdown Selector
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortOption,
                      icon: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppTheme.primaryBlue),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary),
                      onChanged: (val) => val != null ? _onSortChanged(val) : null,
                      items: [
                        DropdownMenuItem(
                          value: 'size_desc',
                          child: Row(
                            children: const [
                              Icon(Icons.arrow_downward_rounded, size: 14, color: AppTheme.amberGold),
                              SizedBox(width: 8),
                              Text('Largest First'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'size_asc',
                          child: Row(
                            children: const [
                              Icon(Icons.arrow_upward_rounded, size: 14, color: AppTheme.cyanGlow),
                              SizedBox(width: 8),
                              Text('Smallest First'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'name_asc',
                          child: Row(
                            children: const [
                              Icon(Icons.sort_by_alpha_rounded, size: 14, color: AppTheme.emeraldGreen),
                              SizedBox(width: 8),
                              Text('Name A-Z'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Multi-Select Batch Action Bar
            if (_selectedFiles.isNotEmpty || _isMultiSelectEnabled) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _selectedFiles.isNotEmpty && _selectedFiles.length == _filteredFiles.length,
                      tristate: _selectedFiles.isNotEmpty && _selectedFiles.length < _filteredFiles.length,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (v) => _toggleSelectAll(),
                    ),
                    Text(
                      _selectedFiles.isEmpty
                          ? 'Select All (${_filteredFiles.length})'
                          : '${_selectedFiles.length} Selected ($selectedSizeFmt)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedFiles.isNotEmpty) ...[
                      ElevatedButton.icon(
                        onPressed: _handleTrashSelected,
                        icon: const Icon(Icons.delete_outline_rounded, size: 15),
                        label: const Text('Move Selected to Trash'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _handleDeleteSelectedPermanently,
                        icon: const Icon(Icons.delete_forever_rounded, size: 15),
                        label: const Text('Delete Permanently'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.coralRose,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSubtle),
                      tooltip: 'Clear Selection',
                      onPressed: () => setState(() => _selectedFiles.clear()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Main Content Area
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _filteredFiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.find_in_page_rounded, size: 48, color: AppTheme.amberGold),
                            const SizedBox(height: 12),
                            Text(
                              'No matching files in Downloads',
                              style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try changing your search query or file filter pills above',
                              style: TextStyle(color: textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : _viewMode == ViewMode.grid
                        ? _buildGridView(innerCardBg, borderColor, textPrimary, textSecondary)
                        : _buildListView(innerCardBg, borderColor, textPrimary, textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSizeBtn(GridCardSize size, String label, String tooltip) {
    final isSelected = _gridCardSize == size;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _onGridCardSizeChanged(size),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.3), blurRadius: 4)] : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String key, String label, IconData icon, bool isDark) {
    final isSelected = _selectedFilterCategory == key;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: () => _onCategoryFilterSelected(key),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppTheme.primaryBlue, Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(Color innerCardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    return ListView.builder(
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        final f = _filteredFiles[index];
        final expandedPath = _getExpandedPath(f.path.isNotEmpty ? f.path : f.name);
        final isImage = SystemStorageService.isImageFile(f.name) || SystemStorageService.isImageFile(expandedPath);
        final isSelected = _selectedFiles.contains(f);
        final formattedSize = SystemStorageService.formatFileSizeGB(f.sizeGB);
        final extTag = _getFileExtensionTag(f.name);
        final tagColor = _getTagColor(extTag);

        return GestureDetector(
          onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition, f),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.15) : innerCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : borderColor.withValues(alpha: 0.5),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                if (_isMultiSelectEnabled || _selectedFiles.isNotEmpty) ...[
                  Checkbox(
                    value: isSelected,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (_) => _toggleSelection(f),
                  ),
                  const SizedBox(width: 4),
                ],
                InkWell(
                  onTap: () {
                    if (isImage) {
                      ImagePreviewModal.show(
                        context: context,
                        imagePath: expandedPath,
                        imageName: f.name,
                        fileSizeFormatted: formattedSize,
                      );
                    } else {
                      SystemStorageService.openFile(expandedPath);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: _buildItemIconOrImage(f, size: 42),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_isMultiSelectEnabled) {
                        _toggleSelection(f);
                      } else if (isImage) {
                        ImagePreviewModal.show(
                          context: context,
                          imagePath: expandedPath,
                          imageName: f.name,
                          fileSizeFormatted: formattedSize,
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
                                f.name,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: tagColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                extTag,
                                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: tagColor),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${f.path} • ${f.type}',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formattedSize,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isImage ? AppTheme.emeraldGreen : textPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                if (isImage)
                  IconButton(
                    icon: const Icon(Icons.image_rounded, color: AppTheme.emeraldGreen, size: 20),
                    tooltip: 'Preview Image',
                    onPressed: () => ImagePreviewModal.show(
                      context: context,
                      imagePath: expandedPath,
                      imageName: f.name,
                      fileSizeFormatted: formattedSize,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.folder_open_rounded, color: AppTheme.cyanGlow, size: 20),
                  tooltip: 'Show in Finder',
                  onPressed: () => SystemStorageService.revealInFinder(expandedPath),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.coralRose, size: 20),
                  tooltip: 'Delete',
                  onPressed: () {
                    ConfirmDeleteModal.show(
                      context: context,
                      itemName: f.name,
                      itemPath: expandedPath,
                      itemSize: formattedSize,
                      onMoveToTrash: () {
                        SystemStorageService.moveToTrash(expandedPath);
                        setState(() {
                          _allFiles.remove(f);
                          _selectedFiles.remove(f);
                          _applyFiltersAndSort();
                        });
                      },
                      onConfirmPermanentDelete: () {
                        SystemStorageService.deletePermanently(expandedPath);
                        setState(() {
                          _allFiles.remove(f);
                          _selectedFiles.remove(f);
                          _applyFiltersAndSort();
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(Color innerCardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    double maxExtent;
    double aspectRatio;

    switch (_gridCardSize) {
      case GridCardSize.small:
        maxExtent = 175;
        aspectRatio = 0.88;
        break;
      case GridCardSize.medium:
        maxExtent = 235;
        aspectRatio = 0.92;
        break;
      case GridCardSize.large:
        maxExtent = 330;
        aspectRatio = 0.98;
        break;
      case GridCardSize.xlarge:
        maxExtent = 460;
        aspectRatio = 1.05;
        break;
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxExtent,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: aspectRatio,
      ),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        final f = _filteredFiles[index];
        final expandedPath = _getExpandedPath(f.path.isNotEmpty ? f.path : f.name);
        final isImage = SystemStorageService.isImageFile(f.name) || SystemStorageService.isImageFile(expandedPath);
        final file = File(expandedPath);
        final isSelected = _selectedFiles.contains(f);
        final formattedSize = SystemStorageService.formatFileSizeGB(f.sizeGB);
        final isHovered = _hoveredFile == f;

        final extTag = _getFileExtensionTag(f.name);
        final tagColor = _getTagColor(extTag);

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredFile = f),
          onExit: (_) => setState(() => _hoveredFile = null),
          child: GestureDetector(
            onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition, f),
            child: InkWell(
              onTap: () {
                if (_isMultiSelectEnabled) {
                  _toggleSelection(f);
                } else if (isImage) {
                  ImagePreviewModal.show(
                    context: context,
                    imagePath: expandedPath,
                    imageName: f.name,
                    fileSizeFormatted: formattedSize,
                  );
                } else {
                  SystemStorageService.openFile(expandedPath);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                      : (isHovered ? innerCardBg.withValues(alpha: 0.9) : innerCardBg),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : (isHovered ? AppTheme.primaryBlue.withValues(alpha: 0.6) : borderColor.withValues(alpha: 0.6)),
                    width: isSelected || isHovered ? 1.8 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                          : (isHovered ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05)),
                      blurRadius: isHovered ? 12 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Image Header
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: f.iconColor.withValues(alpha: 0.08),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            ),
                            child: isImage && file.existsSync()
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.file(
                                          file,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Center(
                                            child: Icon(f.icon, color: f.iconColor, size: _gridCardSize == GridCardSize.small ? 26 : 38),
                                          ),
                                        ),
                                        if (isHovered)
                                          Container(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            child: const Center(
                                              child: Icon(Icons.zoom_in_rounded, color: Colors.white, size: 28),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      f.icon,
                                      color: f.iconColor,
                                      size: _gridCardSize == GridCardSize.small ? 26 : 40,
                                    ),
                                  ),
                          ),
                        ),

                        // Card Footer Metadata
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.name,
                                style: TextStyle(
                                  fontSize: _gridCardSize == GridCardSize.small ? 11.5 : 13,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (isImage ? AppTheme.emeraldGreen : AppTheme.primaryBlue).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      formattedSize,
                                      style: TextStyle(
                                        fontSize: _gridCardSize == GridCardSize.small ? 10 : 11,
                                        fontWeight: FontWeight.w800,
                                        color: isImage ? AppTheme.emeraldGreen : AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (isImage)
                                        InkWell(
                                          onTap: () => ImagePreviewModal.show(
                                            context: context,
                                            imagePath: expandedPath,
                                            imageName: f.name,
                                            fileSizeFormatted: formattedSize,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.all(3),
                                            child: Icon(Icons.image_rounded, size: 15, color: AppTheme.emeraldGreen),
                                          ),
                                        ),
                                      InkWell(
                                        onTap: () => SystemStorageService.revealInFinder(expandedPath),
                                        child: const Padding(
                                          padding: EdgeInsets.all(3),
                                          child: Icon(Icons.folder_open_rounded, size: 15, color: AppTheme.cyanGlow),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Extension Tag Badge Overlay (top-left)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: tagColor.withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          extTag,
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: tagColor),
                        ),
                      ),
                    ),

                    // Selection Overlay Circle (top-right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => _toggleSelection(f),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryBlue : Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
