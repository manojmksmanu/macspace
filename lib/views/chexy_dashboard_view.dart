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
      _scanStatus = "Scanning 10 Chexy categories on Macintosh HD...";
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.cyanGlow),
            const SizedBox(height: 20),
            Text(
              _scanStatus,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textWhite),
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
          // Mode Pill Bar [ My Mac | Volumes ]
          Center(
            child: Container(
              height: 34,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppTheme.cardBgTranslucent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _modeIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
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
                          color: _modeIndex == 0 ? AppTheme.textWhite : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _modeIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
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
                          color: _modeIndex == 1 ? AppTheme.textWhite : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.cyanGlow]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storage_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Chexy Storage Analyzer',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textWhite),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Analyze & clean your Mac storage space',
                            style: TextStyle(fontSize: 11.5, color: AppTheme.textSubtle),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppTheme.textMuted, size: 20),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: () => _loadData(forceRefresh: true),
                    icon: _isScanning
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.bolt_rounded, size: 16),
                    label: const Text('Scan Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Hero Macintosh HD Card (Exact Chexy Card - Screenshot 1)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBgTranslucent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                // Donut Chart
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(130, 130),
                        painter: _ChexyGaugePainter(pct: d.usedPercentage / 100),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${d.usedPercentage.toInt()}%',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textWhite),
                          ),
                          const Text(
                            'USED',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.textSubtle, letterSpacing: 1.1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Disk Info Specs
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.driveName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textWhite),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _buildDotIndicator('Used: ${d.usedGB} GB', AppTheme.primaryBlue),
                          _buildDotIndicator('Free: ${d.freeGB} GB', AppTheme.emeraldGreen),
                          _buildDotIndicator('Reclaimable: ${d.reclaimableGB} GB', AppTheme.amberGold),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: AppTheme.borderColor, height: 1),
                      const SizedBox(height: 10),
                      Text(
                        'Total: ${d.totalGB} GB',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textWhite),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 13, color: AppTheme.textSubtle),
                          const SizedBox(width: 4),
                          Text(
                            '${d.scanDurationSec}s',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSubtle),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.grid_view_rounded, size: 13, color: AppTheme.textSubtle),
                          const SizedBox(width: 4),
                          Text(
                            '${d.categories.length} categories',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSubtle),
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

          // 10 Chexy Category Cards Grid (Screenshot 1)
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 650 ? 3 : 2);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: d.categories.length,
                itemBuilder: (context, index) {
                  final cat = d.categories[index];
                  return Material(
                    color: AppTheme.cardBgTranslucent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        CategoryInspectorModal.show(context: context, categoryInfo: cat);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(cat.icon, color: cat.color, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    cat.title,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textWhite),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    cat.subtitle,
                                    style: const TextStyle(fontSize: 9.5, color: AppTheme.textSubtle),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${cat.sizeGB} GB',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cat.color),
                                  ),
                                  Text(
                                    '${cat.itemCount} item(s)',
                                    style: const TextStyle(fontSize: 9, color: AppTheme.textSubtle),
                                  ),
                                ],
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
        ],
      ),
    );
  }

  Widget _buildDotIndicator(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textWhite),
        ),
      ],
    );
  }
}

class _ChexyGaugePainter extends CustomPainter {
  final double pct;

  _ChexyGaugePainter({required this.pct});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 12.0;

    final trackPaint = Paint()
      ..color = AppTheme.amberGold
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
