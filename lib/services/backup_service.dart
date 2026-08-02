import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static const int _version = 1;
  static const String _appName = 'REDCapCon';

  static const _listKeys = [
    'saved_sessions',
    'locked_sessions',
    'earned_badges',
    'visited_tabs',
    'browsed_years',
    'saved_session_types',
    'save_timestamps',
    'saved_keynote_plenary_ids',
  ];

  static const _stringKeys = ['selected_theme', 'time_format'];
  static const _intKeys = ['total_app_minutes'];

  // These prefixes identify dynamic per-session / per-badge int keys.
  static const _intPrefixes = ['earned_year_', 'session_toggles_'];

  Future<void> exportBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    final data = <String, dynamic>{};

    for (final key in _listKeys) {
      final val = prefs.getStringList(key);
      if (val != null) data[key] = val;
    }
    for (final key in _stringKeys) {
      final val = prefs.getString(key);
      if (val != null) data[key] = val;
    }
    for (final key in _intKeys) {
      final val = prefs.getInt(key);
      if (val != null) data[key] = val;
    }
    for (final key in allKeys) {
      for (final prefix in _intPrefixes) {
        if (key.startsWith(prefix)) {
          final val = prefs.getInt(key);
          if (val != null) data[key] = val;
        }
      }
    }

    final backup = {
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'appName': _appName,
      'data': data,
    };

    final json = const JsonEncoder.withIndent('  ').convert(backup);
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final filename = 'redcapcon_backup_'
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '.json';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(json);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json', name: filename)],
        subject: 'REDCapCon App Backup',
      ),
    );
  }

  /// Returns the count of sessions and badges that were restored.
  /// Throws [FormatException] if the file is invalid or not selected.
  Future<({int savedSessions, int earnedBadges})> importBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      throw const FormatException('No file selected');
    }

    final picked = result.files.first;
    final String content;
    if (picked.bytes != null) {
      content = utf8.decode(picked.bytes!);
    } else if (picked.path != null) {
      content = await File(picked.path!).readAsString();
    } else {
      throw const FormatException('Could not read backup file');
    }

    final backup = jsonDecode(content);
    if (backup is! Map<String, dynamic> || backup['appName'] != _appName) {
      throw const FormatException('Not a valid REDCapCon backup file');
    }

    final data = backup['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Backup data is missing or corrupted');
    }

    final prefs = await SharedPreferences.getInstance();
    for (final entry in data.entries) {
      final val = entry.value;
      if (val is List) {
        await prefs.setStringList(entry.key, List<String>.from(val));
      } else if (val is int) {
        await prefs.setInt(entry.key, val);
      } else if (val is String) {
        await prefs.setString(entry.key, val);
      }
    }

    return (
      savedSessions: (data['saved_sessions'] as List?)?.length ?? 0,
      earnedBadges: (data['earned_badges'] as List?)?.length ?? 0,
    );
  }
}
