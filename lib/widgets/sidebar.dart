import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SidebarItemData {
  final String title;
  final IconData icon;

  const SidebarItemData({required this.title, required this.icon});
}

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const List<SidebarItemData> items = [
    SidebarItemData(title: 'Dashboard', icon: Icons.grid_view_rounded),
    SidebarItemData(title: 'Storage Explorer', icon: Icons.folder_open_rounded),
    SidebarItemData(title: 'Largest Files', icon: Icons.insert_drive_file_outlined),
    SidebarItemData(title: 'Duplicates Finder', icon: Icons.copy_rounded),
    SidebarItemData(title: 'Junk Cleaner', icon: Icons.auto_awesome_rounded),
    SidebarItemData(title: 'Apps Manager', icon: Icons.apps_rounded),
    SidebarItemData(title: 'Downloads', icon: Icons.download_rounded),
    SidebarItemData(title: 'Media Analyzer', icon: Icons.music_note_rounded),
    SidebarItemData(title: 'Trash Bin', icon: Icons.delete_outline_rounded),
    SidebarItemData(title: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: AppTheme.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // App Logo Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.cyanGlow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.cyanGlow.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.storage_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Mac Storage',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textWhite,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'ANALYZER PRO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.cyanGlow,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Navigation List
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onItemSelected(index),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 18,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardBgTranslucent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.apple_rounded,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'macOS Sonoma',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      Text(
                        'v2.4.0 • Active',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.emeraldGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
