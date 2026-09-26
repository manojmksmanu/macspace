import 'dart:io';
import 'package:flutter/material.dart';
import '../models/storage_item.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';

class TrashView extends StatefulWidget {
  const TrashView({super.key});

  @override
  State<TrashView> createState() => _TrashViewState();
}

class _TrashViewState extends State<TrashView> {
  List<StorageFile> _trashItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await SystemStorageService.fetchRealTrashFiles();
    if (mounted) {
      setState(() {
        _trashItems = list;
        _loading = false;
      });
    }
  }

  void _emptyTrash() async {
    try {
      await Process.run('osascript', ['-e', 'tell application "Finder" to empty trash without warnings']);
    } catch (_) {
      final home = Platform.environment['HOME'] ?? '';
      await Process.run('rm', ['-rf', '$home/.Trash/*']);
    }
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('macOS Trash bin emptied!'),
          backgroundColor: AppTheme.emeraldGreen,
        ),
      );
    }
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
                    'macOS Trash Bin Purger',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real deleted items inside ~/.Trash',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _trashItems.isEmpty ? null : _emptyTrash,
                icon: const Icon(Icons.delete_forever_rounded, size: 18),
                label: const Text('Empty Trash Bin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.coralRose,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
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
              child: _trashItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Trash Bin is Empty!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No deleted files currently accumulating space in ~/.Trash',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _trashItems.length,
                      itemBuilder: (context, index) {
                        final item = _trashItems[index];
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
                                  color: AppTheme.coralRose.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: AppTheme.coralRose, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textPrimary),
                                    ),
                                    Text(item.path, style: TextStyle(fontSize: 11, color: textSecondary)),
                                  ],
                                ),
                              ),
                              Text(
                                '${item.sizeGB} GB',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
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
