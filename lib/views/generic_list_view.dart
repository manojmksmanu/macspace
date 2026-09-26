import 'package:flutter/material.dart';
import '../services/system_storage_service.dart';
import '../theme/app_theme.dart';

class GenericListView extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const GenericListView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  State<GenericListView> createState() => _GenericListViewState();
}

class _GenericListViewState extends State<GenericListView> {
  ChexyStorageData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await SystemStorageService.fetchChexyData();
    if (mounted) {
      setState(() {
        _data = d;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _data == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.cyanGlow));
    }

    final files = _data!.categories.firstWhere((c) => c.key == 'large', orElse: () => _data!.categories.first).items;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: const TextStyle(
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
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
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
                          child: Icon(widget.icon, color: AppTheme.primaryBlue, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                              Text(
                                file.path,
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSubtle),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          file.sizeFormatted,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        const SizedBox(width: 14),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.coralRose, size: 20),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Cleaned ${file.name}'),
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
