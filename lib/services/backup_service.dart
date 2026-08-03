import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static const int _version = 1;
  static const String _appName = 'REDCapCon';

  // Changing this key invalidates all previously exported backups.
  static const String _hmacSecret = 'REDCapCon-backup-integrity-v1-2026';

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

  // Canonical (sorted-key) JSON so the HMAC is stable regardless of map
  // iteration order across platforms or Dart versions.
  static String _canonical(dynamic obj) {
    if (obj is Map) {
      final keys = obj.keys.toList()..sort();
      final entries = keys.map((k) => '"$k":${_canonical(obj[k])}').join(',');
      return '{$entries}';
    } else if (obj is List) {
      return '[${obj.map(_canonical).join(',')}]';
    } else {
      return jsonEncode(obj);
    }
  }

  static String _computeHmac(String canonicalData) {
    final key = utf8.encode(_hmacSecret);
    final bytes = utf8.encode(canonicalData);
    return Hmac(sha256, key).convert(bytes).toString();
  }

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

    final checksum = _computeHmac(_canonical(data));

    final backup = {
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'appName': _appName,
      'checksum': checksum,
      'data': data,
    };

    final json = const JsonEncoder.withIndent('  ').convert(backup);
    final now = DateTime.now();
    final filename = 'redcapcon_backup_'
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '.json';

    // Uses UIDocumentPickerViewController on iOS and Android Storage Access
    // Framework on Android — both let the user pick exactly where to save.
    await FilePicker.saveFile(
      dialogTitle: 'Save REDCapCon Backup',
      fileName: filename,
      bytes: utf8.encode(json),
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
  }

  /// Returns the count of sessions and badges that were restored.
  /// Throws [FormatException] if the file is invalid, tampered, or not selected.
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

    // Verify integrity — reject any file whose data doesn't match its checksum.
    final storedChecksum = backup['checksum'];
    if (storedChecksum is! String) {
      throw const FormatException('Backup file is missing integrity checksum');
    }
    final expectedChecksum = _computeHmac(_canonical(data));
    if (storedChecksum != expectedChecksum) {
      throw const FormatException(
          'Backup file has been modified and cannot be restored');
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
