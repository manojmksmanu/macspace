import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/sidebar.dart';
import 'views/chexy_dashboard_view.dart';
import 'views/dissect_explorer_view.dart';
import 'views/apps_manager_view.dart';
import 'views/junk_cleaner_view.dart';
import 'views/downloads_view.dart';
import 'views/trash_view.dart';
import 'views/generic_list_view.dart';

void main() {
  runApp(const MacStorageAnalyzerApp());
}

class MacStorageAnalyzerApp extends StatelessWidget {
  const MacStorageAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mac Storage Analyzer Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkStudioTheme,
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return const ChexyDashboardView(); // PAGE 1: Chexy Dashboard (Screenshot 1)
      case 1:
        return const DissectExplorerView(); // PAGE 2: DissectMac Treemap (Screenshot 2)
      case 2:
        return const GenericListView(
          title: 'Largest Files Inspector',
          subtitle: 'Real large individual files (>50MB) scanned across Macintosh HD',
          icon: Icons.insert_drive_file_outlined,
        );
      case 3:
        return const GenericListView(
          title: 'Duplicates Finder',
          subtitle: 'Identical file copies and redundant downloads detected on disk',
          icon: Icons.copy_rounded,
        );
      case 4:
        return const JunkCleanerView();
      case 5:
        return const AppsManagerView();
      case 6:
        return const DownloadsView();
      case 7:
        return const GenericListView(
          title: 'Media Analyzer',
          subtitle: 'Real video files, photo libraries, audio tracks, and recordings',
          icon: Icons.music_note_rounded,
        );
      case 8:
        return const TrashView();
      case 9:
        return const GenericListView(
          title: 'App Settings & Preferences',
          subtitle: 'Scan depth configuration, auto-clean rules, and system notifications',
          icon: Icons.settings_outlined,
        );
      default:
        return const ChexyDashboardView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Row(
        children: [
          // Left Sidebar Navigation
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          Container(
            width: 1,
            color: AppTheme.borderColor,
          ),
          // Main Body Content
          Expanded(
            child: Container(
              color: AppTheme.bgCanvas,
              child: _buildCurrentView(),
            ),
          ),
        ],
      ),
    );
  }
}
