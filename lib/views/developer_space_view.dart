import 'package:flutter/material.dart';
import '../services/developer_space_service.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_delete_modal.dart';
import '../widgets/cute_app_loader.dart';

class DeveloperSpaceView extends StatefulWidget {
  const DeveloperSpaceView({super.key});

  @override
  State<DeveloperSpaceView> createState() => _DeveloperSpaceViewState();
}

class _DeveloperSpaceViewState extends State<DeveloperSpaceView> {
  bool _loading = true;
  String _scanStatus = 'Scanning developer environment...';
  double _scanProgress = 0.0;

  DevSpaceSummary? _summary;
  List<DevJunkItem> _filteredItems = [];
  final Set<DevJunkItem> _selectedItems = {};
  bool _isMultiSelectEnabled = false;

  String _searchQuery = '';
  String _typeFilter = 'all'; // all, node_modules, xcode, flutter, caches, python_rust
  String _sortOption = 'size_desc'; // size_desc, size_asc, name_asc, age_desc

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scanDeveloperSpace();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanDeveloperSpace() async {
    setState(() {
      _loading = true;
      _scanProgress = 0.05;
      _scanStatus = 'Initializing Developer Space Scanner...';
    });

    final summary = await DeveloperSpaceService.scanDeveloperSpace(
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _scanProgress = progress;
            _scanStatus = status;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _summary = summary;
        _selectedItems.clear();
        _applyFiltersAndSort();
        _loading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    if (_summary == null) return;
    List<DevJunkItem> result = List.from(_summary!.items);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result
          .where((i) =>
              i.projectName.toLowerCase().contains(q) ||
              i.fullPath.toLowerCase().contains(q) ||
              i.typeName.toLowerCase().contains(q))
          .toList();
    }

    if (_typeFilter != 'all') {
      result = result.where((i) {
        switch (_typeFilter) {
          case 'node_modules':
            return i.type == DevJunkType.nodeModules;
          case 'xcode':
            return i.type == DevJunkType.xcodeDerivedData || i.type == DevJunkType.xcodeArchives;
          case 'flutter':
            return i.type == DevJunkType.flutterBuild;
          case 'caches':
            return i.type == DevJunkType.cocoapodsCache ||
                i.type == DevJunkType.gradleCache ||
                i.type == DevJunkType.npmYarnCache;
          case 'python_rust':
            return i.type == DevJunkType.pythonVenv || i.type == DevJunkType.rustTarget;
          default:
            return true;
        }
      }).toList();
    }

    switch (_sortOption) {
      case 'size_desc':
        result.sort((a, b) => b.sizeMB.compareTo(a.sizeMB));
        break;
      case 'size_asc':
        result.sort((a, b) => a.sizeMB.compareTo(b.sizeMB));
        break;
      case 'name_asc':
        result.sort((a, b) => a.projectName.toLowerCase().compareTo(b.projectName.toLowerCase()));
        break;
      case 'age_desc':
        result.sort((a, b) => a.lastModified.compareTo(b.lastModified));
        break;
    }

    _filteredItems = result;
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val;
      _applyFiltersAndSort();
    });
  }

  void _onFilterChanged(String cat) {
    setState(() {
      _typeFilter = cat;
      _applyFiltersAndSort();
    });
  }

  void _onSortChanged(String sort) {
    setState(() {
      _sortOption = sort;
      _applyFiltersAndSort();
    });
  }

  void _toggleSelection(DevJunkItem item) {
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
      if (_selectedItems.length == _filteredItems.length) {
        _selectedItems.clear();
      } else {
        _selectedItems.clear();
        _selectedItems.addAll(_filteredItems);
      }
    });
  }

  void _handleCleanSingleItem(DevJunkItem item) async {
    ConfirmDeleteModal.show(
      context: context,
      itemName: '${item.projectName} (${item.typeName})',
      itemPath: item.fullPath,
      itemSize: item.formattedSize,
      onMoveToTrash: () async {
        final success = await SystemStorageService.moveToTrash(item.fullPath);
        if (success && mounted) {
          setState(() {
            _summary!.items.remove(item);
            _selectedItems.remove(item);
            _applyFiltersAndSort();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Moved ${item.projectName} junk to Trash'),
              backgroundColor: AppTheme.primaryBlue,
            ),
          );
        }
      },
      onConfirmPermanentDelete: () async {
        final success = await DeveloperSpaceService.cleanJunkItem(item);
        if (success && mounted) {
          setState(() {
            _summary!.items.remove(item);
            _selectedItems.remove(item);
            _applyFiltersAndSort();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permanently cleaned ${item.projectName} (${item.formattedSize})'),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
        }
      },
    );
  }

  void _handleCleanSelectedItems() async {
    if (_selectedItems.isEmpty) return;
    final listToClean = List<DevJunkItem>.from(_selectedItems);
    final totalMB = listToClean.fold<double>(0, (sum, i) => sum + i.sizeMB);
    final totalFormatted = DeveloperSpaceService.formatSizeMB(totalMB);

    ConfirmDeleteModal.show(
      context: context,
      itemName: '${listToClean.length} Selected Developer Items',
      itemPath: 'Developer Storage Caches & node_modules',
      itemSize: totalFormatted,
      onMoveToTrash: () async {
        int count = 0;
        for (final item in listToClean) {
          final ok = await SystemStorageService.moveToTrash(item.fullPath);
          if (ok) count++;
        }
        if (mounted) {
          setState(() {
            _summary!.items.removeWhere((i) => listToClean.contains(i));
            _selectedItems.clear();
            _applyFiltersAndSort();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Moved $count items ($totalFormatted) to Trash'),
              backgroundColor: AppTheme.primaryBlue,
            ),
          );
        }
      },
      onConfirmPermanentDelete: () async {
        int count = 0;
        for (final item in listToClean) {
          final ok = await DeveloperSpaceService.cleanJunkItem(item);
          if (ok) count++;
        }
        if (mounted) {
          setState(() {
            _summary!.items.removeWhere((i) => listToClean.contains(i));
            _selectedItems.clear();
            _applyFiltersAndSort();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permanently deleted $count items ($totalFormatted)'),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
        }
      },
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

    if (_loading) {
      return Scaffold(
        backgroundColor: bgCanvas,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CuteAppLoader(
                message: _scanStatus,
                subMessage: 'Scanning node_modules, Xcode DerivedData, Flutter builds & dev caches...',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 320,
                child: LinearProgressIndicator(
                  value: _scanProgress > 0 ? _scanProgress : null,
                  backgroundColor: borderColor,
                  color: AppTheme.cyanGlow,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalMBSelected = _selectedItems.fold<double>(0, (sum, i) => sum + i.sizeMB);
    final formattedSelectedSize = DeveloperSpaceService.formatSizeMB(totalMBSelected);

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.developer_board_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Developer Space & Junk Inspector 🛠️',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Detect node_modules, Xcode DerivedData, Flutter builds, Gradle & package caches',
                          style: TextStyle(fontSize: 12.5, color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),

                // Controls & Scan Refresh Button
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isMultiSelectEnabled || _selectedItems.isNotEmpty
                                ? AppTheme.emeraldGreen.withValues(alpha: 0.2)
                                : cardBgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isMultiSelectEnabled || _selectedItems.isNotEmpty
                                  ? AppTheme.emeraldGreen
                                  : borderColor,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.select_all_rounded,
                                size: 16,
                                color: _isMultiSelectEnabled || _selectedItems.isNotEmpty
                                    ? AppTheme.emeraldGreen
                                    : textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Multi-Select',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isMultiSelectEnabled || _selectedItems.isNotEmpty
                                      ? AppTheme.emeraldGreen
                                      : textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    ElevatedButton.icon(
                      onPressed: _scanDeveloperSpace,
                      icon: const Icon(Icons.sync_rounded, size: 17),
                      label: const Text('Rescan Dev Space'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top Hero Summary Stats Cards Row
            Row(
              children: [
                _buildHeroStatCard(
                  title: 'Total Dev Storage',
                  value: '${_summary?.totalSizeGB ?? 0.0} GB',
                  subtitle: '${_summary?.totalItemCount ?? 0} Dev Items Found',
                  icon: Icons.storage_rounded,
                  color: AppTheme.emeraldGreen,
                  cardBgColor: cardBgColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(width: 12),
                _buildHeroStatCard(
                  title: 'node_modules Total',
                  value: '${_summary?.nodeModulesSizeGB ?? 0.0} GB',
                  subtitle: 'NPM / Yarn Dependencies',
                  icon: Icons.hexagon_outlined,
                  color: const Color(0xFF10B981),
                  cardBgColor: cardBgColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(width: 12),
                _buildHeroStatCard(
                  title: 'Xcode Caches',
                  value: '${_summary?.xcodeSizeGB ?? 0.0} GB',
                  subtitle: 'DerivedData & Archives',
                  icon: Icons.developer_mode_rounded,
                  color: AppTheme.primaryBlue,
                  cardBgColor: cardBgColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(width: 12),
                _buildHeroStatCard(
                  title: 'Flutter / Dart Builds',
                  value: '${_summary?.flutterBuildSizeGB ?? 0.0} GB',
                  subtitle: 'build/ & .dart_tool/',
                  icon: Icons.flutter_dash_rounded,
                  color: AppTheme.cyanGlow,
                  cardBgColor: cardBgColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(width: 12),
                _buildHeroStatCard(
                  title: 'Package Manager Caches',
                  value: '${_summary?.packageCachesGB ?? 0.0} GB',
                  subtitle: 'Gradle, CocoaPods, NPM',
                  icon: Icons.widgets_rounded,
                  color: AppTheme.amberGold,
                  cardBgColor: cardBgColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar, Filter Pills & Sort Row
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
                            color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search_rounded, size: 16, color: AppTheme.emeraldGreen),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Search dev projects by name or path...',
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

                // Category Filter Segmented Track Bar
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
                      children: [
                        _buildFilterPill('all', 'All Items', Icons.apps_rounded, isDark),
                        _buildFilterPill('node_modules', 'node_modules', Icons.hexagon_outlined, isDark),
                        _buildFilterPill('xcode', 'Xcode Caches', Icons.developer_mode_rounded, isDark),
                        _buildFilterPill('flutter', 'Flutter Build', Icons.flutter_dash_rounded, isDark),
                        _buildFilterPill('caches', 'Pkg Caches', Icons.widgets_rounded, isDark),
                        _buildFilterPill('python_rust', 'Py & Rust', Icons.terminal_rounded, isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Sort Selector
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
                        child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppTheme.emeraldGreen),
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

            // Multi-Select Action Bar
            if (_selectedItems.isNotEmpty || _isMultiSelectEnabled) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _selectedItems.isNotEmpty && _selectedItems.length == _filteredItems.length,
                      tristate: _selectedItems.isNotEmpty && _selectedItems.length < _filteredItems.length,
                      activeColor: AppTheme.emeraldGreen,
                      onChanged: (v) => _toggleSelectAll(),
                    ),
                    Text(
                      _selectedItems.isEmpty
                          ? 'Select All (${_filteredItems.length})'
                          : '${_selectedItems.length} Selected ($formattedSelectedSize)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedItems.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _handleCleanSelectedItems,
                        icon: const Icon(Icons.delete_forever_rounded, size: 15),
                        label: Text('Clean ${_selectedItems.length} Items ($formattedSelectedSize)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Main Content ListView
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 48, color: AppTheme.emeraldGreen.withValues(alpha: 0.7)),
                          const SizedBox(height: 12),
                          Text(
                            'No developer junk found matching search query!',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your developer space is clean and optimized.',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = _selectedItems.contains(item);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? item.themeColor.withValues(alpha: 0.12) : cardBgColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? item.themeColor : borderColor,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              if (_isMultiSelectEnabled || _selectedItems.isNotEmpty) ...[
                                Checkbox(
                                  value: isSelected,
                                  activeColor: item.themeColor,
                                  onChanged: (_) => _toggleSelection(item),
                                ),
                                const SizedBox(width: 8),
                              ],

                              // Type Icon Container
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: item.themeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: item.themeColor.withValues(alpha: 0.3)),
                                ),
                                child: Icon(item.icon, color: item.themeColor, size: 22),
                              ),
                              const SizedBox(width: 14),

                              // Item Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item.projectName,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: item.themeColor.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: item.themeColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            item.typeName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: item.themeColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.fullPath,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: textSecondary,
                                        fontFamily: 'monospace',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '💡 ${item.safeToCleanNote}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Size Badge & Action Buttons
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item.themeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.formattedSize,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: item.themeColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.folder_open_rounded, size: 18),
                                        tooltip: 'Show in Finder',
                                        color: AppTheme.amberGold,
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(6),
                                        onPressed: () => SystemStorageService.revealInFinder(item.fullPath),
                                      ),
                                      const SizedBox(width: 4),
                                      ElevatedButton.icon(
                                        onPressed: () => _handleCleanSingleItem(item),
                                        icon: const Icon(Icons.delete_outline_rounded, size: 14),
                                        label: const Text('Clean Junk'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: item.themeColor.withValues(alpha: 0.15),
                                          foregroundColor: item.themeColor,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: BorderSide(color: item.themeColor.withValues(alpha: 0.4)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color cardBgColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 8,
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
                Text(
                  title,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textSecondary),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10.5, color: textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String key, String label, IconData icon, bool isDark) {
    final isSelected = _typeFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: () => _onFilterChanged(key),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppTheme.emeraldGreen, Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.emeraldGreen.withValues(alpha: 0.35),
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
}
