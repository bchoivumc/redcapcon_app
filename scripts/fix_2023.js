import fs from 'fs/promises';

async function convertToDart() {
  const json = await fs.readFile(
    '/Users/user/Documents/projects/redcapcon_beta/scripts/schedule_2023_parsed.json',
    'utf-8'
  );
  const sessions = JSON.parse(json);

  console.log('Converting ' + sessions.length + ' sessions to Dart...');

  const dartSessions = sessions.map((session, index) => {
    const dateStr = session.date;
    const startTime = session.time;
    const endTime = session.title;
    
    const date = new Date(dateStr);
    
    const startParts = startTime.split(':').map(Number);
    const endParts = endTime.split(':').map(Number);
    
    const startDateTime = new Date(date);
    startDateTime.setHours(startParts[0], startParts[1] || 0, 0, 0);
    
    const endDateTime = new Date(date);
    endDateTime.setHours(endParts[0], endParts[1] || 0, 0, 0);
    
    const description = session.audience || '';
    let audience = 'All';
    let cleanDescription = description;
    
    const audienceMatch = description.match(/\(([^)]+)\)\s*$/);
    if (audienceMatch) {
      const extracted = audienceMatch[1].trim();
      if (extracted.includes('New') || extracted.includes('Beginner')) {
        audience = 'Beginner';
      } else if (extracted.includes('Intermediate')) {
        audience = 'Intermediate';
      } else if (extracted.includes('Advanced') || extracted.includes('Developer') || extracted.includes('Technical')) {
        audience = 'Technical';
      } else if (extracted.includes('All')) {
        audience = 'All Attendees';
      } else {
        audience = extracted;
      }
      cleanDescription = description.replace(/\s*\([^)]+\)\s*$/, '').trim();
    }
    
    return {
      id: '2023-' + (index + 1).toString(),
      title: session.type || '',
      description: cleanDescription,
      startTime: startDateTime.toISOString(),
      endTime: endDateTime.toISOString(),
      type: session.location || 'Session',
      audience: audience,
      speaker: session.speaker || '',
      location: session.description || '',
      tags: [],
    };
  });

  let dartCode = 'import \'../models/session.dart\';\n\n';
  dartCode += 'class MockData2023 {\n';
  dartCode += '  static List<Session> getSessions() {\n';
  dartCode += '    return [\n';

  dartSessions.forEach((session, index) => {
    dartCode += '      Session(\n';
    dartCode += '        id: \'' + session.id + '\',\n';
    dartCode += '        title: ' + escapeDartString(session.title) + ',\n';
    dartCode += '        description: ' + escapeDartString(session.description) + ',\n';
    dartCode += '        startTime: DateTime.parse(\'' + session.startTime + '\'),\n';
    dartCode += '        endTime: DateTime.parse(\'' + session.endTime + '\'),\n';
    dartCode += '        type: ' + escapeDartString(session.type) + ',\n';
    dartCode += '        audience: ' + escapeDartString(session.audience) + ',\n';
    dartCode += '        speaker: ' + escapeDartString(session.speaker) + ',\n';
    dartCode += '        location: ' + escapeDartString(session.location) + ',\n';
    dartCode += '        tags: const [],\n';
    dartCode += '      )' + (index < dartSessions.length - 1 ? ',' : '') + '\n';
  });

  dartCode += '    ];\n';
  dartCode += '  }\n';
  dartCode += '}\n';

  await fs.writeFile(
    '/Users/user/Documents/projects/redcapcon_beta/lib/data/mock_data_2023.dart',
    dartCode
  );

  console.log('Successfully generated mock_data_2023.dart');
  console.log('   ' + dartSessions.length + ' sessions');
}

function escapeDartString(str) {
  if (!str) return "''";

  let cleaned = str
    .replace(/\r\n/g, ' ')
    .replace(/\n/g, ' ')
    .replace(/\r/g, ' ')
    .replace(/\t/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  const escaped = cleaned
    .replace(/\\/g, '\\\\')
    .replace(/'/g, "\\'")
    .replace(/\$/g, '\\$');

  return "'" + escaped + "'";
}

convertToDart()
  .then(() => {
    console.log('Done!');
    process.exit(0);
  })
  .catch(error => {
    console.error('Failed:', error);
    process.exit(1);
  });
