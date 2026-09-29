import 'dart:io';
import 'package:flutter/material.dart';
import '../models/project_info.dart';
import '../theme/app_theme.dart';

class ProjectAnalyzerService {
  /// Opens native macOS Folder Picker using osascript, or returns null if cancelled
  static Future<String?> pickProjectsFolder() async {
    if (!Platform.isMacOS) return null;
    try {
      final res = await Process.run('osascript', [
        '-e',
        'POSIX path of (choose folder with prompt "Select your Projects Directory for Deep Analysis:")'
      ]);
      if (res.exitCode == 0) {
        final path = res.stdout.toString().trim();
        if (path.isNotEmpty && Directory(path).existsSync()) {
          return path;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Scans the given projects folder and analyzes each project inside
  static Future<List<ProjectInfo>> scanProjectsFolder({
    required String folderPath,
    void Function(double progress, String status)? onProgress,
  }) async {
    final List<ProjectInfo> projects = [];
    final rootDir = Directory(folderPath);
    if (!rootDir.existsSync()) return projects;

    onProgress?.call(0.05, 'Scanning projects directory: ${folderPath.split('/').last}...');

    final List<Directory> projectDirs = [];
    final Set<String> visitedPaths = {};

    try {
      final entries = rootDir.listSync(recursive: false, followLinks: false);
      for (final entry in entries) {
        if (entry is Directory) {
          final dirName = entry.path.split('/').last;
          if (dirName.startsWith('.')) continue; // skip hidden dirs like .git at root

          if (_isProjectDirectory(entry.path)) {
            projectDirs.add(entry);
          } else {
            // Check 1 level deeper subdirectories (for category folders or monorepos)
            try {
              final subEntries = entry.listSync(recursive: false, followLinks: false);
              for (final sub in subEntries) {
                if (sub is Directory) {
                  final subName = sub.path.split('/').last;
                  if (!subName.startsWith('.') &&
                      subName != 'node_modules' &&
                      subName != 'build' &&
                      subName != 'target' &&
                      _isProjectDirectory(sub.path)) {
                    projectDirs.add(sub);
                  }
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      onProgress?.call(1.0, 'Error reading directory');
      return projects;
    }

    if (projectDirs.isEmpty) {
      // If the folderPath itself is a single project
      if (_isProjectDirectory(folderPath)) {
        projectDirs.add(rootDir);
      }
    }

    onProgress?.call(0.15, 'Found ${projectDirs.length} projects. Analyzing size, dependencies & cache...');

    final int totalCount = projectDirs.length;
    for (int i = 0; i < totalCount; i++) {
      final dir = projectDirs[i];
      if (visitedPaths.contains(dir.path)) continue;
      visitedPaths.add(dir.path);

      final progress = 0.15 + (0.80 * ((i + 1) / (totalCount == 0 ? 1 : totalCount)));
      final projectName = dir.path.split('/').last;
      onProgress?.call(progress, 'Analyzing $projectName (${i + 1}/$totalCount)...');

      final projectInfo = await _analyzeSingleProject(dir.path);
      if (projectInfo != null) {
        projects.add(projectInfo);
      }
    }

    onProgress?.call(1.0, 'Analysis complete!');

    // Sort by reclaimable cache size descending by default
    projects.sort((a, b) => b.reclaimableSizeMB.compareTo(a.reclaimableSizeMB));

    return projects;
  }

  /// Checks if a directory contains indicators of being a coding project root
  static bool _isProjectDirectory(String path) {
    if (File('$path/package.json').existsSync()) return true;
    if (File('$path/pubspec.yaml').existsSync()) return true;
    if (File('$path/Cargo.toml').existsSync()) return true;
    if (File('$path/requirements.txt').existsSync() || File('$path/pyproject.toml').existsSync()) return true;
    if (File('$path/build.gradle').existsSync() || File('$path/pom.xml').existsSync()) return true;
    if (File('$path/go.mod').existsSync()) return true;
    if (File('$path/Podfile').existsSync() || File('$path/Gemfile').existsSync()) return true;
    if (Directory('$path/.git').existsSync()) return true;

    // Check if it has source directories
    if (Directory('$path/src').existsSync() || Directory('$path/lib').existsSync()) return true;

    return false;
  }

  /// Deep analyzes a single project folder
  static Future<ProjectInfo?> _analyzeSingleProject(String projectPath) async {
    final dir = Directory(projectPath);
    if (!dir.existsSync()) return null;

    final projectName = projectPath.split('/').last;

    // 1. Detect Tech Stack
    final techStackData = _detectTechStack(projectPath);
    final techStack = techStackData['type'] as ProjectTechStack;
    final techName = techStackData['name'] as String;
    final techIcon = techStackData['icon'] as IconData;
    final techColor = techStackData['color'] as Color;

    // 2. Check cache & dependency directories
    final List<ProjectCacheSubDetail> cacheDetails = [];

    // node_modules
    double nodeModulesSizeMB = 0.0;
    int nodeModulesPkgCount = 0;
    final nodeModulesDir = Directory('$projectPath/node_modules');
    if (nodeModulesDir.existsSync()) {
      nodeModulesSizeMB = await _getFolderSizeMB(nodeModulesDir.path);
      nodeModulesPkgCount = _countNodeModulesPackages(nodeModulesDir.path);
      if (nodeModulesSizeMB > 0.5) {
        cacheDetails.add(ProjectCacheSubDetail(
          name: 'node_modules',
          path: nodeModulesDir.path,
          sizeMB: nodeModulesSizeMB,
          formattedSize: formatSizeMB(nodeModulesSizeMB),
          icon: Icons.hexagon_outlined,
          color: AppTheme.emeraldGreen,
          description: '$nodeModulesPkgCount NPM/Yarn dependencies',
        ));
      }
    }

    // Build directory (build, dist, .next, target, out)
    double buildOutputSizeMB = 0.0;
    final buildPaths = ['$projectPath/build', '$projectPath/dist', '$projectPath/.next', '$projectPath/target', '$projectPath/out'];
    for (final bPath in buildPaths) {
      if (Directory(bPath).existsSync()) {
        final bSize = await _getFolderSizeMB(bPath);
        if (bSize > 0.5) {
          buildOutputSizeMB += bSize;
          final bName = bPath.split('/').last;
          cacheDetails.add(ProjectCacheSubDetail(
            name: bName,
            path: bPath,
            sizeMB: bSize,
            formattedSize: formatSizeMB(bSize),
            icon: Icons.build_circle_rounded,
            color: AppTheme.amberGold,
            description: 'Compiled build output directory',
          ));
        }
      }
    }

    // Framework / Dev Caches (.dart_tool, Pods, .venv, venv, __pycache__, .cache, .turbo, .git)
    double cacheSizeMB = 0.0;
    final cachePaths = [
      '$projectPath/.dart_tool',
      '$projectPath/Pods',
      '$projectPath/.venv',
      '$projectPath/venv',
      '$projectPath/__pycache__',
      '$projectPath/.cache',
      '$projectPath/.turbo',
    ];
    for (final cPath in cachePaths) {
      if (Directory(cPath).existsSync()) {
        final cSize = await _getFolderSizeMB(cPath);
        if (cSize > 0.5) {
          cacheSizeMB += cSize;
          final cName = cPath.split('/').last;
          cacheDetails.add(ProjectCacheSubDetail(
            name: cName,
            path: cPath,
            sizeMB: cSize,
            formattedSize: formatSizeMB(cSize),
            icon: Icons.cached_rounded,
            color: AppTheme.purpleGlow,
            description: 'Project cache & local virtual environment',
          ));
        }
      }
    }

    // .git directory size
    final gitDir = Directory('$projectPath/.git');
    if (gitDir.existsSync()) {
      final gitSize = await _getFolderSizeMB(gitDir.path);
      if (gitSize > 2.0) {
        cacheDetails.add(ProjectCacheSubDetail(
          name: '.git history',
          path: gitDir.path,
          sizeMB: gitSize,
          formattedSize: formatSizeMB(gitSize),
          icon: Icons.history_rounded,
          color: AppTheme.cyanGlow,
          description: 'Git repository commit history & objects',
        ));
      }
    }

    // 3. Total Project Size & File Count & Last Modified
    final totalSizeMB = await _getFolderSizeMB(projectPath);
    final fileStats = await _getProjectFileStats(projectPath);
    final lastModified = fileStats['lastModified'] as DateTime;
    final totalFiles = fileStats['totalFiles'] as int;

    final reclaimableSizeMB = nodeModulesSizeMB + buildOutputSizeMB + cacheSizeMB;
    final codeSizeMB = (totalSizeMB - reclaimableSizeMB).clamp(0.0, totalSizeMB);

    final relativeTimeStr = _formatRelativeTime(lastModified);

    // 4. Determine Health Status & Recommendation
    final health = _calculateHealth(
      nodeModulesMB: nodeModulesSizeMB,
      buildMB: buildOutputSizeMB,
      reclaimableMB: reclaimableSizeMB,
      lastModified: lastModified,
    );

    return ProjectInfo(
      id: 'proj_${projectPath.hashCode}',
      name: projectName,
      fullPath: projectPath,
      techStack: techStack,
      techStackName: techName,
      techIcon: techIcon,
      techColor: techColor,
      lastModified: lastModified,
      relativeLastUpdated: relativeTimeStr,
      totalFiles: totalFiles,
      totalSizeMB: totalSizeMB,
      formattedTotalSize: formatSizeMB(totalSizeMB),
      codeSizeMB: codeSizeMB,
      nodeModulesSizeMB: nodeModulesSizeMB,
      nodeModulesPackageCount: nodeModulesPkgCount,
      buildOutputSizeMB: buildOutputSizeMB,
      cacheSizeMB: cacheSizeMB,
      reclaimableSizeMB: reclaimableSizeMB,
      formattedReclaimableSize: formatSizeMB(reclaimableSizeMB),
      healthStatus: health['status'] as String,
      healthColor: health['color'] as Color,
      healthMessage: health['message'] as String,
      cacheDetails: cacheDetails,
    );
  }

  /// Detects project tech stack type, icon, and theme color
  static Map<String, dynamic> _detectTechStack(String path) {
    if (File('$path/pubspec.yaml').existsSync()) {
      return {
        'type': ProjectTechStack.flutter,
        'name': 'Flutter / Dart',
        'icon': Icons.flutter_dash_rounded,
        'color': const Color(0xFF0286FF),
      };
    }
    if (File('$path/next.config.js').existsSync() ||
        File('$path/next.config.mjs').existsSync() ||
        File('$path/next.config.ts').existsSync()) {
      return {
        'type': ProjectTechStack.nextJs,
        'name': 'Next.js',
        'icon': Icons.auto_awesome_rounded,
        'color': const Color(0xFFE2E8F0),
      };
    }
    if (File('$path/package.json').existsSync()) {
      return {
        'type': ProjectTechStack.reactNode,
        'name': 'Node.js / React',
        'icon': Icons.javascript_rounded,
        'color': AppTheme.emeraldGreen,
      };
    }
    if (File('$path/Cargo.toml').existsSync()) {
      return {
        'type': ProjectTechStack.rust,
        'name': 'Rust (Cargo)',
        'icon': Icons.build_circle_rounded,
        'color': AppTheme.coralRose,
      };
    }
    if (File('$path/requirements.txt').existsSync() ||
        File('$path/pyproject.toml').existsSync() ||
        File('$path/Pipfile').existsSync()) {
      return {
        'type': ProjectTechStack.python,
        'name': 'Python',
        'icon': Icons.terminal_rounded,
        'color': AppTheme.purpleGlow,
      };
    }
    if (File('$path/Podfile').existsSync() || Directory('$path/.xcodeproj').existsSync()) {
      return {
        'type': ProjectTechStack.iosSwift,
        'name': 'iOS / Swift',
        'icon': Icons.phone_iphone_rounded,
        'color': AppTheme.primaryBlue,
      };
    }
    if (File('$path/build.gradle').existsSync() || File('$path/pom.xml').existsSync()) {
      return {
        'type': ProjectTechStack.androidJava,
        'name': 'Android / Java',
        'icon': Icons.android_rounded,
        'color': AppTheme.amberGold,
      };
    }
    if (File('$path/go.mod').existsSync()) {
      return {
        'type': ProjectTechStack.go,
        'name': 'Go',
        'icon': Icons.code_rounded,
        'color': AppTheme.cyanGlow,
      };
    }

    return {
      'type': ProjectTechStack.general,
      'name': 'Code Project',
      'icon': Icons.code_rounded,
      'color': const Color(0xFF94A3B8),
    };
  }

  /// Counts direct package folders in node_modules
  static int _countNodeModulesPackages(String nodeModulesPath) {
    try {
      final dir = Directory(nodeModulesPath);
      if (!dir.existsSync()) return 0;
      int count = 0;
      final entries = dir.listSync(recursive: false, followLinks: false);
      for (final e in entries) {
        if (e is Directory) {
          final name = e.path.split('/').last;
          if (name.startsWith('@')) {
            // Scoped packages folder
            try {
              final scoped = e.listSync(recursive: false, followLinks: false);
              count += scoped.whereType<Directory>().length;
            } catch (_) {}
          } else if (!name.startsWith('.')) {
            count++;
          }
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Calculates folder size in MB using `du -sk`
  static Future<double> _getFolderSizeMB(String path) async {
    try {
      final res = await Process.run('du', ['-sk', path]);
      if (res.exitCode == 0) {
        final line = res.stdout.toString().trim();
        final parts = line.split(RegExp(r'\s+'));
        if (parts.isNotEmpty) {
          final kb = double.tryParse(parts[0]) ?? 0;
          return kb / 1024.0;
        }
      }
    } catch (_) {}
    return 0.0;
  }

  /// Scans file stats (latest modified date and total non-cache source files count)
  static Future<Map<String, dynamic>> _getProjectFileStats(String projectPath) async {
    DateTime latest = DateTime(2000, 1, 1);
    int fileCount = 0;

    try {
      final dir = Directory(projectPath);
      final entries = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entries) {
        if (entity is File) {
          final p = entity.path;
          if (p.contains('/node_modules/') ||
              p.contains('/build/') ||
              p.contains('/.next/') ||
              p.contains('/target/') ||
              p.contains('/.dart_tool/') ||
              p.contains('/Pods/') ||
              p.contains('/.git/')) {
            continue;
          }
          fileCount++;
          final stat = entity.statSync();
          if (stat.modified.isAfter(latest)) {
            latest = stat.modified;
          }
        }
      }
    } catch (_) {}

    if (latest.year == 2000) {
      try {
        latest = FileStat.statSync(projectPath).modified;
      } catch (_) {
        latest = DateTime.now();
      }
    }

    return {
      'lastModified': latest,
      'totalFiles': fileCount,
    };
  }

  /// Formats relative time (e.g. "Just now", "3 hours ago", "5 days ago", "2 months ago")
  static String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).toStringAsFixed(1)}y ago';
  }

  /// Determines project health status & actionable suggestion
  static Map<String, dynamic> _calculateHealth({
    required double nodeModulesMB,
    required double buildMB,
    required double reclaimableMB,
    required DateTime lastModified,
  }) {
    final daysInactive = DateTime.now().difference(lastModified).inDays;

    if (reclaimableMB > 300 && daysInactive > 30) {
      return {
        'status': 'Inactive (Needs Clean)',
        'color': AppTheme.coralRose,
        'message': 'Inactive for $daysInactive days. Cleaning cache frees ${formatSizeMB(reclaimableMB)}!',
      };
    } else if (nodeModulesMB > 400) {
      return {
        'status': 'Heavy node_modules',
        'color': AppTheme.amberGold,
        'message': 'Large node_modules (${formatSizeMB(nodeModulesMB)}). Re-install anytime.',
      };
    } else if (reclaimableMB > 200) {
      return {
        'status': 'Large Build/Cache',
        'color': AppTheme.cyanGlow,
        'message': '${formatSizeMB(reclaimableMB)} reclaimable cache & build output.',
      };
    } else {
      return {
        'status': 'Clean & Active',
        'color': AppTheme.emeraldGreen,
        'message': 'Project cache is optimized.',
      };
    }
  }

  /// Utility to format size MB to GB/MB
  static String formatSizeMB(double mb) {
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Deletes selected cache item or full project cache/node_modules
  static Future<bool> deleteCachePath(String path) async {
    try {
      final res = await Process.run('rm', ['-rf', path]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
