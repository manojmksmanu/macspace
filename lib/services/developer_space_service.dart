import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum DevJunkType {
  nodeModules,
  xcodeDerivedData,
  xcodeArchives,
  flutterBuild,
  gradleCache,
  cocoapodsCache,
  npmYarnCache,
  pythonVenv,
  rustTarget,
}

class DevJunkItem {
  final String id;
  final String projectName;
  final String fullPath;
  final DevJunkType type;
  final String typeName;
  final double sizeMB;
  final String formattedSize;
  final DateTime lastModified;
  final IconData icon;
  final Color themeColor;
  final String subTitle;
  final String safeToCleanNote;

  DevJunkItem({
    required this.id,
    required this.projectName,
    required this.fullPath,
    required this.type,
    required this.typeName,
    required this.sizeMB,
    required this.formattedSize,
    required this.lastModified,
    required this.icon,
    required this.themeColor,
    required this.subTitle,
    required this.safeToCleanNote,
  });

  double get sizeGB => sizeMB / 1024.0;
}

class DevSpaceSummary {
  final double totalSizeGB;
  final double nodeModulesSizeGB;
  final double xcodeSizeGB;
  final double flutterBuildSizeGB;
  final double packageCachesGB;
  final double pythonRustGB;
  final int totalItemCount;
  final List<DevJunkItem> items;

  DevSpaceSummary({
    required this.totalSizeGB,
    required this.nodeModulesSizeGB,
    required this.xcodeSizeGB,
    required this.flutterBuildSizeGB,
    required this.packageCachesGB,
    required this.pythonRustGB,
    required this.totalItemCount,
    required this.items,
  });
}

class DeveloperSpaceService {
  static Future<DevSpaceSummary> scanDeveloperSpace({
    void Function(double progress, String status)? onProgress,
  }) async {
    final List<DevJunkItem> results = [];
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) {
      return DevSpaceSummary(
        totalSizeGB: 0,
        nodeModulesSizeGB: 0,
        xcodeSizeGB: 0,
        flutterBuildSizeGB: 0,
        packageCachesGB: 0,
        pythonRustGB: 0,
        totalItemCount: 0,
        items: [],
      );
    }

    onProgress?.call(0.1, 'Scanning Xcode DerivedData & System Build Caches...');

    // 1. Xcode DerivedData
    final derivedDataPath = '$home/Library/Developer/Xcode/DerivedData';
    if (Directory(derivedDataPath).existsSync()) {
      final sizeMB = await _getFolderSizeMB(derivedDataPath);
      if (sizeMB > 5) {
        results.add(DevJunkItem(
          id: 'xcode_derived_data',
          projectName: 'Xcode DerivedData',
          fullPath: derivedDataPath,
          type: DevJunkType.xcodeDerivedData,
          typeName: 'Xcode Build Cache',
          sizeMB: sizeMB,
          formattedSize: formatSizeMB(sizeMB),
          lastModified: _getLastModified(derivedDataPath),
          icon: Icons.developer_mode_rounded,
          themeColor: AppTheme.primaryBlue,
          subTitle: 'Temporary Xcode build indexes & intermediate build files',
          safeToCleanNote: '100% Safe to delete. Xcode will rebuild indexes automatically when needed.',
        ));
      }
    }

    // 2. Xcode Archives
    final archivesPath = '$home/Library/Developer/Xcode/Archives';
    if (Directory(archivesPath).existsSync()) {
      final sizeMB = await _getFolderSizeMB(archivesPath);
      if (sizeMB > 10) {
        results.add(DevJunkItem(
          id: 'xcode_archives',
          projectName: 'Xcode App Archives',
          fullPath: archivesPath,
          type: DevJunkType.xcodeArchives,
          typeName: 'Xcode Archives',
          sizeMB: sizeMB,
          formattedSize: formatSizeMB(sizeMB),
          lastModified: _getLastModified(archivesPath),
          icon: Icons.inventory_2_rounded,
          themeColor: const Color(0xFF6366F1),
          subTitle: 'Old app build packages & dSYM debug symbols',
          safeToCleanNote: 'Contains previous iOS/macOS build archives for App Store upload.',
        ));
      }
    }

