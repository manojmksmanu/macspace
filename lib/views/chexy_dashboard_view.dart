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
  String _scanStatus = "Analyzing Mac storage categories...";
  double _scanProgress = 0.0;
  ChexyStorageData? _data;
  List<MacVolumeInfo> _volumes = [];
  int _modeIndex = 0; // 0: My Mac, 1: Volumes

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
      _scanStatus = "Scanning storage categories on Macintosh HD...";
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

    final vols = await SystemStorageService.fetchRealVolumes();

    if (mounted) {
      setState(() {
        _data = data;
        _volumes = vols;
        _isLoading = false;
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppTheme.cardBgTranslucent : AppTheme.cardBgLight;
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final textPrimary = isDark ? AppTheme.textWhite : AppTheme.textDark;
    final textSecondary = isDark ? AppTheme.textSubtle : AppTheme.textMutedLight;
    final pillBg = isDark ? AppTheme.bgDark : AppTheme.bgLight;

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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Control Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.cyanGlow]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.storage_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mac Storage Dashboard',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Analyze & clean your Mac storage space',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Mode Switcher [ My Mac | Volumes ]
              Container(
                height: 38,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _modeIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: _modeIndex == 0 ? AppTheme.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'My Mac',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _modeIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                            color: _modeIndex == 0 ? Colors.white : textSecondary,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _modeIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: _modeIndex == 1 ? AppTheme.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Volumes',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _modeIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                            color: _modeIndex == 1 ? Colors.white : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Scan Button
              ElevatedButton.icon(
                onPressed: () => _loadData(forceRefresh: true),
                icon: _isScanning
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.bolt_rounded, size: 16),
                label: const Text('Scan Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  elevation: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Content View Switcher: My Mac vs Volumes
          if (_modeIndex == 0) ...[
            // Hero Macintosh HD Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Donut Chart Gauge
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(130, 130),
                          painter: _ChexyGaugePainter(pct: d.usedPercentage / 100, isDark: isDark),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${d.usedPercentage.toInt()}%',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary),
                            ),
                            Text(
                              'USED',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: textSecondary, letterSpacing: 1.1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 28),

                  // Disk Info Specs
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.driveName,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 16,
                          runSpacing: 6,
                          children: [
                            _buildDotIndicator('Used: ${d.usedGB} GB', AppTheme.primaryBlue, textPrimary),
                            _buildDotIndicator('Free: ${d.freeGB} GB', AppTheme.emeraldGreen, textPrimary),
                            _buildDotIndicator('Reclaimable: ${d.reclaimableGB} GB', AppTheme.amberGold, textPrimary),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Multi-colored proportion bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            height: 6,
                            color: borderColor,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: (d.usedGB * 10).toInt(),
                                  child: Container(color: AppTheme.primaryBlue),
                                ),
                                Expanded(
                                  flex: (d.reclaimableGB * 10).toInt().clamp(1, 100),
                                  child: Container(color: AppTheme.amberGold),
                                ),
                                Expanded(
                                  flex: (d.freeGB * 10).toInt(),
                                  child: Container(color: AppTheme.emeraldGreen),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Capacity: ${d.totalGB} GB',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                            ),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 13, color: textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Last scanned: ${d.scanDurationSec}s ago',
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.grid_view_rounded, size: 13, color: textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  '${d.categories.length} Storage Categories',
                                  style: TextStyle(fontSize: 11, color: textSecondary),
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
            ),
            const SizedBox(height: 20),

            // 12 Symmetrical Category Cards Grid (4 columns x 3 rows)
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 650 ? 3 : 2);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: 1.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: d.categories.length,
                  itemBuilder: (context, index) {
                    final cat = d.categories[index];
                    final pct = (cat.sizeGB / d.totalGB * 100).clamp(0.5, 100.0);

                    return Material(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          CategoryInspectorModal.show(context: context, categoryInfo: cat);
                        },
                        hoverColor: cat.color.withValues(alpha: 0.08),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          cat.color.withValues(alpha: 0.25),
                                          cat.color.withValues(alpha: 0.12),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: cat.color.withValues(alpha: 0.3)),
                                    ),
                                    child: Icon(cat.icon, color: cat.color, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat.title,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.2),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          cat.subtitle,
                                          style: TextStyle(fontSize: 9.5, color: textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: cat.color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${pct.toStringAsFixed(1)}%',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: cat.color),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '${cat.sizeGB}',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cat.color),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'GB',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cat.color.withValues(alpha: 0.8)),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${cat.itemCount} items',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textSecondary),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.chevron_right_rounded, size: 14, color: cat.color),
                                    ],
                                  ),
                                ],
                              ),
                              // Mini progress bar for category proportion
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  height: 4,
                                  color: borderColor,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: (pct / 100).clamp(0.01, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: cat.color,
                                          borderRadius: BorderRadius.circular(4),
                                          boxShadow: [
                                            BoxShadow(
                                              color: cat.color.withValues(alpha: 0.5),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ] else ...[
            // VOLUMES BREAKDOWN VIEW
            Text(
              'Mounted APFS & Storage Volumes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _volumes.length,
              itemBuilder: (context, index) {
                final vol = _volumes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(vol.icon, color: AppTheme.cyanGlow, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  vol.name,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cyanGlow.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    vol.fileSystem,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.cyanGlow),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mount Point: ${vol.mountPoint}',
                              style: TextStyle(fontSize: 11.5, color: textSecondary),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: vol.usedPercentage / 100,
                                minHeight: 6,
                                backgroundColor: borderColor,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Used: ${vol.usedGB} GB (${vol.usedPercentage}%)', style: TextStyle(fontSize: 11, color: textSecondary)),
                                Text('Free: ${vol.freeGB} GB of ${vol.totalGB} GB', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDotIndicator(String label, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textColor),
        ),
      ],
    );
  }
}

class _ChexyGaugePainter extends CustomPainter {
  final double pct;
  final bool isDark;

  _ChexyGaugePainter({required this.pct, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 12.0;

    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final activePaint = Paint()
      ..color = AppTheme.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * pct.clamp(0.0, 1.0),
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
