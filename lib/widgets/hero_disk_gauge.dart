import 'dart:math';
import 'package:flutter/material.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';

class HeroDiskGaugeCard extends StatelessWidget {
  final SystemStorageData data;
  final VoidCallback onCleanJunk;

  const HeroDiskGaugeCard({
    super.key,
    required this.data,
    required this.onCleanJunk,
  });

  @override
  Widget build(BuildContext context) {
    final usedPct = (data.usedGB / data.totalGB);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBgTranslucent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: isWide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              // Radial Arc Gauge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(130, 130),
                          painter: _GaugePainter(percentage: usedPct),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(usedPct * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textWhite,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'USED SPACE',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.cyanGlow,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isWide) const SizedBox(width: 20),
                ],
              ),
              const SizedBox(width: 20, height: 16),

              // Drive Meta Stats
              Expanded(
                flex: isWide ? 1 : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'SSD Healthy 98%',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.emeraldGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            data.fileSystem,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.driveName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'APFS SSD • Total: ${data.totalGB} GB',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Capacity Stats Row
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        _buildStatPill('Used Storage', '${data.usedGB} GB', AppTheme.primaryBlue),
                        _buildStatPill('Free Available', '${data.freeGB} GB', AppTheme.cyanGlow),
                        _buildStatPill('Cleanable Junk', '${data.reclaimableGB} GB', AppTheme.amberGold),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16, height: 16),

              // Action Clean Button
              ElevatedButton.icon(
                onPressed: onCleanJunk,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text('Clean ${data.reclaimableGB} GB'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.amberGold,
                  foregroundColor: Colors.black,
                  elevation: 4,
                  shadowColor: AppTheme.amberGold.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatPill(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textSubtle),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          val,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.textWhite),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;

  _GaugePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 12.0;

    // Track Paint
    final trackPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3 * pi / 4,
      3 * pi / 2,
      false,
      trackPaint,
    );

    // Active Radial Gradient Paint
    final activePaint = Paint()
      ..shader = const SweepGradient(
        colors: [AppTheme.primaryBlue, AppTheme.cyanGlow, AppTheme.purpleGlow],
        startAngle: 3 * pi / 4,
        endAngle: 9 * pi / 4,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (3 * pi / 2) * percentage.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3 * pi / 4,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
