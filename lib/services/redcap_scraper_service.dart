import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/session.dart';

/// Service to fetch and parse REDCap Conference schedule
class RedCapScraperService {
  // URLs for different years
  static const Map<int, String> scheduleUrls = {
    2026: 'https://redcap.vumc.org/surveys/?__report=Y7EMJR9L797FTX83',
    2025: 'https://redcap.vumc.org/surveys/?__report=R7MDEEJTA89C34MH',
    2024: 'https://redcap.vumc.org/surveys/?__report=LXMLYK3R3JHDJCP7',
  };

  /// Fetch the schedule from the URL for the specified year
  Future<List<Session>> fetchSchedule({int year = 2026}) async {
    try {
      final url = scheduleUrls[year];
      if (url == null) {
        throw Exception('No URL configured for year $year');
      }

      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // Parse HTML and extract table data
        return _parseHtmlSchedule(response.body, year);
      } else {
        throw Exception('Failed to load schedule: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching schedule: $e');
    }
  }

  /// Parse HTML schedule and extract session data
  List<Session> _parseHtmlSchedule(String htmlContent, int year) {
    final document = html_parser.parse(htmlContent);
    final sessions = <Session>[];

    // Find all tables
    final tables = document.querySelectorAll('table');

    String? currentDate;
    int sessionIndex = 1;

    for (var table in tables) {
      // Get the date from the previous .session-date div
      final dateDiv = table.previousElementSibling;
      if (dateDiv != null && dateDiv.className.contains('session-date')) {
        currentDate = dateDiv.text.trim();
      }

      // Get all rows except header
      final rows = table.querySelectorAll('tbody tr');

      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.length >= 7) {
          try {
            final session = _createSessionFromHtmlRow(
              sessionIndex++,
              currentDate ?? '',
              cells,
              year,
            );
            if (session != null) {
              sessions.add(session);
            }
          } catch (e) {
            print('Error parsing row: $e');
          }
        }
      }
    }

    return sessions;
  }

  /// Create session from HTML table row
  Session? _createSessionFromHtmlRow(
    int index,
    String dateStr,
    List cells,
    int year,
  ) {
    try {
      final startTimeStr = cells[0].text.trim();
      final endTimeStr = cells[1].text.trim();
      final location = cells[2].text.trim();
      final title = cells[3].text.trim();
      final speaker = cells[4].text.trim();
      final description = cells[5].text.trim();
      final type = cells[6].text.trim();

      if (dateStr.isEmpty || startTimeStr.isEmpty || title.isEmpty) {
        return null;
      }

      // Parse date from string like "Monday, August 31, 2026"
      final date = _parseDateString(dateStr, year);
      if (date == null) return null;

      // Parse times
      final startParts = startTimeStr.split(':');
      if (startParts.length != 2) return null;

      final endParts = endTimeStr.split(':');
      if (endParts.length != 2) return null;

      final startTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );

      final endTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      // Extract audience from description
      String audience = 'All';
      String cleanDescription = description;

      final audienceMatch = RegExp(r'\(([^)]+)\)\s*$').firstMatch(description);
      if (audienceMatch != null) {
        final extracted = audienceMatch.group(1)?.trim() ?? '';
        audience = _mapAudience(extracted);
        cleanDescription = description.replaceAll(RegExp(r'\s*\([^)]+\)\s*$'), '').trim();
      }

      return Session(
        id: '$year-$index',
        title: title,
        description: cleanDescription,
        startTime: startTime,
        endTime: endTime,
        type: type,
        audience: audience,
        speaker: speaker,
        location: location,
        tags: const [],
      );
    } catch (e) {
      print('Error creating session: $e');
      return null;
    }
  }

  /// Parse date string like "Monday, August 31, 2026"
  DateTime? _parseDateString(String dateStr, int year) {
    try {
      // Extract month and day
      final parts = dateStr.split(',');
      if (parts.length < 2) return null;

      final monthDay = parts[1].trim().split(' ');
      if (monthDay.length < 2) return null;

      final monthStr = monthDay[0];
      final day = int.tryParse(monthDay[1]);
      if (day == null) return null;

      final monthMap = {
        'January': 1, 'February': 2, 'March': 3, 'April': 4,
        'May': 5, 'June': 6, 'July': 7, 'August': 8,
        'September': 9, 'October': 10, 'November': 11, 'December': 12,
      };

      final month = monthMap[monthStr];
      if (month == null) return null;

      return DateTime(year, month, day);
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  /// Map audience text to standard categories
  String _mapAudience(String audience) {
    if (audience.contains('New') || audience.contains('Beginner')) {
      return 'Beginner';
    } else if (audience.contains('Intermediate')) {
      return 'Intermediate';
    } else if (audience.contains('Advanced') || audience.contains('Developer')) {
      return 'Advanced';
    } else if (audience.contains('Technical')) {
      return 'Technical';
    } else if (audience.contains('Administrative') || audience.contains('Administrators')) {
      return 'Administrative';
    } else if (audience.contains('All')) {
      return 'All';
    }
    return audience; // Return as-is if no match
  }
}
