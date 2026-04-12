import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';
import '../data/mock_data.dart';
import '../data/mock_data_2025.dart';
import '../data/mock_data_2024.dart';
import '../data/mock_data_2023.dart';
import '../data/mock_data_2022.dart';
import 'notification_service.dart';
import 'json_api_service.dart';

class ScheduleService {
  static const String _savedSessionsKey = 'saved_sessions';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const String _cacheVersionKey = 'cache_version';
  static const int _currentCacheVersion = 8; // Increment this to invalidate old cache (v8: fixed notification CDT scheduling - times stored as CDT not UTC)

  final NotificationService _notificationService = NotificationService();
  final JsonApiService _jsonApiService = JsonApiService();

  /// Get cache key for specific year
  String _getCachedScheduleKey(int year) => 'cached_schedule_$year';

  /// Check and clear old cache if version mismatch
  Future<void> _checkCacheVersion() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(_cacheVersionKey) ?? 0;

    if (storedVersion != _currentCacheVersion) {
      // Clear all cached schedules
      for (var year in [2022, 2023, 2024, 2025, 2026]) {
        await prefs.remove(_getCachedScheduleKey(year));
      }
      await prefs.setInt(_cacheVersionKey, _currentCacheVersion);
      print('Cache cleared due to version mismatch');
    }
  }

  /// Fetch schedule - tries live API first, falls back to cached/mock data
  Future<List<Session>> fetchSchedule({bool forceRefresh = false, int year = 2026}) async {
    // Check and clear old cache if version mismatch
    await _checkCacheVersion();

    // If not forcing refresh, try cached data first
    if (!forceRefresh) {
      final cachedSessions = await _getCachedSchedule(year);
      if (cachedSessions != null && cachedSessions.isNotEmpty) {
        print('Using cached schedule for $year (${cachedSessions.length} sessions)');
        return cachedSessions;
      }
    }

    // Try to fetch from live API (only for 2026, current year)
    if (year == 2026) {
      try {
        print('Attempting to fetch 2026 schedule from JSON API...');
        final liveSessions = await _jsonApiService.fetchSchedule();
        print('Received ${liveSessions.length} sessions from JSON API');
        if (liveSessions.isNotEmpty) {
          // Cache the schedule
          await _cacheSchedule(liveSessions, year);
          print('Successfully fetched and cached ${liveSessions.length} sessions from JSON API');
          return liveSessions;
        } else {
          print('JSON API returned empty session list');
        }
      } catch (e) {
        print('FAILED to fetch from JSON API for 2026: $e');
        // Continue to fallback options
      }
    }

    // Try cached schedule as fallback
    final cachedSessions = await _getCachedSchedule(year);
    if (cachedSessions != null && cachedSessions.isNotEmpty) {
      print('Using cached schedule as fallback for $year (${cachedSessions.length} sessions)');
      return cachedSessions;
    }

    // Final fallback to bundled mock data
    print('Using bundled mock data for $year');
    var mockSessions = year == 2026
        ? MockData.getSessions()
        : year == 2025
            ? MockData2025.getSessions()
            : year == 2024
                ? MockData2024.getSessions()
                : year == 2023
                    ? MockData2023.getSessions()
                    : year == 2022
                        ? MockData2022.getSessions()
                        : <Session>[]; // Return empty list for years without data

    if (mockSessions.isEmpty) {
      print('No schedule data available for $year');
      return mockSessions;
    }

    // Cache the mock data for offline use
    await _cacheSchedule(mockSessions, year);

    return mockSessions;
  }


  /// Get cached schedule from local storage for specific year
  Future<List<Session>?> _getCachedSchedule(int year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_getCachedScheduleKey(year));

      if (cachedJson == null) return null;

      final List<dynamic> decoded = json.decode(cachedJson);
      final sessions = decoded.map((item) => Session.fromJson(item as Map<String, dynamic>)).toList();

      return sessions;
    } catch (e) {
      print('Error loading cached schedule for $year: $e');
      return null;
    }
  }

  /// Cache schedule data to local storage for specific year
  Future<void> _cacheSchedule(List<Session> sessions, int year) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert sessions to JSON
      final sessionsJson = sessions.map((s) => s.toJson()).toList();
      final jsonString = json.encode(sessionsJson);

      // Store in SharedPreferences with year-specific key
      await prefs.setString(_getCachedScheduleKey(year), jsonString);
      await prefs.setInt('cached_session_count_$year', sessions.length);
      await prefs.setString('${_cacheTimestampKey}_$year', DateTime.now().toIso8601String());

      print('Cached ${sessions.length} sessions for $year to local storage');
    } catch (e) {
      print('Error caching schedule for $year: $e');
    }
  }

  /// Get cache information
  Future<Map<String, dynamic>> getCacheInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('cached_session_count') ?? 0;
    final timestamp = prefs.getString(_cacheTimestampKey);

    return {
      'count': count,
      'timestamp': timestamp,
      'hasCachedData': count > 0,
    };
  }

  /// Clear all cached data for a specific year
  Future<void> clearCache({int? year}) async {
    final prefs = await SharedPreferences.getInstance();
    if (year != null) {
      await prefs.remove(_getCachedScheduleKey(year));
      await prefs.remove('cached_session_count_$year');
      await prefs.remove('${_cacheTimestampKey}_$year');
      print('Cache cleared for $year');
    } else {
      // Clear all years
      for (final y in [2022, 2023, 2024, 2025, 2026]) {
        await prefs.remove(_getCachedScheduleKey(y));
        await prefs.remove('cached_session_count_$y');
        await prefs.remove('${_cacheTimestampKey}_$y');
      }
      print('All caches cleared');
    }
  }


  // Save a session to personal schedule
  Future<void> saveSession(String sessionId, {Session? session}) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_savedSessionsKey) ?? [];
    if (!saved.contains(sessionId)) {
      saved.add(sessionId);
      await prefs.setStringList(_savedSessionsKey, saved);

      // Schedule notification if session object is provided and notifications are enabled
      if (session != null) {
        final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        if (notificationsEnabled) {
          await _notificationService.scheduleSessionReminder(session);
        }
      }
    }
  }

  // Remove a session from personal schedule
  Future<void> removeSession(String sessionId, {Session? session}) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_savedSessionsKey) ?? [];
    saved.remove(sessionId);
    await prefs.setStringList(_savedSessionsKey, saved);

    // Cancel notification if session object is provided
    if (session != null) {
      await _notificationService.cancelSessionReminder(session);
    }
  }

  // Check if a session is saved
  Future<bool> isSessionSaved(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_savedSessionsKey) ?? [];
    return saved.contains(sessionId);
  }

  // Get all saved session IDs
  Future<List<String>> getSavedSessionIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedSessionsKey) ?? [];
  }

  /// Cancel all existing notifications and reschedule for all saved sessions.
  /// Call this on app startup after fixing the CDT scheduling bug so any
  /// previously-scheduled notifications (which fired at the wrong time) are corrected.
  Future<void> rescheduleAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      if (!notificationsEnabled) return;

      // Cancel all pending notifications first
      await _notificationService.cancelAllReminders();

      // Load saved session IDs
      final savedIds = await getSavedSessionIds();
      if (savedIds.isEmpty) return;

      // Fetch 2026 sessions (the only year with future sessions)
      final sessions = await fetchSchedule(year: 2026);
      for (final session in sessions) {
        if (savedIds.contains(session.id)) {
          await _notificationService.scheduleSessionReminder(session);
        }
      }
      print('Rescheduled notifications for ${savedIds.length} saved sessions');
    } catch (e) {
      print('Error rescheduling notifications: $e');
    }
  }

  // Toggle session saved status
  Future<bool> toggleSession(String sessionId, {Session? session}) async {
    final isSaved = await isSessionSaved(sessionId);
    if (isSaved) {
      await removeSession(sessionId, session: session);
      return false;
    } else {
      await saveSession(sessionId, session: session);
      return true;
    }
  }
}
