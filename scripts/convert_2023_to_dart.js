/**
 * Convert 2024 scraped JSON data to Dart code
 */

import fs from 'fs/promises';

async function convertToDart() {
  // Read the parsed JSON
  const json = await fs.readFile(
    '/Users/user/Documents/projects/redcapcon_beta/scripts/schedule_2023_parsed.json',
    'utf-8'
  );
  const sessions = JSON.parse(json);

  console.log(`Converting ${sessions.length} sessions to Dart...`);

  // Parse and transform sessions
  const dartSessions = sessions.map((session, index) => {
    // Parse the date
    const dateStr = session['Session Date'];
    const startTime = session['Start time'];
    const endTime = session['End time'];

    // Parse date like "Sunday, September 8, 2024"
    const date = new Date(dateStr);

    // Parse time like "14:00"
    const [startHour, startMin] = startTime.split(':').map(Number);
    const [endHour, endMin] = endTime.split(':').map(Number);

    const startDateTime = new Date(date);
    startDateTime.setHours(startHour, startMin, 0, 0);

    const endDateTime = new Date(date);
    endDateTime.setHours(endHour, endMin, 0, 0);

    // Extract audience from description
    const description = session['Session Description w/ (Audience):'] || '';
    let audience = 'All';
    let cleanDescription = description;

    // Try to extract audience from parentheses at end
    const audienceMatch = description.match(/\(([^)]+)\)\s*$/);
    if (audienceMatch) {
      const extracted = audienceMatch[1].trim();
      // Map various audience types
      if (extracted.includes('New') || extracted.includes('Beginner')) {
        audience = 'Beginner';
      } else if (extracted.includes('Intermediate')) {
        audience = 'Intermediate';
      } else if (extracted.includes('Advanced') || extracted.includes('Developer')) {
        audience = 'Advanced';
      } else if (extracted.includes('All')) {
        audience = 'All';
      } else {
        audience = extracted;
      }
      // Remove audience from description
      cleanDescription = description.replace(/\s*\([^)]+\)\s*$/, '').trim();
    }

    return {
      id: (index + 1).toString(),
      title: session['Session Title:'] || '',
      description: cleanDescription,
      startTime: startDateTime.toISOString(),
      endTime: endDateTime.toISOString(),
      type: session['Session Type:'] || 'Session',
      audience: audience,
      speaker: session['Presenter Information:'] || '',
      location: session['Session Location:'] || '',
      tags: [],
    };
  });

  // Generate Dart code
  let dartCode = `import '../models/session.dart';

/// REDCap Conference 2024 schedule data
/// Last updated: ${new Date().toISOString()}
/// Source: https://redcap.vumc.org/surveys/?__report=LXMLYK3R3JHDJCP7

class MockData2023 {
  static List<Session> getSessions() {
    return [
`;

  dartSessions.forEach((session, index) => {
    dartCode += `      Session(
        id: '${session.id}',
        title: ${_escapeDartString(session.title)},
        description: ${_escapeDartString(session.description)},
        startTime: DateTime.parse('${session.startTime}'),
        endTime: DateTime.parse('${session.endTime}'),
        type: ${_escapeDartString(session.type)},
        audience: ${_escapeDartString(session.audience)},
        speaker: ${_escapeDartString(session.speaker)},
        location: ${_escapeDartString(session.location)},
        tags: const [],
      )${index < dartSessions.length - 1 ? ',' : ''}
`;
  });

  dartCode += `    ];
  }

  static DateTime getLastUpdateTime() {
    return DateTime.parse('${new Date().toISOString()}');
  }
}
`;

  // Save the Dart file
  await fs.writeFile(
    '/Users/user/Documents/projects/redcapcon_beta/lib/data/mock_data_2023.dart',
    dartCode
  );

  console.log('✅ Successfully generated mock_data_2023.dart');
  console.log(`   ${dartSessions.length} sessions`);

  // Print some stats
  const dates = new Set(dartSessions.map(s => s.startTime.split('T')[0]));
  const types = new Set(dartSessions.map(s => s.type));
  const audiences = new Set(dartSessions.map(s => s.audience));

  console.log(`\nStats:`);
  console.log(`  Dates: ${dates.size} days`);
  console.log(`  Types: ${Array.from(types).join(', ')}`);
  console.log(`  Audiences: ${Array.from(audiences).join(', ')}`);
}

function _escapeDartString(str) {
  if (!str) return "''";

  // Remove or replace problematic characters
  let cleaned = str
    .replace(/\r\n/g, ' ')  // Replace Windows line breaks
    .replace(/\n/g, ' ')     // Replace Unix line breaks
    .replace(/\r/g, ' ')     // Replace Mac line breaks
    .replace(/\t/g, ' ')     // Replace tabs
    .replace(/\s+/g, ' ')    // Collapse multiple spaces
    .trim();

  // Escape single quotes, backslashes, and dollar signs
  const escaped = cleaned
    .replace(/\\/g, '\\\\')
    .replace(/'/g, "\\'")
    .replace(/\$/g, '\\$');

  return `'${escaped}'`;
}

convertToDart()
  .then(() => {
    console.log('\nDone!');
    process.exit(0);
  })
  .catch(error => {
    console.error('Failed:', error);
    process.exit(1);
  });