    onProgress?.call(0.3, 'Scanning Package Manager Caches (NPM, Yarn, CocoaPods, Gradle)...');

    // 3. CocoaPods Cache
    final podsCachePath = '$home/Library/Caches/CocoaPods';
    if (Directory(podsCachePath).existsSync()) {
      final sizeMB = await _getFolderSizeMB(podsCachePath);
      if (sizeMB > 5) {
        results.add(DevJunkItem(
          id: 'cocoapods_cache',
          projectName: 'CocoaPods Cache',
          fullPath: podsCachePath,
          type: DevJunkType.cocoapodsCache,
          typeName: 'iOS Dependency Cache',
          sizeMB: sizeMB,
          formattedSize: formatSizeMB(sizeMB),
          lastModified: _getLastModified(podsCachePath),
          icon: Icons.hub_rounded,
          themeColor: AppTheme.coralRose,
          subTitle: 'Cached Pod specs & downloaded iOS frameworks',
          safeToCleanNote: 'Safe to delete. Run pod install to re-fetch when building iOS projects.',
        ));
      }
    }

    // 4. Gradle Cache
    final gradleCachePath = '$home/.gradle/caches';
    if (Directory(gradleCachePath).existsSync()) {
      final sizeMB = await _getFolderSizeMB(gradleCachePath);
      if (sizeMB > 10) {
        results.add(DevJunkItem(
          id: 'gradle_cache',
          projectName: 'Gradle & Android Cache',
          fullPath: gradleCachePath,
          type: DevJunkType.gradleCache,
          typeName: 'Android Gradle Cache',
          sizeMB: sizeMB,
          formattedSize: formatSizeMB(sizeMB),
          lastModified: _getLastModified(gradleCachePath),
          icon: Icons.android_rounded,
          themeColor: AppTheme.amberGold,
          subTitle: 'Downloaded Android SDK dependencies & wrapper JARs',
          safeToCleanNote: 'Safe to clear. Gradle will re-download required dependencies on next build.',
        ));
      }
    }

    // 5. NPM Cache
    final npmCachePath = '$home/.npm/_cacache';
    if (Directory(npmCachePath).existsSync()) {
      final sizeMB = await _getFolderSizeMB(npmCachePath);
      if (sizeMB > 10) {
        results.add(DevJunkItem(
          id: 'npm_cache',
          projectName: 'NPM Global Cache',
          fullPath: npmCachePath,
          type: DevJunkType.npmYarnCache,
          typeName: 'Node Package Cache',
          sizeMB: sizeMB,
          formattedSize: formatSizeMB(sizeMB),
          lastModified: _getLastModified(npmCachePath),
          icon: Icons.javascript_rounded,
          themeColor: AppTheme.emeraldGreen,
          subTitle: 'Global NPM tarballs & HTTP cache',
          safeToCleanNote: 'Safe to clear. Equivalent to npm cache clean --force.',
        ));
      }
    }

    // 6. Yarn Berry Cache
    final yarnCachePath = '$home/.yarn/berry/cache';
    if (Directory(yarnCachePath).existsSync()) {
      final sizeMB = await _getFolderSizeMB(yarnCachePath);
      if (sizeMB > 10) {
        results.add(DevJunkItem(
          id: 'yarn_cache',
          projectName: 'Yarn Package Cache',
          fullPath: yarnCachePath,
          type: DevJunkType.npmYarnCache,
          typeName: 'Yarn Cache',
          sizeMB: sizeMB,
          formattedSize: formatSizeMB(sizeMB),
          lastModified: _getLastModified(yarnCachePath),
          icon: Icons.line_style_rounded,
          themeColor: AppTheme.cyanGlow,
          subTitle: 'Yarn package cache zip archives',
          safeToCleanNote: 'Safe to clear to reclaim disk space.',
        ));
      }
    }

    onProgress?.call(0.6, 'Scanning Projects for node_modules, Flutter build & .venv folders...');

    // Scan developer project roots
    final searchRoots = [
      '$home/Desktop',
      '$home/Documents',
      '$home/Downloads',
      '$home/dev',
      '$home/Projects',
      '$home/WebstormProjects',
      '$home/VSCodeProjects',
      '$home/code',
      '$home/src',
      '$home/git',
      '$home/workspace',
    ];

