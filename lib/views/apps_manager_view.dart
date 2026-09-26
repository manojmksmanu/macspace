import 'dart:io';
import 'package:flutter/material.dart';
import '../models/storage_item.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cute_app_loader.dart';

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

  IconData _getAppIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('xcode')) return Icons.code_rounded;
    if (n.contains('chrome') || n.contains('safari') || n.contains('firefox') || n.contains('browser')) return Icons.language_rounded;
    if (n.contains('code') || n.contains('studio') || n.contains('sublime') || n.contains('intellij')) return Icons.terminal_rounded;
    if (n.contains('slack') || n.contains('discord') || n.contains('telegram') || n.contains('whatsapp')) return Icons.chat_bubble_rounded;
    if (n.contains('spotify') || n.contains('music') || n.contains('logic')) return Icons.music_note_rounded;
    if (n.contains('photo') || n.contains('figma') || n.contains('design') || n.contains('cut')) return Icons.palette_rounded;
    if (n.contains('docker')) return Icons.directions_boat_rounded;
    if (n.contains('terminal') || n.contains('iterm')) return Icons.developer_board_rounded;
    if (n.contains('mail')) return Icons.email_rounded;
    if (n.contains('simulator')) return Icons.smartphone_rounded;
    if (n.contains('clean') || n.contains('purge') || n.contains('keeper')) return Icons.auto_awesome_rounded;
    return Icons.window_rounded;
  }

  Color _getAppIconColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('xcode') || n.contains('chrome') || n.contains('safari')) return AppTheme.primaryBlue;
    if (n.contains('code') || n.contains('studio') || n.contains('discord')) return AppTheme.purpleGlow;
    if (n.contains('spotify') || n.contains('whatsapp') || n.contains('slack')) return AppTheme.emeraldGreen;
    if (n.contains('docker') || n.contains('figma') || n.contains('photo')) return AppTheme.cyanGlow;
    if (n.contains('cut') || n.contains('music') || n.contains('mail')) return AppTheme.coralRose;
    return AppTheme.amberGold;
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
      return const Center(
        child: CuteAppLoader(
          message: 'Scanning Installed Apps...',
          subMessage: 'Analyzing application bundles & support data',
        ),
      );
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
                            gradient: LinearGradient(
                              colors: [
                                _getAppIconColor(app.name).withValues(alpha: 0.25),
                                _getAppIconColor(app.name).withValues(alpha: 0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getAppIconColor(app.name).withValues(alpha: 0.3)),
                          ),
                          child: Icon(_getAppIcon(app.name), color: _getAppIconColor(app.name), size: 22),
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
