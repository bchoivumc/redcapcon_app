import fs from 'fs/promises';

const inputFile = '/Users/user/Documents/projects/redcapcon_beta/scripts/schedule_2023_parsed.json';
const outputFile = '/Users/user/Documents/projects/redcapcon_beta/lib/data/mock_data_2023.dart';

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
  
  return `'${escaped}'`;
}

function parseDateTime(dateStr, timeStr) {
  const monthMap = {
    'January': '01', 'February': '02', 'March': '03', 'April': '04',
    'May': '05', 'June': '06', 'July': '07', 'August': '08',
    'September': '09', 'October': '10', 'November': '11', 'December': '12'
  };
  
  const dateMatch = dateStr.match(/(\w+)\s+(\d+),\s+(\d{4})/);
  if (!dateMatch) return '2023-09-10 08:00:00';
  
  const month = monthMap[dateMatch[1]];
  const day = dateMatch[2].padStart(2, '0');
  const year = dateMatch[3];
  
  const timeMatch = timeStr.match(/(\d{1,2}):(\d{2})/);
  if (!timeMatch) return `${year}-${month}-${day} 08:00:00`;
  
  let hour = parseInt(timeMatch[1]);
  const minute = timeMatch[2];
  
  const hourStr = hour.toString().padStart(2, '0');
  return `${year}-${month}-${day} ${hourStr}:${minute}:00`;
}

(async () => {
  const rawData = await fs.readFile(inputFile, 'utf8');
  const sessions = JSON.parse(rawData);
  
  let dartCode = `import '../models/session.dart';

class MockData2023 {
  static List<Session> getSessions() {
    return [
`;

  sessions.forEach((session, index) => {
    const startTime = parseDateTime(session.date, session.time);
    const endTime = parseDateTime(session.date, session.title);
    
    const actualTitle = session.type || '';
    const actualLocation = session.description || '';
    const actualType = session.location || '';
    const actualAudience = session.audience ? session.audience.split('\n\n').pop().replace(/[()]/g, '') : '';
    const actualDescription = session.audience || '';
    
    dartCode += `      Session(
        id: '2023-${index + 1}',
        title: ${escapeDartString(actualTitle)},
        description: ${escapeDartString(actualDescription)},
        startTime: DateTime.parse('${startTime}'),
        endTime: DateTime.parse('${endTime}'),
        location: ${escapeDartString(actualLocation)},
        speaker: ${escapeDartString(session.speaker)},
        type: ${escapeDartString(actualType)},
        audience: ${escapeDartString(actualAudience)},
        tags: [],
      ),
`;
  });

  dartCode += `    ];
  }
}
`;

  await fs.writeFile(outputFile, dartCode);
  console.log(`Converted ${sessions.length} sessions to ${outputFile}`);
})();
