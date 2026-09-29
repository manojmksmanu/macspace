import 'dart:io';
import 'package:flutter/material.dart';
import '../models/project_info.dart';
import '../services/developer_space_service.dart';
import '../services/project_analyzer_service.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_delete_modal.dart';
import '../widgets/cute_app_loader.dart';
import '../widgets/project_inspector_modal.dart';

class DeveloperSpaceView extends StatefulWidget {
  const DeveloperSpaceView({super.key});

  @override
  State<DeveloperSpaceView> createState() => _DeveloperSpaceViewState();
}

class _DeveloperSpaceViewState extends State<DeveloperSpaceView> {
  // Tab Selection: 0 = Projects Folder Inspector, 1 = System Dev Junk Cleaner
  int _selectedTab = 0;

  // --- TAB 0: Projects Folder Inspector State ---
  String _currentFolderPath = '';
  List<ProjectInfo> _allProjects = [];
  List<ProjectInfo> _filteredProjects = [];
  final Set<ProjectInfo> _selectedProjects = {};
  bool _projectsLoading = false;
  double _projectsScanProgress = 0.0;
  String _projectsScanStatus = '';

  String _projectSearchQuery = '';
  String _projectTechFilter = 'all'; // all, node_react, flutter, python_rust, reclaimable, inactive
  String _projectSortOption = 'reclaimable_desc'; // reclaimable_desc, size_desc, updated_desc, name_asc
  final TextEditingController _projectSearchController = TextEditingController();

  // Predefined quick folders
  final List<String> _quickFolderPaths = [];

  // --- TAB 1: System Dev Junk State ---
  bool _junkLoading = true;
  String _junkScanStatus = 'Scanning developer environment...';
  double _junkScanProgress = 0.0;

  DevSpaceSummary? _junkSummary;
  List<DevJunkItem> _filteredJunkItems = [];
  final Set<DevJunkItem> _selectedJunkItems = {};
  bool _isJunkMultiSelect = false;

