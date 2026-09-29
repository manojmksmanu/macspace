import 'dart:io';
import 'package:flutter/material.dart';
import '../models/storage_item.dart';
import '../services/system_storage_service.dart';
import '../services/user_preferences_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_delete_modal.dart';
import '../widgets/cute_app_loader.dart';
import '../widgets/deletion_loading_modal.dart';
import '../widgets/image_preview_modal.dart';

class TrashView extends StatefulWidget {
  const TrashView({super.key});

  @override
  State<TrashView> createState() => _TrashViewState();
}

class _TrashViewState extends State<TrashView> {
  List<StorageFile> _allTrashItems = [];
  List<StorageFile> _filteredTrashItems = [];
  final Set<StorageFile> _selectedItems = {};

  bool _loading = true;
  ViewMode _viewMode = ViewMode.grid;
  GridCardSize _gridCardSize = GridCardSize.medium;
  bool _isMultiSelectEnabled = false;
  StorageFile? _hoveredItem;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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

    if (mounted) {
      setState(() {
        _viewMode = savedMode;
        _gridCardSize = savedSize;
      });
    }

    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await SystemStorageService.fetchRealTrashFiles();
    if (mounted) {
      setState(() {
        _allTrashItems = list;
        _selectedItems.clear();
        _applySearchFilter();
        _loading = false;
      });
    }
  }

  void _applySearchFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredTrashItems = List.from(_allTrashItems);
    } else {
      final q = _searchQuery.trim().toLowerCase();
      _filteredTrashItems = _allTrashItems.where((i) => i.name.toLowerCase().contains(q) || i.path.toLowerCase().contains(q)).toList();
    }
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val;
      _applySearchFilter();
    });
  }

  void _onViewModeChanged(ViewMode mode) {
    setState(() => _viewMode = mode);
    UserPreferencesService.setViewMode(mode);
  }

  void _onGridCardSizeChanged(GridCardSize size) {
    setState(() => _gridCardSize = size);
    UserPreferencesService.setGridCardSize(size);
  }

  void _emptyTrash() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppTheme.coralRose, size: 24),
            SizedBox(width: 10),
            Text('Empty macOS Trash Bin?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently empty all items in your macOS Trash? This action cannot be undone.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: const Text('Empty Trash'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.coralRose,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await DeletionLoadingModal.show(
      context: context,
      title: 'Emptying macOS Trash Bin...',
      subTitle: 'Permanently removing all trashed files & folders...',
      onDeleteTask: () async {
        try {
          await Process.run('osascript', ['-e', 'tell application "Finder" to empty trash without warnings']);
        } catch (_) {
          final home = Platform.environment['HOME'] ?? '';
          await Process.run('rm', ['-rf', '$home/.Trash/*']);
        }
        return true;
      },
    );

    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('macOS Trash bin emptied successfully!'),
          backgroundColor: AppTheme.emeraldGreen,
        ),
      );
    }
  }

  void _toggleSelection(StorageFile item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedItems.length == _filteredTrashItems.length) {
        _selectedItems.clear();
      } else {
        _selectedItems.clear();
        _selectedItems.addAll(_filteredTrashItems);
      }
    });
  }

  void _handleDeleteSelectedPermanently() async {
    if (_selectedItems.isEmpty) return;
    final itemsToDelete = List<StorageFile>.from(_selectedItems);
    final totalGB = itemsToDelete.fold<double>(0, (sum, i) => sum + i.sizeGB);
    final formattedSize = SystemStorageService.formatFileSizeGB(totalGB);

    ConfirmDeleteModal.show(
      context: context,
      itemName: '${itemsToDelete.length} Selected Trash Items',
      itemPath: '~/.Trash',
      itemSize: formattedSize,
      onMoveToTrash: null,
      onConfirmPermanentDelete: () async {
        int count = 0;
        for (final item in itemsToDelete) {
          final success = await SystemStorageService.deletePermanently(item.path);
          if (success) count++;
        }

        if (mounted) {
          setState(() {
            _allTrashItems.removeWhere((i) => itemsToDelete.contains(i));
            _applySearchFilter();
            _selectedItems.clear();
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

  void _showContextMenu(BuildContext context, Offset position, StorageFile item) async {
    final expandedPath = item.path;
    final isImage = SystemStorageService.isImageFile(item.name) || SystemStorageService.isImageFile(expandedPath);
    final isFolder = Directory(expandedPath).existsSync();
    final isSelected = _selectedItems.contains(item);
    final formattedSize = SystemStorageService.formatFileSizeGB(item.sizeGB);

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
        _toggleSelection(item);
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
          imageName: item.name,
          fileSizeFormatted: formattedSize,
        );
        break;
      case 'delete':
        ConfirmDeleteModal.show(
          context: context,
          itemName: item.name,
          itemPath: expandedPath,
          itemSize: formattedSize,
          onMoveToTrash: null,
          onConfirmPermanentDelete: () async {
            final ok = await SystemStorageService.deletePermanently(expandedPath);
            if (ok && mounted) {
              setState(() {
                _allTrashItems.remove(item);
                _applySearchFilter();
                _selectedItems.remove(item);
              });
            }
          },
        );
        break;
    }
  }

  Widget _buildItemIconOrImage(StorageFile item, {double size = 42}) {
    final expandedPath = item.path;
    final isImage = SystemStorageService.isImageFile(item.name) || SystemStorageService.isImageFile(expandedPath);
    final file = File(expandedPath);

    if (isImage && file.existsSync()) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.5)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppTheme.coralRose.withValues(alpha: 0.18),
                child: Icon(item.icon, color: AppTheme.coralRose, size: size * 0.5),
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
        color: AppTheme.coralRose.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(item.icon, color: AppTheme.coralRose, size: size * 0.5),
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

    final selectedTotalGB = _selectedItems.fold<double>(0, (sum, i) => sum + i.sizeGB);
    final selectedSizeFmt = SystemStorageService.formatFileSizeGB(selectedTotalGB);

    if (_loading) {
      return const Center(
        child: CuteAppLoader(
          message: 'Scanning Trash...',
          subMessage: 'Retrieving recoverable files & cache',
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
                              colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'macOS Trash Bin Purger',
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
                      'Showing ${_filteredTrashItems.length} of ${_allTrashItems.length} items in ~/.Trash',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Multi-Select Toggle Button
                    Tooltip(
                      message: 'Toggle Multi-Select Mode',
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isMultiSelectEnabled = !_isMultiSelectEnabled;
                            if (!_isMultiSelectEnabled) _selectedItems.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isMultiSelectEnabled || _selectedItems.isNotEmpty
                                ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                                : cardBgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isMultiSelectEnabled || _selectedItems.isNotEmpty
                                  ? AppTheme.primaryBlue
                                  : borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.select_all_rounded,
                                size: 16,
                                color: _isMultiSelectEnabled || _selectedItems.isNotEmpty ? AppTheme.primaryBlue : textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Multi-Select',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isMultiSelectEnabled || _selectedItems.isNotEmpty ? AppTheme.primaryBlue : textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Grid Card Size Selector (S, M, L, XL) - Only in Grid Mode!
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
                            _buildGridSizeBtn(GridCardSize.small, 'S', 'Small Cards'),
                            _buildGridSizeBtn(GridCardSize.medium, 'M', 'Medium Cards'),
                            _buildGridSizeBtn(GridCardSize.large, 'L', 'Large Cards'),
                            _buildGridSizeBtn(GridCardSize.xlarge, 'XL', 'Hero Cards'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],

                    // View Switcher (Persisted!)
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
                    const SizedBox(width: 12),

                    ElevatedButton.icon(
                      onPressed: _allTrashItems.isEmpty ? null : _emptyTrash,
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: const Text('Empty Trash Bin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.coralRose,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search Bar inside Trash
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.coralRose.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.search_rounded, size: 16, color: AppTheme.coralRose),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search deleted items in Trash by name...',
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
            const SizedBox(height: 14),

            // Multi-Select Batch Action Bar
            if (_selectedItems.isNotEmpty || _isMultiSelectEnabled) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.coralRose.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.coralRose.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _selectedItems.isNotEmpty && _selectedItems.length == _filteredTrashItems.length,
                      tristate: _selectedItems.isNotEmpty && _selectedItems.length < _filteredTrashItems.length,
                      activeColor: AppTheme.coralRose,
                      onChanged: (v) => _toggleSelectAll(),
                    ),
                    Text(
                      _selectedItems.isEmpty
                          ? 'Select All Trash (${_filteredTrashItems.length})'
                          : '${_selectedItems.length} Selected ($selectedSizeFmt)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedItems.isNotEmpty) ...[
                      ElevatedButton.icon(
                        onPressed: _handleDeleteSelectedPermanently,
                        icon: const Icon(Icons.delete_forever_rounded, size: 16),
                        label: const Text('Delete Selected Permanently'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.coralRose,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSubtle),
                      tooltip: 'Clear Selection',
                      onPressed: () => setState(() => _selectedItems.clear()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

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
                child: _filteredTrashItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'Trash Bin is Empty!',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No deleted files currently accumulating space in ~/.Trash',
                              style: TextStyle(fontSize: 12, color: textSecondary),
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

  Widget _buildListView(Color innerCardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    return ListView.builder(
      itemCount: _filteredTrashItems.length,
      itemBuilder: (context, index) {
        final item = _filteredTrashItems[index];
        final expandedPath = item.path;
        final isImage = SystemStorageService.isImageFile(item.name) || SystemStorageService.isImageFile(expandedPath);
        final isSelected = _selectedItems.contains(item);
        final formattedSize = SystemStorageService.formatFileSizeGB(item.sizeGB);

        return GestureDetector(
          onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition, item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.coralRose.withValues(alpha: 0.15) : innerCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.coralRose : borderColor.withValues(alpha: 0.5),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                if (_isMultiSelectEnabled || _selectedItems.isNotEmpty) ...[
                  Checkbox(
                    value: isSelected,
                    activeColor: AppTheme.coralRose,
                    onChanged: (_) => _toggleSelection(item),
                  ),
                  const SizedBox(width: 4),
                ],
                InkWell(
                  onTap: () {
                    if (isImage) {
                      ImagePreviewModal.show(
                        context: context,
                        imagePath: expandedPath,
                        imageName: item.name,
                        fileSizeFormatted: formattedSize,
                      );
                    } else {
                      SystemStorageService.openFile(expandedPath);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: _buildItemIconOrImage(item, size: 42),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_isMultiSelectEnabled) {
                        _toggleSelection(item);
                      } else if (isImage) {
                        ImagePreviewModal.show(
                          context: context,
                          imagePath: expandedPath,
                          imageName: item.name,
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
                        Text(
                          item.name,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(item.path, style: TextStyle(fontSize: 11, color: textSecondary), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formattedSize,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: isImage ? AppTheme.emeraldGreen : textPrimary),
                ),
                const SizedBox(width: 14),
                if (isImage)
                  IconButton(
                    icon: const Icon(Icons.image_rounded, color: AppTheme.emeraldGreen, size: 20),
                    tooltip: 'Preview Image',
                    onPressed: () => ImagePreviewModal.show(
                      context: context,
                      imagePath: expandedPath,
                      imageName: item.name,
                      fileSizeFormatted: formattedSize,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.folder_open_rounded, color: AppTheme.cyanGlow, size: 20),
                  tooltip: 'Show in Finder',
                  onPressed: () => SystemStorageService.revealInFinder(expandedPath),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.coralRose, size: 20),
                  tooltip: 'Delete Permanently',
                  onPressed: () {
                    ConfirmDeleteModal.show(
                      context: context,
                      itemName: item.name,
                      itemPath: expandedPath,
                      itemSize: formattedSize,
                      onMoveToTrash: () => SystemStorageService.deletePermanently(expandedPath),
                      onConfirmPermanentDelete: () {
                        SystemStorageService.deletePermanently(expandedPath);
                        setState(() {
                          _allTrashItems.remove(item);
                          _applySearchFilter();
                          _selectedItems.remove(item);
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
      itemCount: _filteredTrashItems.length,
      itemBuilder: (context, index) {
        final item = _filteredTrashItems[index];
        final expandedPath = item.path;
        final isImage = SystemStorageService.isImageFile(item.name) || SystemStorageService.isImageFile(expandedPath);
        final file = File(expandedPath);
        final isSelected = _selectedItems.contains(item);
        final formattedSize = SystemStorageService.formatFileSizeGB(item.sizeGB);
        final isHovered = _hoveredItem == item;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredItem = item),
          onExit: (_) => setState(() => _hoveredItem = null),
          child: GestureDetector(
            onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition, item),
            child: InkWell(
              onTap: () {
                if (_isMultiSelectEnabled) {
                  _toggleSelection(item);
                } else if (isImage) {
                  ImagePreviewModal.show(
                    context: context,
                    imagePath: expandedPath,
                    imageName: item.name,
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
                      ? AppTheme.coralRose.withValues(alpha: 0.15)
                      : (isHovered ? innerCardBg.withValues(alpha: 0.9) : innerCardBg),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.coralRose
                        : (isHovered ? AppTheme.coralRose.withValues(alpha: 0.6) : borderColor.withValues(alpha: 0.6)),
                    width: isSelected || isHovered ? 1.8 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppTheme.coralRose.withValues(alpha: 0.2)
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
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.coralRose.withValues(alpha: 0.08),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            ),
                            child: isImage && file.existsSync()
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                    child: Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Icon(item.icon, color: AppTheme.coralRose, size: _gridCardSize == GridCardSize.small ? 26 : 38),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(item.icon, color: AppTheme.coralRose, size: _gridCardSize == GridCardSize.small ? 26 : 38),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: _gridCardSize == GridCardSize.small ? 11.5 : 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formattedSize,
                                    style: TextStyle(
                                      fontSize: _gridCardSize == GridCardSize.small ? 10 : 11,
                                      fontWeight: FontWeight.w800,
                                      color: isImage ? AppTheme.emeraldGreen : AppTheme.coralRose,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (isImage)
                                        InkWell(
                                          onTap: () => ImagePreviewModal.show(
                                            context: context,
                                            imagePath: expandedPath,
                                            imageName: item.name,
                                            fileSizeFormatted: formattedSize,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.all(2),
                                            child: Icon(Icons.image_rounded, size: 15, color: AppTheme.emeraldGreen),
                                          ),
                                        ),
                                      InkWell(
                                        onTap: () => SystemStorageService.revealInFinder(expandedPath),
                                        child: const Padding(
                                          padding: EdgeInsets.all(2),
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

                    // Selection Checkbox Overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => _toggleSelection(item),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.coralRose : Colors.black.withValues(alpha: 0.45),
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
