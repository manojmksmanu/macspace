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
    SidebarItemData(title: 'Developer Space 🛠️', icon: Icons.developer_board_rounded),
    SidebarItemData(title: 'Downloads', icon: Icons.download_rounded),
    SidebarItemData(title: 'Media Analyzer', icon: Icons.music_note_rounded),
    SidebarItemData(title: 'Trash Bin', icon: Icons.delete_outline_rounded),
    SidebarItemData(title: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? AppTheme.sidebarBg : AppTheme.sidebarBgLight;
    final textPrimary = isDark ? AppTheme.textWhite : AppTheme.textDark;
    final textMuted = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    final cardBg = isDark ? AppTheme.cardBgTranslucent : AppTheme.cardBgLight;
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;

    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // App Logo Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.cyanGlow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.cyanGlow.withValues(alpha: 0.35),
                        blurRadius: 14,
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
                    children: [
                      Text(
                        'Mac Storage',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.emeraldGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'ANALYZER PRO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.cyanGlow,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(color: borderColor, height: 1),
          ),
          const SizedBox(height: 12),

          // Navigation List
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onItemSelected(index),
                      hoverColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [AppTheme.primaryBlue, Color(0xFF2563EB)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 19,
                              color: isSelected ? Colors.white : textMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 5,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(4),
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

          // Theme Toggle Pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: AppTheme.themeModeNotifier,
              builder: (context, mode, _) {
                final isDarkMode = mode == ThemeMode.dark;
                return InkWell(
                  onTap: () => AppTheme.toggleThemeMode(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                key: ValueKey(isDarkMode),
                                size: 17,
                                color: isDarkMode ? AppTheme.cyanGlow : AppTheme.amberGold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isDarkMode ? 'Dark Studio' : 'Light Studio',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDarkMode ? AppTheme.primaryBlue.withValues(alpha: 0.2) : AppTheme.amberGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isDarkMode ? 'DARK' : 'LIGHT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isDarkMode ? AppTheme.cyanGlow : AppTheme.amberGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // macOS System Status Footer Card
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.apple_rounded,
                      size: 20,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'macOS Sequoia',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.emeraldGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Disk Ready • 100%',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
