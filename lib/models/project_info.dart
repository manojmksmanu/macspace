import 'package:flutter/material.dart';

enum ProjectTechStack {
  flutter,
  reactNode,
  nextJs,
  vueNuxt,
  python,
  rust,
  iosSwift,
  androidJava,
  go,
  general,
}

class ProjectCacheSubDetail {
  final String name;
  final String path;
  final double sizeMB;
  final String formattedSize;
  final IconData icon;
  final Color color;
  final String description;

  ProjectCacheSubDetail({
    required this.name,
    required this.path,
    required this.sizeMB,
    required this.formattedSize,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class ProjectInfo {
  final String id;
  final String name;
  final String fullPath;
  final ProjectTechStack techStack;
  final String techStackName;
  final IconData techIcon;
  final Color techColor;
  final DateTime lastModified;
  final String relativeLastUpdated;
  final int totalFiles;
  final double totalSizeMB;
  final String formattedTotalSize;
  final double codeSizeMB;
  final double nodeModulesSizeMB;
  final int nodeModulesPackageCount;
  final double buildOutputSizeMB;
  final double cacheSizeMB;
  final double reclaimableSizeMB;
  final String formattedReclaimableSize;
  final String healthStatus;
  final Color healthColor;
  final String healthMessage;
  final List<ProjectCacheSubDetail> cacheDetails;

  ProjectInfo({
    required this.id,
    required this.name,
    required this.fullPath,
    required this.techStack,
    required this.techStackName,
    required this.techIcon,
    required this.techColor,
    required this.lastModified,
    required this.relativeLastUpdated,
    required this.totalFiles,
    required this.totalSizeMB,
    required this.formattedTotalSize,
    required this.codeSizeMB,
    required this.nodeModulesSizeMB,
    required this.nodeModulesPackageCount,
    required this.buildOutputSizeMB,
    required this.cacheSizeMB,
    required this.reclaimableSizeMB,
    required this.formattedReclaimableSize,
    required this.healthStatus,
    required this.healthColor,
    required this.healthMessage,
    required this.cacheDetails,
  });

  bool get hasCleanableCache => reclaimableSizeMB > 1.0;
  bool get isInactive => DateTime.now().difference(lastModified).inDays > 30;
}
