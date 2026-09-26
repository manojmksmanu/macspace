import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/category_inspector_modal.dart';

class ChexyDashboardView extends StatefulWidget {
  const ChexyDashboardView({super.key});

  @override
  State<ChexyDashboardView> createState() => _ChexyDashboardViewState();
}

class _ChexyDashboardViewState extends State<ChexyDashboardView> {
  bool _isLoading = true;
  bool _isScanning = false;
  String _scanStatus = "Scanning real Macintosh HD storage...";
  double _scanProgress = 0.0;
  ChexyStorageData? _data;
  int _activeCategoryFilter = 0; // 0: All, 1: Dev & Code, 2: Caches & Logs, 3: Trash & Temp
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  late String _currentUsername;

  @override
  void initState() {
    super.initState();
    _currentUsername = Platform.environment['USER'] ?? 'Mac User';
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _isScanning = true;
      _scanProgress = 0.2;
      _scanStatus = "Analyzing real disk usage & categories...";
    });

    final data = await SystemStorageService.fetchChexyData(
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
        _data = data;
        _isLoading = false;
        _isScanning = false;
      });
    }
  }

  List<CategoryDetailItem> _getFilteredItems(ChexyStorageData d) {
    List<CategoryDetailItem> allItems = [];
    for (var cat in d.categories) {
      if (_activeCategoryFilter == 1 && cat.key != 'dev' && cat.key != 'xcode') continue;
      if (_activeCategoryFilter == 2 && cat.key != 'caches' && cat.key != 'containers') continue;
      if (_activeCategoryFilter == 3 && cat.key != 'trash') continue;
      allItems.addAll(cat.items);
    }

    allItems.sort((a, b) => b.sizeMB.compareTo(a.sizeMB));

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      allItems = allItems.where((i) => i.name.toLowerCase().contains(q) || i.path.toLowerCase().contains(q)).toList();
    }

    return allItems;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppTheme.cardBgTranslucent : AppTheme.cardBgLight;
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final textPrimary = isDark ? AppTheme.textWhite : AppTheme.textDark;
    final textSecondary = isDark ? AppTheme.textSubtle : AppTheme.textMutedLight;

    if (_isLoading || _data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.cyanGlow),
            const SizedBox(height: 20),
            Text(
              _scanStatus,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _scanProgress,
                  minHeight: 6,
                  backgroundColor: borderColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final d = _data!;
    final filteredItems = _getFilteredItems(d);

    // Calculate real metrics
    final devSizeGB = d.categories.firstWhere((c) => c.key == 'dev', orElse: () => d.categories.first).sizeGB;
    final appSizeGB = d.categories.firstWhere((c) => c.key == 'apps', orElse: () => d.categories.first).sizeGB;
    final totalDevAppGB = (devSizeGB + appSizeGB).toStringAsFixed(1);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP HEADER BAR WITH REAL SEARCH & SYSTEM METRICS
          Row(
            children: [
              // Logo & Real App Name
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.cyanGlow, AppTheme.primaryBlue]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.cyanGlow.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.storage_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Mac Storage Pro',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // Instant Real Search Bar
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardBg : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                    boxShadow: AppTheme.softShadow(isDark),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 18, color: textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: TextStyle(fontSize: 13, color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search real files (e.g. DerivedData, Trash, Caches)...',
                            hintStyle: TextStyle(fontSize: 13, color: textSecondary.withValues(alpha: 0.7)),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = "");
                          },
                          color: textSecondary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // System Status & Real User Profile Chip
              Row(
                children: [
                  IconButton(
                    onPressed: () => _loadData(forceRefresh: true),
                    icon: _isScanning
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue))
                        : const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Rescan Macintosh HD',
                    color: textSecondary,
                  ),
                  const SizedBox(width: 8),

                  // Real Storage Alert Bell
                  Stack(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardBg : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                        ),
                        child: Icon(Icons.notifications_none_rounded, size: 20, color: textSecondary),
                      ),
                      if (d.reclaimableGB > 5.0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppTheme.amberGold,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardBgColor, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Real macOS User Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardBg : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                      boxShadow: AppTheme.softShadow(isDark),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                          child: Text(
                            _currentUsername[0].toUpperCase(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentUsername,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                            ),
                            Text(
                              d.driveName,
                              style: TextStyle(fontSize: 9, color: textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. MAIN REAL DATA GRID
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT COLUMN: 4 Real Metric Gradient Cards & Storage Proportions
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real Disk Metrics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 12),

                    // 2x2 Grid of Real Gradient Cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.6,
                      children: [
                        _buildRealMetricCard(
                          title: '${d.usedGB} GB',
                          subtitle: 'Used Space (${d.usedPercentage.toInt()}%)',
                          badgeText: 'Macintosh HD',
                          gradient: AppTheme.cardGradientBlue,
                          icon: Icons.pie_chart_rounded,
                          onTap: () => _openCategory('system'),
                        ),
                        _buildRealMetricCard(
                          title: '${d.freeGB} GB',
                          subtitle: 'Free Capacity (${(100 - d.usedPercentage).toInt()}%)',
                          badgeText: 'Available',
                          gradient: AppTheme.cardGradientEmerald,
                          icon: Icons.cloud_done_rounded,
                          onTap: () => _openCategory('free'),
                        ),
                        _buildRealMetricCard(
                          title: '${d.reclaimableGB} GB',
                          subtitle: 'Reclaimable Junk & Trash',
                          badgeText: '${d.categories.firstWhere((c) => c.key == 'trash', orElse: () => d.categories.first).itemCount} items',
                          gradient: AppTheme.cardGradientPurple,
                          icon: Icons.delete_sweep_rounded,
                          onTap: () => _openCategory('trash'),
                        ),
                        _buildRealMetricCard(
                          title: '$totalDevAppGB GB',
                          subtitle: 'Developer Bloat & Apps',
                          badgeText: '${d.categories.firstWhere((c) => c.key == 'dev', orElse: () => d.categories.first).itemCount} build assets',
                          gradient: AppTheme.cardGradientRoyal,
                          icon: Icons.code_rounded,
                          onTap: () => _openCategory('dev'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Real Category Proportions Breakdown Panel
                    Text(
                      'Category Usage Breakdown',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Filters
                        Container(
                          width: 140,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                            boxShadow: AppTheme.softShadow(isDark),
                          ),
                          child: Column(
                            children: [
                              _buildCategoryFilterTab(0, 'All Categories', isDark),
                              _buildCategoryFilterTab(1, 'Dev & Code', isDark),
                              _buildCategoryFilterTab(2, 'Caches & Logs', isDark),
                              _buildCategoryFilterTab(3, 'Trash & Temp', isDark),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Real Category Progress List (Displays ALL categories)
                        Expanded(
                          child: Container(
                            height: 220,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                              boxShadow: AppTheme.softShadow(isDark),
                            ),
                            child: ListView.builder(
                              itemCount: d.categories.length,
                              itemBuilder: (context, index) {
                                final cat = d.categories[index];
                                final pct = (cat.sizeGB / d.totalGB * 100).clamp(0.1, 100.0);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildRealCategoryBar(cat.title, pct / 100, cat.sizeGB, cat.color, textPrimary, textSecondary),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Donut Chart Reclaimable Callout Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                        boxShadow: AppTheme.softShadow(isDark),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.amberGold,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reclaimable Space Summary',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                              ),
                              Text(
                                '${d.reclaimableGB} GB cleanable out of ${d.usedGB} GB used',
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: CustomPaint(
                              painter: _RealReclaimableDonutPainter(
                                reclaimableRatio: (d.reclaimableGB / d.usedGB).clamp(0.05, 1.0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // RIGHT COLUMN: Real Data Spline Chart + Scanned Items Table
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Volume Bar
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                        boxShadow: AppTheme.softShadow(isDark),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sd_storage_rounded, color: AppTheme.cyanGlow, size: 22),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Macintosh HD Mount Path',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
                              ),
                              Text(
                                'Total Capacity: ${d.totalGB} GB • Scanned in ${d.scanDurationSec}s',
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'APFS VOLUME',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.emeraldGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // REAL CATEGORY SIZES SPLINE AREA CHART
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                        boxShadow: AppTheme.softShadow(isDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Real Category Storage Sizes',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.3),
                                  ),
                                  Text(
                                    'Proportional storage allocation across Macintosh HD',
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.bgDark : AppTheme.bgLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Text(
                                  '${d.categories.length} Categories',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Real Data Spline Chart Canvas
                          SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _RealCategorySplinePainter(
                                categories: d.categories,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // REAL SCANNED FILES ACTION TABLE
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                        boxShadow: AppTheme.softShadow(isDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Scanned Storage Items (${filteredItems.length})',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                              ),
                              Text(
                                'Click item to inspect',
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          if (filteredItems.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Center(
                                child: Text('No matching items found for "$_searchQuery"', style: TextStyle(color: textSecondary)),
                              ),
                            )
                          else
                            SizedBox(
                              height: 280,
                              child: ListView.builder(
                                itemCount: filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10.0),
                                    child: _buildRealFileRow(
                                      item: item,
                                      isDark: isDark,
                                      textPrimary: textPrimary,
                                      textSecondary: textSecondary,
                                      borderColor: borderColor,
                                      onInspect: () => _openCategory(item.categoryKey),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openCategory(String key) {
    if (_data == null) return;
    final cat = _data!.categories.firstWhere((c) => c.key == key, orElse: () => _data!.categories.first);
    CategoryInspectorModal.show(context: context, categoryInfo: cat);
  }

  Widget _buildRealMetricCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required LinearGradient gradient,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.last.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background Curve Wave
              Positioned.fill(
                child: CustomPaint(
                  painter: _RealWavePainter(),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterTab(int index, String label, bool isDark) {
    final isSelected = _activeCategoryFilter == index;
    return InkWell(
      onTap: () => setState(() => _activeCategoryFilter = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 34,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? AppTheme.cardBg : AppTheme.bgLight) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AppTheme.cyanGlow.withValues(alpha: 0.5)) : null,
        ),
        child: Row(
          children: [
            if (isSelected) Container(width: 3, height: 14, color: AppTheme.cyanGlow) else const SizedBox(width: 3),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? (isDark ? AppTheme.textWhite : AppTheme.textDark) : AppTheme.textMutedLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealCategoryBar(String title, double pct, double sizeGB, Color color, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
            Text('${sizeGB.toStringAsFixed(1)} GB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildRealFileRow({
    required CategoryDetailItem item,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required VoidCallback onInspect,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgDark.withValues(alpha: 0.6) : AppTheme.bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
            child: const Icon(Icons.insert_drive_file_rounded, size: 18, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary), overflow: TextOverflow.ellipsis),
                Text(item.path, style: TextStyle(fontSize: 10, color: textSecondary), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.sizeFormatted,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
          ),
          const SizedBox(width: 14),
          ElevatedButton(
            onPressed: onInspect,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            child: const Text('Inspect'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// REAL DATA PAINTERS
// -----------------------------------------------------------------------------

class _RealWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.6,
      size.height * 0.9,
      size.width,
      size.height * 0.5,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RealCategorySplinePainter extends CustomPainter {
  final List<CategoryCardInfo> categories;
  final bool isDark;

  _RealCategorySplinePainter({required this.categories, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (categories.isEmpty) return;

    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final displayCats = categories.take(10).toList();
    final maxGB = displayCats.map((c) => c.sizeGB).fold<double>(1.0, (m, v) => v > m ? v : m);

    final points = <Offset>[];
    for (int i = 0; i < displayCats.length; i++) {
      final x = displayCats.length > 1 ? size.width * (i / (displayCats.length - 1)) : size.width / 2;
      final y = size.height - (size.height * 0.75 * (displayCats[i].sizeGB / maxGB)) - (size.height * 0.1);
      points.add(Offset(x, y));
    }

    final strokePaint = Paint()
      ..color = AppTheme.cyanGlow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlX = (p0.dx + p1.dx) / 2;
        path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppTheme.cyanGlow.withValues(alpha: 0.25), AppTheme.cyanGlow.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, strokePaint);

    // Draw real data point dots, size callout badges, and category labels
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final cat = displayCats[i];

      // Draw point dot with glowing ring
      canvas.drawCircle(pt, 7, Paint()..color = cat.color.withValues(alpha: 0.3));
      canvas.drawCircle(pt, 5, Paint()..color = Colors.white);
      canvas.drawCircle(pt, 3, Paint()..color = cat.color);

      // Draw GB size badge tag ABOVE the point
      final sizeText = '${cat.sizeGB} GB';
      TextSpan sizeSpan = TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
        text: sizeText,
      );
      TextPainter tpSize = TextPainter(text: sizeSpan, textDirection: TextDirection.ltr);
      tpSize.layout();

      final badgeWidth = tpSize.width + 10;
      final badgeHeight = tpSize.height + 4;
      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pt.dx.clamp(badgeWidth / 2, size.width - badgeWidth / 2), (pt.dy - 16).clamp(10, size.height - 25)),
          width: badgeWidth,
          height: badgeHeight,
        ),
        const Radius.circular(6),
      );

      // Badge background pill
      canvas.drawRRect(badgeRect, Paint()..color = cat.color);
      tpSize.paint(
        canvas,
        Offset(
          pt.dx.clamp(badgeWidth / 2, size.width - badgeWidth / 2) - tpSize.width / 2,
          (pt.dy - 16).clamp(10, size.height - 25) - tpSize.height / 2,
        ),
      );

      // Label at bottom
      TextSpan span = TextSpan(
        style: TextStyle(
          color: (isDark ? AppTheme.textWhite : AppTheme.textDark),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
        text: cat.title.split(' ').first,
      );
      TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(pt.dx.clamp(tp.width / 2, size.width - tp.width / 2) - tp.width / 2, size.height - 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RealReclaimableDonutPainter extends CustomPainter {
  final double reclaimableRatio;
  _RealReclaimableDonutPainter({required this.reclaimableRatio});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = AppTheme.cyanGlow.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final arcPaint = Paint()
      ..color = AppTheme.amberGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, pi * 2 * reclaimableRatio, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
