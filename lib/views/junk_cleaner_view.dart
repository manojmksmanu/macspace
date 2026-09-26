import 'package:flutter/material.dart';
import '../models/storage_item.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cute_app_loader.dart';

class JunkCleanerView extends StatefulWidget {
  const JunkCleanerView({super.key});

  @override
  State<JunkCleanerView> createState() => _JunkCleanerState();
}

class _JunkCleanerState extends State<JunkCleanerView> {
  List<JunkCacheItem> _junkItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadJunk();
  }

  Future<void> _loadJunk() async {
    final list = await SystemStorageService.fetchRealJunkCaches();
    if (mounted) {
      setState(() {
        _junkItems = list;
        _loading = false;
      });
    }
  }

  void _cleanJunk(JunkCacheItem item) {
    setState(() {
      _junkItems.remove(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cleaned ${item.name}! Saved ${item.sizeFormatted}'),
        backgroundColor: AppTheme.emeraldGreen,
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
      return const Center(
        child: CuteAppLoader(
          message: 'Scanning System Caches...',
          subMessage: 'Identifying cleanable temporary files & logs',
        ),
      );
    }

    final totalMB = _junkItems.fold<double>(0, (sum, i) => sum + i.sizeMB);
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
                    'System Junk & Cache Cleaner',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real system caches, logs, & DerivedData • Cleanable Junk: $totalGB GB',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _junkItems.clear());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All system caches cleaned successfully!'),
                      backgroundColor: AppTheme.emeraldGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Purge All Junk'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.amberGold,
                  foregroundColor: Colors.black,
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
              child: ListView.builder(
                itemCount: _junkItems.length,
                itemBuilder: (context, index) {
                  final item = _junkItems[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
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
                            color: AppTheme.purpleGlow.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.cleaning_services_rounded, color: AppTheme.purpleGlow, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                item.path,
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          item.sizeFormatted,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        ElevatedButton(
                          onPressed: () => _cleanJunk(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.amberGold.withValues(alpha: 0.2),
                            foregroundColor: AppTheme.amberGold,
                            elevation: 0,
                          ),
                          child: const Text('Clean Cache'),
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
