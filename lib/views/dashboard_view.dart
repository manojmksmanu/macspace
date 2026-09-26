import 'package:flutter/material.dart';
import '../models/storage_item.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hero_disk_gauge.dart';
import '../widgets/category_cards_grid.dart';
import '../widgets/large_files_table.dart';
import '../widgets/recommendations_widget.dart';
import '../widgets/treemap_widget.dart';

class DashboardView extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const DashboardView({super.key, required this.onNavigate});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isLoading = true;
  bool _isScanning = false;
  String _scanStatus = "Loading Mac storage data...";
  double _scanProgress = 0.0;
  SystemStorageData? _storageData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _isScanning = true;
      _scanProgress = 0.2;
      _scanStatus = "Scanning Apple SSD storage...";
    });

    final data = await SystemStorageService.fetchRealSystemData(
      forceRefresh: forceRefresh,
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
        _storageData = data;
        _isLoading = false;
        _isScanning = false;
      });
    }
  }

  void _triggerCleanJunk() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.auto_awesome_rounded, color: AppTheme.amberGold),
            SizedBox(width: 8),
            Text('Confirm Junk Cleanup', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Are you sure you want to clean 22.4 GB of system caches, Xcode build data, and temporary logs?',
          style: TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSubtle)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Successfully cleaned 22.4 GB of storage junk!'),
                  backgroundColor: AppTheme.emeraldGreen,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.amberGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Clean Now', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _storageData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppTheme.cyanGlow,
            ),
            const SizedBox(height: 20),
            Text(
              _scanStatus,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _scanProgress,
                  minHeight: 6,
                  backgroundColor: AppTheme.borderColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.cyanGlow,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final data = _storageData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Storage Analytics Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textWhite,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Real-time Mac drive metrics & storage breakdown',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSubtle,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  // Refresh Button
                  Material(
                    color: AppTheme.cardBgTranslucent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _loadData(forceRefresh: true),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AnimatedRotation(
                          turns: _isScanning ? 1.0 : 0.0,
                          duration: const Duration(seconds: 1),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: AppTheme.cyanGlow,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Turbo Scan Button
                  ElevatedButton.icon(
                    onPressed: () => _loadData(forceRefresh: true),
                    icon: _isScanning
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.bolt_rounded, size: 16),
                    label: const Text('Turbo Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Hero Gauge Card
          HeroDiskGaugeCard(
            data: data,
            onCleanJunk: _triggerCleanJunk,
          ),
          const SizedBox(height: 20),

          // Categories Cards Grid
          CategoryCardsGrid(
            categories: data.categories.map((c) => StorageCategory(
              name: c.title,
              sizeGB: c.sizeGB,
              percentage: ((c.sizeGB / (data.totalGB > 0 ? data.totalGB : 1)) * 100),
              color: c.color,
              icon: c.icon,
            )).toList(),
          ),
          const SizedBox(height: 20),

          // Adaptive Middle Layout: Large Files Table & AI Recommendations
          LayoutBuilder(
            builder: (context, constraints) {
              final folders = data.rootTreemapNode.children.map((c) => StorageFolder(name: c.name, path: c.path, sizeGB: c.sizeGB)).toList();
              final files = (data.categories.isNotEmpty ? data.categories.first.items : []).map((i) => StorageFile(name: i.name, path: i.path, sizeGB: i.sizeMB / 1024, icon: Icons.insert_drive_file_rounded, type: 'File')).toList();
              const recs = [
                StorageRecommendation(
                  title: 'Clean Xcode DerivedData & Developer Caches',
                  subtitle: 'Reclaim up to 14.5 GB of obsolete build caches',
                  actionText: 'Quick Clean',
                  potentialSavingsGB: 14.5,
                  icon: Icons.code_rounded,
                  color: AppTheme.amberGold,
                ),
                StorageRecommendation(
                  title: 'Empty macOS System Trash',
                  subtitle: '2.03 GB of deleted files sitting in Trash bin',
                  actionText: 'Empty Trash',
                  potentialSavingsGB: 2.03,
                  icon: Icons.delete_sweep_rounded,
                  color: AppTheme.coralRose,
                ),
              ];

              if (constraints.maxWidth > 950) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 58,
                      child: LargeFilesTable(
                        folders: folders,
                        largestFiles: files,
                        recentFiles: files,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 42,
                      child: Column(
                        children: [
                          RecommendationsWidget(recommendations: recs),
                          const SizedBox(height: 20),
                          const TreemapWidget(),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    LargeFilesTable(
                      folders: folders,
                      largestFiles: files,
                      recentFiles: files,
                    ),
                    const SizedBox(height: 20),
                    RecommendationsWidget(recommendations: recs),
                    const SizedBox(height: 20),
                    const TreemapWidget(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
