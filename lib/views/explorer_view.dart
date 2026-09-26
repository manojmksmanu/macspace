import 'dart:io';
import 'package:flutter/material.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';

class ExplorerView extends StatefulWidget {
  const ExplorerView({super.key});

  @override
  State<ExplorerView> createState() => _ExplorerViewState();
}

class _ExplorerViewState extends State<ExplorerView> {
  SystemStorageData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await SystemStorageService.fetchRealSystemData();
    if (mounted) {
      setState(() {
        _data = d;
        _loading = false;
      });
    }
  }

  void _openFinder(String path) {
    final expanded = path.replaceAll('~', Platform.environment['HOME'] ?? '');
    Process.run('open', [expanded]);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _data == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.cyanGlow));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Storage Explorer',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Interactive directory hierarchy & disk consumption map',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSubtle,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBgTranslucent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: ListView.builder(
                itemCount: _data!.rootTreemapNode.children.length,
                itemBuilder: (context, index) {
                  final node = _data!.rootTreemapNode.children[index];
                  final pct = ((node.sizeGB / _data!.totalGB) * 100).toStringAsFixed(1);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.folder_rounded, color: AppTheme.cyanGlow, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                node.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                node.path,
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSubtle),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (node.sizeGB / _data!.totalGB * 2).clamp(0.05, 1.0),
                                  minHeight: 4,
                                  backgroundColor: AppTheme.borderColor.withValues(alpha: 0.3),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${node.sizeGB} GB',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textWhite,
                              ),
                            ),
                            Text(
                              '$pct% of drive',
                              style: const TextStyle(fontSize: 11, color: AppTheme.cyanGlow, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        IconButton(
                          icon: const Icon(Icons.folder_open_rounded, color: AppTheme.cyanGlow, size: 20),
                          onPressed: () => _openFinder(node.path),
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
