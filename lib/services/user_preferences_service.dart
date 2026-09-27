import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

enum ViewMode { grid, list }
enum GridCardSize { small, medium, large, xlarge }

class UserPreferencesService {
  static String get _configPath {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/.macspace_config.json';
  }

  static Map<String, dynamic> _cache = {};
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final file = File(_configPath);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          _cache = jsonDecode(content) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint("Error reading user preferences: $e");
    }
    _initialized = true;
  }

  static Future<void> _save() async {
    try {
      final file = File(_configPath);
      await file.writeAsString(jsonEncode(_cache));
    } catch (e) {
      debugPrint("Error saving user preferences: $e");
    }
  }

  // --- View Mode ---
  static ViewMode getViewMode({ViewMode defaultValue = ViewMode.grid}) {
    final val = _cache['view_mode'];
    if (val == 'list') return ViewMode.list;
    if (val == 'grid') return ViewMode.grid;
    return defaultValue;
  }

  static Future<void> setViewMode(ViewMode mode) async {
    _cache['view_mode'] = mode == ViewMode.list ? 'list' : 'grid';
    await _save();
  }

  // --- Grid Card Size ---
  static GridCardSize getGridCardSize({GridCardSize defaultValue = GridCardSize.medium}) {
    final val = _cache['grid_card_size'];
    if (val == 'small') return GridCardSize.small;
    if (val == 'medium') return GridCardSize.medium;
    if (val == 'large') return GridCardSize.large;
    if (val == 'xlarge') return GridCardSize.xlarge;
    return defaultValue;
  }

  static Future<void> setGridCardSize(GridCardSize size) async {
    _cache['grid_card_size'] = size.name;
    await _save();
  }

  // --- Sort Option ---
  static String getSortOption({String defaultValue = 'size_desc'}) {
    return (_cache['sort_option'] as String?) ?? defaultValue;
  }

  static Future<void> setSortOption(String sortOption) async {
    _cache['sort_option'] = sortOption;
    await _save();
  }
}