    final Set<String> scannedFolderPaths = {};

    for (final rootPath in searchRoots) {
      final rootDir = Directory(rootPath);
      if (!rootDir.existsSync()) continue;

      try {
        final entries = rootDir.listSync(recursive: false, followLinks: false);
        for (final entity in entries) {
          if (entity is Directory) {
            final dirName = entity.path.split('/').last;
            if (dirName.startsWith('.')) continue; // skip hidden dirs like .git

            // Sub-scan up to level 2 depth
            await _scanProjectFolder(entity.path, results, scannedFolderPaths);
          }
        }
      } catch (_) {}
    }

    onProgress?.call(1.0, 'Developer scan complete!');

    // Sort by size descending
    results.sort((a, b) => b.sizeMB.compareTo(a.sizeMB));

    double totalGB = 0;
    double nodeModulesGB = 0;
    double xcodeGB = 0;
    double flutterGB = 0;
    double packageCachesGB = 0;
    double pythonRustGB = 0;

    for (final item in results) {
      totalGB += item.sizeGB;
      switch (item.type) {
        case DevJunkType.nodeModules:
          nodeModulesGB += item.sizeGB;
          break;
        case DevJunkType.xcodeDerivedData:
        case DevJunkType.xcodeArchives:
          xcodeGB += item.sizeGB;
          break;
        case DevJunkType.flutterBuild:
          flutterGB += item.sizeGB;
          break;
        case DevJunkType.cocoapodsCache:
        case DevJunkType.gradleCache:
        case DevJunkType.npmYarnCache:
          packageCachesGB += item.sizeGB;
          break;
        case DevJunkType.pythonVenv:
        case DevJunkType.rustTarget:
          pythonRustGB += item.sizeGB;
          break;
      }
    }

