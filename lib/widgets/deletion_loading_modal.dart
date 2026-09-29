import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'cute_app_loader.dart';

class DeletionLoadingModal extends StatefulWidget {
  final String title;
  final String subTitle;
  final Future<void> Function() onDeleteTask;

  const DeletionLoadingModal({
    super.key,
    required this.title,
    required this.subTitle,
    required this.onDeleteTask,
  });

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String subTitle,
    required Future<bool> Function() onDeleteTask,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DeletionLoadingModal(
        title: title,
        subTitle: subTitle,
        onDeleteTask: onDeleteTask,
      ),
    );
    return result ?? false;
  }

  @override
  State<DeletionLoadingModal> createState() => _DeletionLoadingModalState();
}

class _DeletionLoadingModalState extends State<DeletionLoadingModal> {
  bool _isDone = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _runDeletion();
  }

  Future<void> _runDeletion() async {
    try {
      await widget.onDeleteTask();
      _success = true;
    } catch (_) {
      _success = false;
    }

    if (mounted) {
      setState(() {
        _isDone = true;
      });

      // Brief pause to show success animation
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Navigator.of(context).pop(_success);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 420,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isDone ? AppTheme.emeraldGreen : AppTheme.coralRose.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isDone) ...[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.4), width: 1.5),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppTheme.emeraldGreen,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Completed Successfully!',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Disk space reclaimed and files updated.',
                style: TextStyle(fontSize: 12.5, color: textSecondary),
              ),
            ] else ...[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.coralRose.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: AppTheme.coralRose,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                widget.subTitle,
                style: TextStyle(fontSize: 12.5, color: textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 260,
                child: LinearProgressIndicator(
                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  color: AppTheme.coralRose,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
