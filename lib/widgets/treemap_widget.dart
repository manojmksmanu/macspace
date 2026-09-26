import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TreemapWidget extends StatelessWidget {
  const TreemapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppTheme.cardBgTranslucent : AppTheme.cardBgLight;
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final textPrimary = isDark ? AppTheme.textWhite : AppTheme.textDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visual Space Allocation Treemap',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                // Applications (Flex 26)
                Expanded(
                  flex: 26,
                  child: _buildBlock(
                    name: 'Applications',
                    size: '86.4 GB',
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 6),

                // System & Cache (Flex 22)
                Expanded(
                  flex: 22,
                  child: _buildBlock(
                    name: 'System',
                    size: '41.3 GB',
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 6),

                // Center Column (Flex 30)
                Expanded(
                  flex: 30,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 12,
                        child: _buildBlock(
                          name: 'Videos',
                          size: '18.7 GB',
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        flex: 10,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 14,
                              child: _buildBlock(
                                name: 'Photos',
                                size: '14.2 GB',
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 9,
                              child: _buildBlock(
                                name: 'Audio',
                                size: '4.8 GB',
                                color: const Color(0xFFEC4899),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Right Column (Flex 20)
                Expanded(
                  flex: 20,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 10,
                        child: _buildBlock(
                          name: 'Downloads',
                          size: '12.6 GB',
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        flex: 8,
                        child: _buildBlock(
                          name: 'Docs',
                          size: '8.4 GB',
                          color: const Color(0xFF06B6D4),
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
    );
  }

  Widget _buildBlock({
    required String name,
    required String size,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                size,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
