import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Script to scrape REDCap Conference schedule from survey report
/// Run with: dart run scripts/scrape_schedule.dart

void main() async {
  const url = 'https://redcap.vumc.org/surveys/?__report=R7MDEEJTA89C34MH';

  print('Fetching conference schedule from: $url');

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print('Successfully fetched HTML (${response.body.length} bytes)');

      // Save raw HTML for inspection
      final htmlFile = File('scripts/schedule_raw.html');
      await htmlFile.writeAsString(response.body);
      print('Saved raw HTML to: ${htmlFile.path}');

      // Parse the HTML
      final sessions = parseScheduleHtml(response.body);

      print('\nParsed ${sessions.length} sessions');

      // Save as JSON
      final jsonFile = File('scripts/schedule_data.json');
      await jsonFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(sessions),
      );
      print('Saved parsed data to: ${jsonFile.path}');

      // Print summary
      print('\n=== Schedule Summary ===');
      for (var session in sessions.take(5)) {
        print('${session['title']} - ${session['date']} ${session['time']}');
      }
      if (sessions.length > 5) {
        print('... and ${sessions.length - 5} more sessions');
      }

    } else {
      print('Failed to fetch URL: ${response.statusCode}');
      print('Response: ${response.body.substring(0, 500)}');
    }
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  }
}

List<Map<String, dynamic>> parseScheduleHtml(String html) {
  final sessions = <Map<String, dynamic>>[];

  // Look for table data - REDCap reports typically use tables
  // We'll need to parse the HTML to extract session information

  // First, let's try to find the report table
  final tableRegex = RegExp(r'<table[^>]*>(.*?)</table>',
    caseSensitive: false,
    dotAll: true
  );

  final tableMatches = tableRegex.allMatches(html);

  print('Found ${tableMatches.length} tables in HTML');

  for (var tableMatch in tableMatches) {
    final tableContent = tableMatch.group(1) ?? '';

    // Extract rows
    final rowRegex = RegExp(r'<tr[^>]*>(.*?)</tr>',
      caseSensitive: false,
      dotAll: true
    );

    final rows = rowRegex.allMatches(tableContent).toList();

    if (rows.isEmpty) continue;

    // Skip header row, process data rows
    for (var i = 1; i < rows.length; i++) {
      final rowContent = rows[i].group(1) ?? '';

      // Extract cells
      final cellRegex = RegExp(r'<t[dh][^>]*>(.*?)</t[dh]>',
        caseSensitive: false,
        dotAll: true
      );

      final cells = cellRegex.allMatches(rowContent)
        .map((m) => _cleanHtml(m.group(1) ?? ''))
        .toList();

      if (cells.isEmpty) continue;

      // Try to map cells to session fields
      // This is a guess - we'll need to inspect the actual data structure
      final session = <String, dynamic>{};

      if (cells.length >= 1) session['raw_data'] = cells;

      // Common REDCap report fields might include:
      // Date, Time, Title, Description, Speaker, Location, Type, Audience

      // Add to sessions if it looks valid
      if (cells.isNotEmpty && cells.any((c) => c.trim().isNotEmpty)) {
        sessions.add(session);
      }
    }
  }

  // If no tables found, try alternative parsing
  if (sessions.isEmpty) {
    print('No data found in tables, trying alternative parsing...');
    sessions.addAll(_parseAlternativeFormat(html));
  }

  return sessions;
}

List<Map<String, dynamic>> _parseAlternativeFormat(String html) {
  final sessions = <Map<String, dynamic>>[];

  // Look for specific patterns in the HTML
  // REDCap might use divs or other structures

  // Try to find any structured data
  final dataRegex = RegExp(r'data-.*?=.*?"([^"]*)"',
    caseSensitive: false
  );

  final matches = dataRegex.allMatches(html);

  if (matches.isNotEmpty) {
    print('Found ${matches.length} data attributes');
    // Store for inspection
    sessions.add({
      'note': 'Found data attributes but need to determine structure',
      'count': matches.length,
    });
  }

  return sessions;
}

String _cleanHtml(String text) {
  // Remove HTML tags
  var cleaned = text.replaceAll(RegExp(r'<[^>]*>'), '');

  // Decode HTML entities
  cleaned = cleaned
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&mdash;', '—')
    .replaceAll('&ndash;', '–');

  // Trim whitespace
  return cleaned.trim();
}