    return DevSpaceSummary(
      totalSizeGB: double.parse(totalGB.toStringAsFixed(2)),
      nodeModulesSizeGB: double.parse(nodeModulesGB.toStringAsFixed(2)),
      xcodeSizeGB: double.parse(xcodeGB.toStringAsFixed(2)),
      flutterBuildSizeGB: double.parse(flutterGB.toStringAsFixed(2)),
      packageCachesGB: double.parse(packageCachesGB.toStringAsFixed(2)),
      pythonRustGB: double.parse(pythonRustGB.toStringAsFixed(2)),
      totalItemCount: results.length,
      items: results,
    );
  }

  static Future<void> _scanProjectFolder(
    String projectPath,
    List<DevJunkItem> results,
    Set<String> scannedFolderPaths,
  ) async {
    if (scannedFolderPaths.contains(projectPath)) return;
    scannedFolderPaths.add(projectPath);

    final projectDir = Directory(projectPath);
    if (!projectDir.existsSync()) return;

    final projectName = projectPath.split('/').last;

    // Check for node_modules
    final nodeModulesPath = '$projectPath/node_modules';
    if (Directory(nodeModulesPath).existsSync() && !scannedFolderPaths.contains(nodeModulesPath)) {
      scannedFolderPaths.add(nodeModulesPath);
      final sizeMB = await _getFolderSizeMB(nodeModulesPath);
      if (sizeMB > 1.0) {
        results.add(DevJunkItem(
          id: 'nm_${nodeModulesPath.hashCode}',
          projectName: projectName,
          fullPath: nodeModulesPath,
          type: DevJunkType.nodeModules,
          typeName: 'node_modules',
          sizeMB: sizeMB,
          formattedSize: formatSizeMB(sizeMB),
          lastModified: _getLastModified(nodeModulesPath),
          icon: Icons.hexagon_outlined,
          themeColor: AppTheme.emeraldGreen,
          subTitle: '$projectName / node_modules',
          safeToCleanNote: 'Re-install anytime by running "npm install" or "yarn install".',
        ));
      }
    }

    // Check for Flutter build / .dart_tool
    final flutterBuildPath = '$projectPath/build';
    final pubspecFile = File('$projectPath/pubspec.yaml');
    if (pubspecFile.existsSync() && Directory(flutterBuildPath).existsSync() && !scannedFolderPaths.contains(flutterBuildPath)) {
      scannedFolderPaths.add(flutterBuildPath);
      final sizeMB = await _getFolderSizeMB(flutterBuildPath);
      if (sizeMB > 1.0) {
        results.add(DevJunkItem(
          id: 'fl_${flutterBuildPath.hashCode}',
          projectName: projectName,
          fullPath: flutterBuildPath,
          type: DevJunkType.flutterBuild,
          typeName: 'Flutter Build Output',
          sizeMB: sizeMB,
          formattedSize: formatSizeMB(sizeMB),
          lastModified: _getLastModified(flutterBuildPath),
          icon: Icons.flutter_dash_rounded,
          themeColor: AppTheme.cyanGlow,
          subTitle: '$projectName / build',
          safeToCleanNote: 'Safe to clean. Equivalent to "flutter clean".',
        ));
      }
    }

    // Check for Python .venv / venv
    final venvPath = '$projectPath/.venv';
    final altVenvPath = '$projectPath/venv';
    String targetVenv = Directory(venvPath).existsSync() ? venvPath : (Directory(altVenvPath).existsSync() ? altVenvPath : '');
    if (targetVenv.isNotEmpty && !scannedFolderPaths.contains(targetVenv)) {
      scannedFolderPaths.add(targetVenv);
      final sizeMB = await _getFolderSizeMB(targetVenv);
      if (sizeMB > 5.0) {
        results.add(DevJunkItem(
          id: 'py_${targetVenv.hashCode}',
          projectName: projectName,
          fullPath: targetVenv,
          type: DevJunkType.pythonVenv,
          typeName: 'Python VirtualEnv',
          sizeMB: sizeMB,
          formattedSize: formatSizeMB(sizeMB),
          lastModified: _getLastModified(targetVenv),
          icon: Icons.terminal_rounded,
          themeColor: AppTheme.purpleGlow,
          subTitle: '$projectName / ${targetVenv.split('/').last}',
          safeToCleanNote: 'Can be recreated using "python -m venv venv && pip install -r requirements.txt".',
        ));
      }
    }

    // Check for Rust target/
    final cargoFile = File('$projectPath/Cargo.toml');
    final rustTargetPath = '$projectPath/target';
    if (cargoFile.existsSync() && Directory(rustTargetPath).existsSync() && !scannedFolderPaths.contains(rustTargetPath)) {
      scannedFolderPaths.add(rustTargetPath);
      final sizeMB = await _getFolderSizeMB(rustTargetPath);
      if (sizeMB > 5.0) {
        results.add(DevJunkItem(
          id: 'rs_${rustTargetPath.hashCode}',
          projectName: projectName,
          fullPath: rustTargetPath,
          type: DevJunkType.rustTarget,
          typeName: 'Cargo Target Directory',
          sizeMB: sizeMB,
          formattedSize: formatSizeMB(sizeMB),
          lastModified: _getLastModified(rustTargetPath),
          icon: Icons.build_circle_rounded,
          themeColor: AppTheme.coralRose,
          subTitle: '$projectName / target',
          safeToCleanNote: 'Safe to delete. Equivalent to "cargo clean".',
        ));
      }
    }

    // Check 1 level deeper subdirectories (for monorepos or project folders like ~/dev/macspace)
    try {
      final subEntries = projectDir.listSync(recursive: false, followLinks: false);
      for (final sub in subEntries) {
        if (sub is Directory) {
          final subName = sub.path.split('/').last;
          if (subName.startsWith('.') || subName == 'node_modules' || subName == 'build' || subName == 'target') continue;
          await _scanProjectFolder(sub.path, results, scannedFolderPaths);
        }
      }
    } catch (_) {}
  }

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

  static DateTime _getLastModified(String path) {
    try {
      final stat = FileStat.statSync(path);
      return stat.modified;
    } catch (_) {
      return DateTime.now();
    }
  }

  static String formatSizeMB(double mb) {
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  static Future<bool> cleanJunkItem(DevJunkItem item) async {
    try {
      final res = await Process.run('rm', ['-rf', item.fullPath]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
