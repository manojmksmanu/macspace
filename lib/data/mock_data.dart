import 'package:flutter/material.dart';
import '../models/storage_item.dart';

class MockData {
  static const double totalStorageGB = 512.0;
  static const double usedStorageGB = 347.2;
  static const double freeStorageGB = 164.8;
  static const String totalFiles = "1,248,932";
  static const String totalFolders = "312,421";
  static const String lastScanTime = "Today, 10:24 AM";

  static final List<StorageCategory> categories = [
    const StorageCategory(
      name: "Applications",
      sizeGB: 86.4,
      percentage: 16.9,
      color: Color(0xFF2563EB),
      icon: Icons.apps_rounded,
    ),
    const StorageCategory(
      name: "Documents",
      sizeGB: 72.8,
      percentage: 14.2,
      color: Color(0xFFF97316),
      icon: Icons.description_rounded,
    ),
    const StorageCategory(
      name: "System Data",
      sizeGB: 61.3,
      percentage: 12.0,
      color: Color(0xFFA855F7),
      icon: Icons.memory_rounded,
    ),
    const StorageCategory(
      name: "Images",
      sizeGB: 48.7,
      percentage: 9.5,
      color: Color(0xFF22C55E),
      icon: Icons.image_rounded,
    ),
    const StorageCategory(
      name: "Downloads",
      sizeGB: 31.6,
      percentage: 6.2,
      color: Color(0xFFEF4444),
      icon: Icons.download_rounded,
    ),
    const StorageCategory(
      name: "Videos",
      sizeGB: 24.3,
      percentage: 4.7,
      color: Color(0xFFEAB308),
      icon: Icons.videocam_rounded,
    ),
    const StorageCategory(
      name: "Audio",
      sizeGB: 12.8,
      percentage: 2.5,
      color: Color(0xFFEC4899),
      icon: Icons.music_note_rounded,
    ),
    const StorageCategory(
      name: "Other",
      sizeGB: 22.1,
      percentage: 4.3,
      color: Color(0xFF94A3B8),
      icon: Icons.more_horiz_rounded,
    ),
  ];

  static final List<StorageCategory> fileTypes = [
    const StorageCategory(
      name: "Executables (.app)",
      sizeGB: 104.8,
      percentage: 20.5,
      color: Color(0xFF2563EB),
      icon: Icons.terminal_rounded,
    ),
    const StorageCategory(
      name: "Archives (.zip, .dmg)",
      sizeGB: 45.2,
      percentage: 8.8,
      color: Color(0xFFF97316),
      icon: Icons.folder_zip_rounded,
    ),
    const StorageCategory(
      name: "Media Files (.mov, .mp4)",
      sizeGB: 37.1,
      percentage: 7.2,
      color: Color(0xFFEAB308),
      icon: Icons.movie_creation_rounded,
    ),
    const StorageCategory(
      name: "Code & Cache",
      sizeGB: 68.4,
      percentage: 13.4,
      color: Color(0xFFA855F7),
      icon: Icons.code_rounded,
    ),
    const StorageCategory(
      name: "Raw Images (.png, .jpg)",
      sizeGB: 48.7,
      percentage: 9.5,
      color: Color(0xFF22C55E),
      icon: Icons.photo_library_rounded,
    ),
    const StorageCategory(
      name: "Virtual Disks",
      sizeGB: 22.0,
      percentage: 4.3,
      color: Color(0xFF64748B),
      icon: Icons.dns_rounded,
    ),
    const StorageCategory(
      name: "System Files",
      sizeGB: 21.0,
      percentage: 4.1,
      color: Color(0xFF94A3B8),
      icon: Icons.settings_system_daydream_rounded,
    ),
  ];

  static final List<StorageFolder> largestFolders = [
    const StorageFolder(name: "Library", path: "~/Library", sizeGB: 54.8),
    const StorageFolder(name: "Applications", path: "~/Applications", sizeGB: 42.3),
    const StorageFolder(name: "Documents", path: "~/Documents", sizeGB: 31.7),
    const StorageFolder(name: "Downloads", path: "~/Downloads", sizeGB: 18.4),
    const StorageFolder(name: "Developer", path: "~/Developer", sizeGB: 16.2),
  ];

  static final List<StorageFile> largestFiles = [
    const StorageFile(
      name: "Xcode.app",
      path: "/Applications",
      sizeGB: 18.4,
      icon: Icons.code_rounded,
      iconColor: Color(0xFF0284C7),
      type: "Application",
    ),
    const StorageFile(
      name: "Android Studio.app",
      path: "/Applications",
      sizeGB: 12.7,
      icon: Icons.android_rounded,
      iconColor: Color(0xFF16A34A),
      type: "Application",
    ),
    const StorageFile(
      name: "Docker.raw",
      path: "~/Library/Containers",
      sizeGB: 9.3,
      icon: Icons.insert_drive_file_rounded,
      iconColor: Color(0xFF64748B),
      type: "Disk Image",
    ),
    const StorageFile(
      name: "iOS Simulator",
      path: "~/Library/Developer",
      sizeGB: 8.1,
      icon: Icons.phone_iphone_rounded,
      iconColor: Color(0xFF0284C7),
      type: "Developer Tool",
    ),
    const StorageFile(
      name: "WhatsApp.app",
      path: "/Applications",
      sizeGB: 4.6,
      icon: Icons.chat_rounded,
      iconColor: Color(0xFF22C55E),
      type: "Application",
    ),
  ];

  static final List<StorageFile> recentLargeFiles = [
    const StorageFile(
      name: "Screen Recording.mov",
      path: "~/Movies",
      sizeGB: 3.2,
      icon: Icons.video_file_rounded,
      iconColor: Color(0xFFEAB308),
      type: "Video",
    ),
    const StorageFile(
      name: "Project.zip",
      path: "~/Documents",
      sizeGB: 2.8,
      icon: Icons.folder_zip_rounded,
      iconColor: Color(0xFFF97316),
      type: "Archive",
    ),
    const StorageFile(
      name: "VMware Virtual Disk.vmdk",
      path: "~/Virtual Machines",
      sizeGB: 2.4,
      icon: Icons.storage_rounded,
      iconColor: Color(0xFF475569),
      type: "Virtual Disk",
    ),
    const StorageFile(
      name: "Database.dump",
      path: "~/Downloads",
      sizeGB: 1.9,
      icon: Icons.dataset_rounded,
      iconColor: Color(0xFF6366F1),
      type: "Database",
    ),
    const StorageFile(
      name: "Presentation.key",
      path: "~/Documents",
      sizeGB: 1.6,
      icon: Icons.slideshow_rounded,
      iconColor: Color(0xFF3B82F6),
      type: "Presentation",
    ),
  ];
}
