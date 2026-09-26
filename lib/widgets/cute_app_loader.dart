import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CuteAppLoader extends StatefulWidget {
  final String? message;
  final String? subMessage;
  final String? submessage;
  final double? progress;
  final double size;
  final bool showText;

  const CuteAppLoader({
    super.key,
    this.message,
    this.subMessage,
    this.submessage,
    this.progress,
    this.size = 64.0,
    this.showText = true,
  });

  @override
  State<CuteAppLoader> createState() => _CuteAppLoaderState();
}

class _CuteAppLoaderState extends State<CuteAppLoader> with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.textWhite : AppTheme.textDark;
    final textSecondary = isDark ? AppTheme.textSubtle : AppTheme.textMutedLight;
    final cardBg = isDark ? AppTheme.cardBgTranslucent : Colors.white.withValues(alpha: 0.95);
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;

    final effectiveMessage = widget.message ?? 'Scanning Macintosh HD...';
    final effectiveSubMessage = widget.subMessage ?? widget.submessage;

    // Compact mode for inline button icons / refresh controls
    if (!widget.showText || widget.size < 32) {
      return RotationTransition(
        turns: _spinController,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            value: widget.progress,
            strokeWidth: (widget.size * 0.12).clamp(1.5, 3.0),
            backgroundColor: isDark ? AppTheme.borderColor : AppTheme.borderColorLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cyanGlow),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: 340,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.35) : AppTheme.primaryBlue.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Professional Dual-Ring Spinner with Mac Storage Icon
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow Halo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.cyanGlow.withValues(alpha: 0.22),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  // Continuous Spinning Gradient Ring
                  RotationTransition(
                    turns: _spinController,
                    child: SizedBox(
                      width: 68,
                      height: 68,
                      child: CircularProgressIndicator(
                        value: widget.progress,
                        strokeWidth: 3.5,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cyanGlow),
                      ),
                    ),
                  ),
                  // Center Apple Mac Hardware Badge
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.laptop_mac_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Main Title
            Text(
              effectiveMessage,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),

            if (effectiveSubMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Text(
                  effectiveSubMessage,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            if (widget.progress != null) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: widget.progress,
                      minHeight: 5,
                      backgroundColor: isDark ? AppTheme.borderColor : AppTheme.borderColorLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${((widget.progress ?? 0) * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.cyanGlow,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
