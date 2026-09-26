import 'dart:io';
import 'package:flutter/material.dart';
import '../models/storage_item.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';

class DownloadsView extends StatefulWidget {
  const DownloadsView({super.key});

  @override
  State<DownloadsView> createState() => _DownloadsViewState();
}

class _DownloadsViewState extends State<DownloadsView> {
  List<StorageFile> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await SystemStorageService.fetchRealDownloads();
    if (mounted) {
      setState(() {
        _files = list;
        _loading = false;
      });
    }
  }

  void _openInFinder(String name) {
    final home = Platform.environment['HOME'] ?? '';
    Process.run('open', ['$home/Downloads/$name']);
  }

  @override
  Widget build(BuildContext context) {
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
                children: const [
                  Text(
                    'Downloads Folder Analyzer',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Real downloaded files and archives in ~/Downloads',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSubtle,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh Folder'),
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
                color: AppTheme.cardBgTranslucent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: ListView.builder(
                itemCount: _files.length,
                itemBuilder: (context, index) {
                  final f = _files[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: f.iconColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(f.icon, color: f.iconColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.name,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textWhite,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${f.path} • ${f.type}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSubtle),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${f.sizeGB} GB',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        const SizedBox(width: 14),
                        IconButton(
                          icon: const Icon(Icons.folder_open_rounded, color: AppTheme.cyanGlow, size: 20),
                          onPressed: () => _openInFinder(f.name),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.coralRose, size: 20),
                          onPressed: () {
                            setState(() => _files.remove(f));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Deleted ${f.name}'),
                                backgroundColor: AppTheme.coralRose,
                              ),
                            );
                          },
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
