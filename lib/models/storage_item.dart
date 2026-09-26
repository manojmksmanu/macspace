import 'package:flutter/material.dart';

class StorageCategory {
  final String name;
  final double sizeGB;
  final double percentage;
  final Color color;
  final IconData icon;

  const StorageCategory({
    required this.name,
    required this.sizeGB,
    required this.percentage,
    required this.color,
    required this.icon,
  });
}

class StorageFolder {
  final String name;
  final String path;
  final double sizeGB;
  final IconData icon;

  const StorageFolder({
    required this.name,
    required this.path,
    required this.sizeGB,
    this.icon = Icons.folder_rounded,
  });
}

class StorageFile {
  final String name;
  final String path;
  final double sizeGB;
  final IconData icon;
  final Color iconColor;
  final String type;

  const StorageFile({
    required this.name,
    required this.path,
    required this.sizeGB,
    required this.icon,
    this.iconColor = const Color(0xFF3B82F6),
    required this.type,
  });
}

class InstalledAppItem {
  final String name;
  final String path;
  final double sizeMB;
  final String sizeFormatted;

  InstalledAppItem({
    required this.name,
    required this.path,
    required this.sizeMB,
    required this.sizeFormatted,
  });
}

class JunkCacheItem {
  final String name;
  final String path;
  final double sizeMB;
  final String sizeFormatted;

  JunkCacheItem({
    required this.name,
    required this.path,
    required this.sizeMB,
    required this.sizeFormatted,
  });
}

class StorageRecommendation {
  final String title;
  final String subtitle;
  final String actionText;
  final double potentialSavingsGB;
  final IconData icon;
  final Color color;

  const StorageRecommendation({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.potentialSavingsGB,
    required this.icon,
    required this.color,
  });
}

