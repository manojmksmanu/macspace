import 'dart:io';
import 'package:flutter/material.dart';
import '../models/storage_item.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';

class AppsManagerView extends StatefulWidget {
  const AppsManagerView({super.key});

  @override
  State<AppsManagerView> createState() => _AppsManagerViewState();
}

class _AppsManagerViewState extends State<AppsManagerView> {
  List<InstalledAppItem> _apps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final list = await SystemStorageService.fetchRealInstalledApps();
    if (mounted) {
      setState(() {
        _apps = list;
        _loading = false;
      });
    }
  }

  void _openApp(String path) {
    Process.run('open', [path]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $path...'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppTheme.cardBgTranslucent : AppTheme.cardBgLight;
    final innerCardBg = isDark ? AppTheme.bgDark.withValues(alpha: 0.5) : AppTheme.bgLight;
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;
    final textPrimary = isDark ? AppTheme.textWhite : AppTheme.textDark;
    final textSecondary = isDark ? AppTheme.textSubtle : AppTheme.textMutedLight;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.cyanGlow));
    }

    final totalMB = _apps.fold<double>(0, (sum, a) => sum + a.sizeMB);
    final totalGB = (totalMB / 1024).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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
                    'Applications Manager',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real installed macOS applications in /Applications • Total: $totalGB GB',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _loadApps,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Rescan Apps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: ListView.builder(
                itemCount: _apps.length,
                itemBuilder: (context, index) {
                  final app = _apps[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: innerCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.apps_rounded, color: AppTheme.cyanGlow, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                app.path,
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          app.sizeFormatted,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        ElevatedButton(
                          onPressed: () => _openApp(app.path),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                            foregroundColor: AppTheme.primaryBlue,
                            elevation: 0,
                          ),
                          child: const Text('Open App'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