  String _junkSearchQuery = '';
  String _junkTypeFilter = 'all'; // all, node_modules, xcode, flutter, caches, python_rust
  String _junkSortOption = 'size_desc'; // size_desc, size_asc, name_asc, age_desc
  final TextEditingController _junkSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDefaultFolders();
    _scanProjectsFolder(_currentFolderPath);
    _scanSystemDevJunk();
  }

  void _initDefaultFolders() {
    final home = Platform.environment['HOME'] ?? '';
    if (home.isNotEmpty) {
      final candidates = [
        '$home/Desktop/dev',
        '$home/dev',
        '$home/Projects',
        '$home/Desktop',
        '$home/Documents',
        '$home/code',
        '$home/workspace',
        '$home/Downloads',
      ];
      for (final p in candidates) {
        if (Directory(p).existsSync()) {
          _quickFolderPaths.add(p);
        }
      }
      if (_quickFolderPaths.isNotEmpty) {
        _currentFolderPath = _quickFolderPaths.first;
      } else {
        _currentFolderPath = home;
      }
    } else {
      _currentFolderPath = '/';
    }
  }

  @override
  void dispose() {
    _projectSearchController.dispose();
    _junkSearchController.dispose();
    super.dispose();
  }

  // ==========================================
  // TAB 0: PROJECTS FOLDER ANALYZER LOGIC
  // ==========================================
  Future<void> _scanProjectsFolder(String path) async {
    if (path.isEmpty || !Directory(path).existsSync()) return;

    setState(() {
      _currentFolderPath = path;
      _projectsLoading = true;
      _projectsScanProgress = 0.05;
      _projectsScanStatus = 'Analyzing folder: ${path.split('/').last}...';
      _selectedProjects.clear();
    });

    final projects = await ProjectAnalyzerService.scanProjectsFolder(
      folderPath: path,
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _projectsScanProgress = progress;
            _projectsScanStatus = status;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _allProjects = projects;
        _applyProjectFiltersAndSort();
        _projectsLoading = false;
      });
    }
  }

  Future<void> _handlePickCustomFolder() async {
    final picked = await ProjectAnalyzerService.pickProjectsFolder();
    if (picked != null && picked.isNotEmpty && mounted) {
      if (!_quickFolderPaths.contains(picked)) {
        _quickFolderPaths.insert(0, picked);
      }
      _scanProjectsFolder(picked);
    }
  }

  void _applyProjectFiltersAndSort() {
    List<ProjectInfo> result = List.from(_allProjects);

    // Search Query
    if (_projectSearchQuery.trim().isNotEmpty) {
      final q = _projectSearchQuery.trim().toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.fullPath.toLowerCase().contains(q) ||
            p.techStackName.toLowerCase().contains(q) ||
            p.healthStatus.toLowerCase().contains(q);
      }).toList();
    }

    // Filter
    if (_projectTechFilter != 'all') {
      result = result.where((p) {
        switch (_projectTechFilter) {
          case 'node_react':
            return p.techStack == ProjectTechStack.reactNode || p.techStack == ProjectTechStack.nextJs;
          case 'flutter':
            return p.techStack == ProjectTechStack.flutter;
          case 'python_rust':
            return p.techStack == ProjectTechStack.python || p.techStack == ProjectTechStack.rust;
          case 'reclaimable':
            return p.reclaimableSizeMB > 20.0;
          case 'inactive':
            return p.isInactive;
          default:
            return true;
        }
      }).toList();
    }

    // Sort
    switch (_projectSortOption) {
      case 'reclaimable_desc':
        result.sort((a, b) => b.reclaimableSizeMB.compareTo(a.reclaimableSizeMB));
        break;
      case 'size_desc':
        result.sort((a, b) => b.totalSizeMB.compareTo(a.totalSizeMB));
        break;
      case 'updated_desc':
        result.sort((a, b) => b.lastModified.compareTo(a.lastModified));
        break;
      case 'name_asc':
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }

    _filteredProjects = result;
  }

  void _handleCleanAllInactiveProjects(List<ProjectInfo> inactiveProjects) async {
    if (inactiveProjects.isEmpty) return;
    final totalMB = inactiveProjects.fold<double>(0, (sum, p) => sum + p.reclaimableSizeMB);
    final formattedSize = ProjectAnalyzerService.formatSizeMB(totalMB);

    ConfirmDeleteModal.show(
      context: context,
      itemName: '${inactiveProjects.length} Inactive Projects (Not updated in 30+ days)',
      itemPath: 'node_modules, build outputs, and caches of inactive projects: ${inactiveProjects.map((e) => e.name).join(", ")}',
      itemSize: formattedSize,
      onMoveToTrash: () async {
        int count = 0;
        for (final p in inactiveProjects) {
          for (final sub in p.cacheDetails) {
            final ok = await SystemStorageService.moveToTrash(sub.path);
            if (ok) count++;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Moved $count cache folders ($formattedSize) from inactive projects to Trash'),
              backgroundColor: AppTheme.primaryBlue,
            ),
          );
          _scanProjectsFolder(_currentFolderPath);
        }
      },
      onConfirmPermanentDelete: () async {
        int count = 0;
        for (final p in inactiveProjects) {
          for (final sub in p.cacheDetails) {
            final ok = await ProjectAnalyzerService.deleteCachePath(sub.path);
            if (ok) count++;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permanently cleaned $count cache folders ($formattedSize) from inactive projects'),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
          _scanProjectsFolder(_currentFolderPath);
        }
      },
    );
  }

  void _handleCleanSingleProjectCache(ProjectInfo p) async {
    ConfirmDeleteModal.show(
      context: context,
      itemName: 'Cache & node_modules for ${p.name}',
      itemPath: '${p.fullPath} (node_modules, build output, caches)',
      itemSize: p.formattedReclaimableSize,
      onMoveToTrash: () async {
        int count = 0;
        for (final sub in p.cacheDetails) {
          final ok = await SystemStorageService.moveToTrash(sub.path);
          if (ok) count++;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Moved ${p.name} cache folders (${p.formattedReclaimableSize}) to Trash'),
              backgroundColor: AppTheme.primaryBlue,
            ),
          );
          _scanProjectsFolder(_currentFolderPath);
        }
      },
      onConfirmPermanentDelete: () async {
        int count = 0;
        for (final sub in p.cacheDetails) {
          final ok = await ProjectAnalyzerService.deleteCachePath(sub.path);
          if (ok) count++;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permanently cleaned ${p.formattedReclaimableSize} from ${p.name}'),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
          _scanProjectsFolder(_currentFolderPath);
        }
      },
    );
  }

  void _handleCleanSelectedProjectsCache() async {
    if (_selectedProjects.isEmpty) return;

    final list = List<ProjectInfo>.from(_selectedProjects);
    final totalReclaimableMB = list.fold<double>(0, (sum, p) => sum + p.reclaimableSizeMB);
    final formattedSize = ProjectAnalyzerService.formatSizeMB(totalReclaimableMB);

    ConfirmDeleteModal.show(
      context: context,
      itemName: '${list.length} Selected Projects Cache & node_modules',
      itemPath: 'node_modules, build outputs, and caches across ${list.length} projects',
      itemSize: formattedSize,
      onMoveToTrash: () async {
        int count = 0;
        for (final p in list) {
          for (final sub in p.cacheDetails) {
            final ok = await SystemStorageService.moveToTrash(sub.path);
            if (ok) count++;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Moved $count cache folders ($formattedSize) to Trash'),
              backgroundColor: AppTheme.primaryBlue,
            ),
          );
          _scanProjectsFolder(_currentFolderPath);
        }
      },
      onConfirmPermanentDelete: () async {
        int count = 0;
        for (final p in list) {
          for (final sub in p.cacheDetails) {
            final ok = await ProjectAnalyzerService.deleteCachePath(sub.path);
            if (ok) count++;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permanently cleaned $count cache folders ($formattedSize)'),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
          _scanProjectsFolder(_currentFolderPath);
        }
      },
    );
  }

  // ==========================================
  // TAB 1: SYSTEM DEV JUNK SCANNER LOGIC
  // ==========================================
  Future<void> _scanSystemDevJunk() async {
    setState(() {
      _junkLoading = true;
      _junkScanProgress = 0.05;
      _junkScanStatus = 'Initializing Developer Space Scanner...';
    });

    final summary = await DeveloperSpaceService.scanDeveloperSpace(
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _junkScanProgress = progress;
            _junkScanStatus = status;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _junkSummary = summary;
        _selectedJunkItems.clear();
        _applyJunkFiltersAndSort();
        _junkLoading = false;
      });
    }
  }

  void _applyJunkFiltersAndSort() {
    if (_junkSummary == null) return;
    List<DevJunkItem> result = List.from(_junkSummary!.items);

    if (_junkSearchQuery.trim().isNotEmpty) {
      final q = _junkSearchQuery.trim().toLowerCase();
      result = result
          .where((i) =>
              i.projectName.toLowerCase().contains(q) ||
              i.fullPath.toLowerCase().contains(q) ||
              i.typeName.toLowerCase().contains(q))
          .toList();
    }

    if (_junkTypeFilter != 'all') {
      result = result.where((i) {
        switch (_junkTypeFilter) {
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

    switch (_junkSortOption) {
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

    _filteredJunkItems = result;
  }

  void _handleCleanSingleJunkItem(DevJunkItem item) async {
    ConfirmDeleteModal.show(
      context: context,
      itemName: '${item.projectName} (${item.typeName})',
      itemPath: item.fullPath,
      itemSize: item.formattedSize,
      onMoveToTrash: () async {
        final success = await SystemStorageService.moveToTrash(item.fullPath);
        if (success && mounted) {
          setState(() {
            _junkSummary!.items.remove(item);
            _selectedJunkItems.remove(item);
            _applyJunkFiltersAndSort();
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
            _junkSummary!.items.remove(item);
            _selectedJunkItems.remove(item);
            _applyJunkFiltersAndSort();
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

  void _handleCleanSelectedJunkItems() async {
    if (_selectedJunkItems.isEmpty) return;
    final listToClean = List<DevJunkItem>.from(_selectedJunkItems);
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
            _junkSummary!.items.removeWhere((i) => listToClean.contains(i));
            _selectedJunkItems.clear();
            _applyJunkFiltersAndSort();
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
            _junkSummary!.items.removeWhere((i) => listToClean.contains(i));
            _selectedJunkItems.clear();
            _applyJunkFiltersAndSort();
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

  // ==========================================
  // BUILD MAIN UI
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCanvas = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBgColor = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.9) : Colors.white;
    final innerCardBg = isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgCanvas,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header & Mode Tab Switcher
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
                          'Developer Space & Projects Inspector 🛠️',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Analyze node_modules, last updated timestamps, build outputs & dev storage caches',
                          style: TextStyle(fontSize: 12.5, color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),

                // Tab Mode Switcher Segmented Button
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: innerCardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      _buildMainTabButton(
                        index: 0,
                        title: 'Projects Folder Analyzer',
                        icon: Icons.folder_special_rounded,
                        isDark: isDark,
                      ),
                      _buildMainTabButton(
                        index: 1,
                        title: 'System Dev Caches',
                        icon: Icons.cleaning_services_rounded,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Tab Content
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildProjectsFolderTab(cardBgColor, innerCardBg, borderColor, textPrimary, textSecondary, isDark),
                  _buildSystemDevJunkTab(cardBgColor, innerCardBg, borderColor, textPrimary, textSecondary, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabButton({
    required int index,
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppTheme.emeraldGreen, Color(0xFF059669)],
                )
              : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.emeraldGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0 BUILDER: PROJECTS FOLDER ANALYZER
  // ==========================================
  Widget _buildProjectsFolderTab(
    Color cardBgColor,
    Color innerCardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    if (_projectsLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CuteAppLoader(
              message: _projectsScanStatus,
              subMessage: 'Searching project directories, node_modules, last modified times & build caches...',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 340,
              child: LinearProgressIndicator(
                value: _projectsScanProgress > 0 ? _projectsScanProgress : null,
                backgroundColor: borderColor,
                color: AppTheme.emeraldGreen,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      );
    }

    final totalProjectsCount = _allProjects.length;
    final totalFolderSizeMB = _allProjects.fold<double>(0, (sum, p) => sum + p.totalSizeMB);
    final totalNodeModulesMB = _allProjects.fold<double>(0, (sum, p) => sum + p.nodeModulesSizeMB);
    final totalReclaimableMB = _allProjects.fold<double>(0, (sum, p) => sum + p.reclaimableSizeMB);

    final inactiveProjectsWithCache = _allProjects.where((p) => p.isInactive && p.reclaimableSizeMB > 5.0).toList();
    final inactiveTotalReclaimableMB = inactiveProjectsWithCache.fold<double>(0, (sum, p) => sum + p.reclaimableSizeMB);
    final inactiveCount = _allProjects.where((p) => p.isInactive).length;

    final selectedReclaimableMB = _selectedProjects.fold<double>(0, (sum, p) => sum + p.reclaimableSizeMB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Folder Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder_special_rounded, color: AppTheme.emeraldGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Projects Search Folder',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _currentFolderPath,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Quick Folder Dropdown
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _quickFolderPaths.contains(_currentFolderPath) ? _currentFolderPath : null,
                  hint: Text('Quick Folders', style: TextStyle(fontSize: 12, color: textSecondary)),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.emeraldGreen),
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                  onChanged: (val) {
                    if (val != null) _scanProjectsFolder(val);
                  },
                  items: _quickFolderPaths.map((path) {
                    return DropdownMenuItem(
                      value: path,
                      child: Text(path.split('/').last.isEmpty ? path : '📁 ${path.split('/').last} ($path)'),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 10),

              // Select Custom Folder Native Button
              ElevatedButton.icon(
                onPressed: _handlePickCustomFolder,
                icon: const Icon(Icons.create_new_folder_rounded, size: 16),
                label: const Text('Select Projects Folder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),

              IconButton(
                onPressed: () => _scanProjectsFolder(_currentFolderPath),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Rescan Projects Folder',
                color: AppTheme.emeraldGreen,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Inactive Projects Smart Recommendation Banner (If any inactive projects exist)
        if (inactiveProjectsWithCache.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.coralRose.withValues(alpha: 0.15),
                  AppTheme.amberGold.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.coralRose.withValues(alpha: 0.4), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.coralRose.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.coralRose, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '💡 Smart Inactive Project Cleanup Suggestion',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.coralRose,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.coralRose.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${inactiveProjectsWithCache.length} Inactive Projects',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.coralRose),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Found ${inactiveProjectsWithCache.length} projects not modified in >30 days. Deleting their node_modules, build outputs & caches will safely free ${ProjectAnalyzerService.formatSizeMB(inactiveTotalReclaimableMB)} (Can re-install anytime via npm/yarn/flutter)!',
                        style: TextStyle(fontSize: 12, color: textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _projectTechFilter = 'inactive';
                      _applyProjectFiltersAndSort();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('View List', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),

                ElevatedButton.icon(
                  onPressed: () => _handleCleanAllInactiveProjects(inactiveProjectsWithCache),
                  icon: const Icon(Icons.cleaning_services_rounded, size: 15),
                  label: Text('Clean Inactive (${ProjectAnalyzerService.formatSizeMB(inactiveTotalReclaimableMB)})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.coralRose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Hero Stats Cards Row
        Row(
          children: [
            _buildHeroStatCard(
              title: 'Projects Found',
              value: '$totalProjectsCount',
              subtitle: 'Active & Sub-projects',
              icon: Icons.code_rounded,
              color: AppTheme.emeraldGreen,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(width: 12),
            _buildHeroStatCard(
              title: 'Total Projects Size',
              value: ProjectAnalyzerService.formatSizeMB(totalFolderSizeMB),
              subtitle: 'Source Code + Caches',
              icon: Icons.storage_rounded,
              color: AppTheme.primaryBlue,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(width: 12),
            _buildHeroStatCard(
              title: 'node_modules Total',
              value: ProjectAnalyzerService.formatSizeMB(totalNodeModulesMB),
              subtitle: 'NPM & Yarn Dependencies',
              icon: Icons.hexagon_outlined,
              color: const Color(0xFF10B981),
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(width: 12),
            _buildHeroStatCard(
              title: 'Reclaimable Space',
              value: ProjectAnalyzerService.formatSizeMB(totalReclaimableMB),
              subtitle: 'node_modules, builds & cache',
              icon: Icons.cleaning_services_rounded,
              color: AppTheme.coralRose,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(width: 12),
            _buildHeroStatCard(
              title: 'Inactive Projects',
              value: '$inactiveCount',
              subtitle: 'Not modified in 30+ days',
              icon: Icons.history_toggle_off_rounded,
              color: AppTheme.amberGold,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Search, Filter Pills & Sort Row
        Row(
          children: [
            // Search Input
            Expanded(
              flex: 3,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 16, color: AppTheme.emeraldGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _projectSearchController,
                        onChanged: (val) {
                          setState(() {
                            _projectSearchQuery = val;
                            _applyProjectFiltersAndSort();
                          });
                        },
                        style: TextStyle(fontSize: 13, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search projects by name, tech stack, or path...',
                          hintStyle: TextStyle(fontSize: 12.5, color: textSecondary),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_projectSearchQuery.isNotEmpty)
                      InkWell(
                        onTap: () {
                          _projectSearchController.clear();
                          setState(() {
                            _projectSearchQuery = '';
                            _applyProjectFiltersAndSort();
                          });
                        },
                        child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textSubtle),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Filter Pills Track
            Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: innerCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildProjectFilterPill('all', 'All Projects', Icons.apps_rounded, isDark),
                    _buildProjectFilterPill('node_react', 'Node / React', Icons.javascript_rounded, isDark),
                    _buildProjectFilterPill('flutter', 'Flutter', Icons.flutter_dash_rounded, isDark),
                    _buildProjectFilterPill('python_rust', 'Py & Rust', Icons.terminal_rounded, isDark),
                    _buildProjectFilterPill('reclaimable', 'Has Cleanable Cache', Icons.cleaning_services_rounded, isDark),
                    _buildProjectFilterPill('inactive', 'Inactive (>30d)', Icons.history_rounded, isDark),
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
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _projectSortOption,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppTheme.emeraldGreen),
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _projectSortOption = val;
                        _applyProjectFiltersAndSort();
                      });
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: 'reclaimable_desc',
                      child: Row(
                        children: const [
                          Icon(Icons.cleaning_services_rounded, size: 14, color: AppTheme.coralRose),
                          SizedBox(width: 8),
                          Text('Reclaimable Space'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'size_desc',
                      child: Row(
                        children: const [
                          Icon(Icons.storage_rounded, size: 14, color: AppTheme.amberGold),
                          SizedBox(width: 8),
                          Text('Largest Total Size'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'updated_desc',
                      child: Row(
                        children: const [
                          Icon(Icons.history_rounded, size: 14, color: AppTheme.cyanGlow),
                          SizedBox(width: 8),
                          Text('Last Updated'),
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
        const SizedBox(height: 12),

        // Multi-Select Action Bar (if items selected)
        if (_selectedProjects.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.emeraldGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _selectedProjects.length == _filteredProjects.length,
                  tristate: _selectedProjects.length < _filteredProjects.length,
                  activeColor: AppTheme.emeraldGreen,
                  onChanged: (v) {
                    setState(() {
                      if (_selectedProjects.length == _filteredProjects.length) {
                        _selectedProjects.clear();
                      } else {
                        _selectedProjects.clear();
                        _selectedProjects.addAll(_filteredProjects);
                      }
                    });
                  },
                ),
                Text(
                  '${_selectedProjects.length} Projects Selected (${ProjectAnalyzerService.formatSizeMB(selectedReclaimableMB)} reclaimable)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _handleCleanSelectedProjectsCache,
                  icon: const Icon(Icons.delete_forever_rounded, size: 15),
                  label: Text('Clean Cache for ${_selectedProjects.length} Projects'),
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
          const SizedBox(height: 12),
        ],

        // Main Projects ListView / Grid
        Expanded(
          child: _filteredProjects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_off_rounded, size: 48, color: textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No projects found in "${_currentFolderPath.split('/').last}"',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Click "Select Projects Folder" above to choose another folder with code projects.',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredProjects.length,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemBuilder: (context, index) {
                    final p = _filteredProjects[index];
                    final isSelected = _selectedProjects.contains(p);
                    final isInactiveSuggest = p.isInactive && p.reclaimableSizeMB > 5.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? p.techColor.withValues(alpha: 0.1)
                            : (isInactiveSuggest ? AppTheme.coralRose.withValues(alpha: 0.04) : cardBgColor),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? p.techColor
                              : (isInactiveSuggest ? AppTheme.coralRose.withValues(alpha: 0.4) : borderColor),
                          width: isSelected || isInactiveSuggest ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Select Checkbox
                              Checkbox(
                                value: isSelected,
                                activeColor: p.techColor,
                                onChanged: (val) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedProjects.remove(p);
                                    } else {
                                      _selectedProjects.add(p);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 6),

                              // Tech Icon Badge
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: p.techColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: p.techColor.withValues(alpha: 0.3)),
                                ),
                                child: Icon(p.techIcon, color: p.techColor, size: 24),
                              ),
                              const SizedBox(width: 14),

                              // Project Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          p.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: p.techColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: p.techColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            p.techStackName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: p.techColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: p.healthColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: p.healthColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            p.healthStatus,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: p.healthColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      p.fullPath,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: textSecondary,
                                        fontFamily: 'monospace',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.history_rounded, size: 13, color: isInactiveSuggest ? AppTheme.coralRose : textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Last Updated: ${p.relativeLastUpdated}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: isInactiveSuggest ? FontWeight.bold : FontWeight.w600,
                                            color: isInactiveSuggest ? AppTheme.coralRose : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Icon(Icons.insert_drive_file_outlined, size: 13, color: textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${p.totalFiles} files',
                                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                                        ),
                                        if (p.nodeModulesSizeMB > 0) ...[
                                          const SizedBox(width: 14),
                                          Icon(Icons.hexagon_outlined, size: 13, color: AppTheme.emeraldGreen),
                                          const SizedBox(width: 4),
                                          Text(
                                            'node_modules: ${p.nodeModulesPackageCount} pkgs (${ProjectAnalyzerService.formatSizeMB(p.nodeModulesSizeMB)})',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.emeraldGreen,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Size Badge & Inspection Buttons
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      if (p.reclaimableSizeMB > 0.5) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.coralRose.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.cleaning_services_rounded, size: 12, color: AppTheme.coralRose),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Cleanable: ${p.formattedReclaimableSize}',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.coralRose,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: p.techColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          p.formattedTotalSize,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w900,
                                            color: p.techColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (isInactiveSuggest) ...[
                                        ElevatedButton.icon(
                                          onPressed: () => _handleCleanSingleProjectCache(p),
                                          icon: const Icon(Icons.delete_sweep_rounded, size: 14),
                                          label: Text('Clean ${p.formattedReclaimableSize}'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.coralRose,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      IconButton(
                                        icon: const Icon(Icons.folder_open_rounded, size: 18),
                                        tooltip: 'Open in Finder',
                                        color: AppTheme.amberGold,
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(6),
                                        onPressed: () => SystemStorageService.revealInFinder(p.fullPath),
                                      ),
                                      const SizedBox(width: 4),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          ProjectInspectorModal.show(
                                            context: context,
                                            project: p,
                                            onProjectUpdated: () => _scanProjectsFolder(_currentFolderPath),
                                          );
                                        },
                                        icon: const Icon(Icons.analytics_rounded, size: 14),
                                        label: const Text('Inspect Details'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.emeraldGreen,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Deletable Files Recommendation Note if inactive
                          if (isInactiveSuggest) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.coralRose.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.coralRose.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.coralRose),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Suggested for Cleanup: Inactive for 30+ days. Recommended to delete node_modules, build outputs & caches (${p.formattedReclaimableSize}). Safe to delete & re-install anytime!',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProjectFilterPill(String key, String label, IconData icon, bool isDark) {
    final isSelected = _projectTechFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _projectTechFilter = key;
            _applyProjectFiltersAndSort();
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppTheme.emeraldGreen, Color(0xFF059669)],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
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

  // ==========================================
  // TAB 1 BUILDER: SYSTEM DEV JUNK SCANNER
  // ==========================================
  Widget _buildSystemDevJunkTab(
    Color cardBgColor,
    Color innerCardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    if (_junkLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CuteAppLoader(
              message: _junkScanStatus,
              subMessage: 'Scanning node_modules, Xcode DerivedData, Flutter builds & dev caches...',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 320,
              child: LinearProgressIndicator(
                value: _junkScanProgress > 0 ? _junkScanProgress : null,
                backgroundColor: borderColor,
                color: AppTheme.cyanGlow,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      );
    }

    final totalMBSelected = _selectedJunkItems.fold<double>(0, (sum, i) => sum + i.sizeMB);
    final formattedSelectedSize = DeveloperSpaceService.formatSizeMB(totalMBSelected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls & Refresh Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'System-Wide Developer Caches & Derived Data',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _isJunkMultiSelect = !_isJunkMultiSelect;
                      if (!_isJunkMultiSelect) _selectedJunkItems.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: _isJunkMultiSelect || _selectedJunkItems.isNotEmpty
                          ? AppTheme.emeraldGreen.withValues(alpha: 0.2)
                          : cardBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isJunkMultiSelect || _selectedJunkItems.isNotEmpty
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
                          color: _isJunkMultiSelect || _selectedJunkItems.isNotEmpty
                              ? AppTheme.emeraldGreen
                              : textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Multi-Select',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isJunkMultiSelect || _selectedJunkItems.isNotEmpty
                                ? AppTheme.emeraldGreen
                                : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _scanSystemDevJunk,
                  icon: const Icon(Icons.sync_rounded, size: 17),
                  label: const Text('Rescan System Caches'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Hero Stats
        Row(
          children: [
            _buildHeroStatCard(
              title: 'Total Dev Junk',
              value: '${_junkSummary?.totalSizeGB ?? 0.0} GB',
              subtitle: '${_junkSummary?.totalItemCount ?? 0} Dev Items Found',
              icon: Icons.storage_rounded,
              color: AppTheme.emeraldGreen,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(width: 12),
            _buildHeroStatCard(
              title: 'node_modules',
              value: '${_junkSummary?.nodeModulesSizeGB ?? 0.0} GB',
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
              value: '${_junkSummary?.xcodeSizeGB ?? 0.0} GB',
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
              title: 'Flutter Builds',
              value: '${_junkSummary?.flutterBuildSizeGB ?? 0.0} GB',
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
              title: 'Package Caches',
              value: '${_junkSummary?.packageCachesGB ?? 0.0} GB',
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
        const SizedBox(height: 14),

        // Search & Filter Row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 16, color: AppTheme.emeraldGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _junkSearchController,
                        onChanged: (val) {
                          setState(() {
                            _junkSearchQuery = val;
                            _applyJunkFiltersAndSort();
                          });
                        },
                        style: TextStyle(fontSize: 13, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search dev items by name or path...',
                          hintStyle: TextStyle(fontSize: 12.5, color: textSecondary),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_junkSearchQuery.isNotEmpty)
                      InkWell(
                        onTap: () {
                          _junkSearchController.clear();
                          setState(() {
                            _junkSearchQuery = '';
                            _applyJunkFiltersAndSort();
                          });
                        },
                        child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textSubtle),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: innerCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildJunkFilterPill('all', 'All Items', Icons.apps_rounded, isDark),
                    _buildJunkFilterPill('node_modules', 'node_modules', Icons.hexagon_outlined, isDark),
                    _buildJunkFilterPill('xcode', 'Xcode Caches', Icons.developer_mode_rounded, isDark),
                    _buildJunkFilterPill('flutter', 'Flutter Build', Icons.flutter_dash_rounded, isDark),
                    _buildJunkFilterPill('caches', 'Pkg Caches', Icons.widgets_rounded, isDark),
                    _buildJunkFilterPill('python_rust', 'Py & Rust', Icons.terminal_rounded, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Multi-Select Action Bar
        if (_selectedJunkItems.isNotEmpty || _isJunkMultiSelect) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.emeraldGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _selectedJunkItems.isNotEmpty && _selectedJunkItems.length == _filteredJunkItems.length,
                  tristate: _selectedJunkItems.isNotEmpty && _selectedJunkItems.length < _filteredJunkItems.length,
                  activeColor: AppTheme.emeraldGreen,
                  onChanged: (v) {
                    setState(() {
                      if (_selectedJunkItems.length == _filteredJunkItems.length) {
                        _selectedJunkItems.clear();
                      } else {
                        _selectedJunkItems.clear();
                        _selectedJunkItems.addAll(_filteredJunkItems);
                      }
                    });
                  },
                ),
                Text(
                  _selectedJunkItems.isEmpty
                      ? 'Select All (${_filteredJunkItems.length})'
                      : '${_selectedJunkItems.length} Selected ($formattedSelectedSize)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const Spacer(),
                if (_selectedJunkItems.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _handleCleanSelectedJunkItems,
                    icon: const Icon(Icons.delete_forever_rounded, size: 15),
                    label: Text('Clean ${_selectedJunkItems.length} Items ($formattedSelectedSize)'),
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
          const SizedBox(height: 12),
        ],

        // Main ListView
        Expanded(
          child: _filteredJunkItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 48, color: AppTheme.emeraldGreen.withValues(alpha: 0.7)),
                      const SizedBox(height: 12),
                      Text(
                        'No developer junk found matching query!',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredJunkItems.length,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemBuilder: (context, index) {
                    final item = _filteredJunkItems[index];
                    final isSelected = _selectedJunkItems.contains(item);

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
                      ),
                      child: Row(
                        children: [
                          if (_isJunkMultiSelect || _selectedJunkItems.isNotEmpty) ...[
                            Checkbox(
                              value: isSelected,
                              activeColor: item.themeColor,
                              onChanged: (_) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedJunkItems.remove(item);
                                  } else {
                                    _selectedJunkItems.add(item);
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                          ],

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

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.projectName,
                                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textPrimary),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: item.themeColor.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.typeName,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.themeColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.fullPath,
                                  style: TextStyle(fontSize: 11.5, color: textSecondary, fontFamily: 'monospace'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '💡 ${item.safeToCleanNote}',
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

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
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: item.themeColor),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                                    tooltip: 'Show in Finder',
                                    color: AppTheme.amberGold,
                                    onPressed: () => SystemStorageService.revealInFinder(item.fullPath),
                                  ),
                                  const SizedBox(width: 4),
                                  ElevatedButton.icon(
                                    onPressed: () => _handleCleanSingleJunkItem(item),
                                    icon: const Icon(Icons.delete_outline_rounded, size: 14),
                                    label: const Text('Clean Junk'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: item.themeColor.withValues(alpha: 0.15),
                                      foregroundColor: item.themeColor,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    );
  }

  Widget _buildJunkFilterPill(String key, String label, IconData icon, bool isDark) {
    final isSelected = _junkTypeFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _junkTypeFilter = key;
            _applyJunkFiltersAndSort();
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppTheme.emeraldGreen, Color(0xFF059669)],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
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
              overflow: TextOverflow.ellipsis,
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
}
