import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/session.dart';

/// Service to fetch schedule from hosted JSON API
class JsonApiService {
  // GitHub Pages hosted JSON - auto-updates when schedule changes
  static const String apiUrl = 'https://bchoivumc.github.io/redcapcon_app/schedule_2026_api.json';

  /// Fetch schedule from JSON API
  Future<List<Session>> fetchSchedule() async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sessionsList = data['sessions'] as List;

        return sessionsList.map((sessionJson) {
          return Session(
            id: sessionJson['id'] as String,
            title: sessionJson['title'] as String,
            description: sessionJson['description'] as String,
            startTime: DateTime.parse(sessionJson['startTime'] as String),
            endTime: DateTime.parse(sessionJson['endTime'] as String),
            type: sessionJson['type'] as String,
            audience: sessionJson['audience'] as String,
            speaker: sessionJson['speaker'] as String,
            location: sessionJson['location'] as String,
            tags: (sessionJson['tags'] as List?)?.cast<String>() ?? const [],
          );
        }).toList();
      } else {
        throw Exception('Failed to load schedule: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching schedule from API: $e');
    }
  }
}
