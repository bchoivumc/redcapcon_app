/**
 * Scrape REDCap Conference 2026 schedule and output as JSON API
 * This can be run on a schedule to keep the schedule updated
 *
 * Usage:
 *   node scrape_to_json.js > schedule_2026.json
 */

import puppeteer from 'puppeteer';

async function scrapeSchedule() {
  const url = 'https://redcap.vumc.org/surveys/?__report=Y7EMJR9L797FTX83';

  console.error('Launching browser...');
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  try {
    const page = await browser.newPage();

    console.error(`Loading: ${url}`);
    await page.goto(url, {
      waitUntil: 'networkidle2',
      timeout: 30000
    });

    // Wait for the report to load
    console.error('Waiting for content to load...');
    await page.waitForSelector('#report_parent_div', { timeout: 15000 });

    // Wait for DataTables to render
    await new Promise(resolve => setTimeout(resolve, 3000));

    // Extract table data
    const sessions = await page.evaluate(() => {
      const tables = document.querySelectorAll('table');
      const allSessions = [];

      tables.forEach((table) => {
        const headers = [];
        const headerRow = table.querySelector('thead tr');
        if (headerRow) {
          headerRow.querySelectorAll('th').forEach(th => {
            headers.push(th.textContent.trim());
          });
        }

        const tbody = table.querySelector('tbody');
        if (tbody) {
          const rows = tbody.querySelectorAll('tr');

          rows.forEach(row => {
            const cells = Array.from(row.querySelectorAll('td')).map(td =>
              td.textContent.trim()
            );

            if (cells.length === 0) return;

            const session = {};
            headers.forEach((header, i) => {
              if (i < cells.length) {
                session[header] = cells[i];
              }
            });

            allSessions.push(session);
          });
        }
      });

      return allSessions;
    });

    console.error(`Scraped ${sessions.length} sessions`);

    // Transform to app format
    const appSessions = sessions.map((session, index) => {
      const dateStr = session['Session Date'];
      const startTime = session['Start time'];
      const endTime = session['End time'];
      const location = session['Session Location:'] || '';
      const title = session['Session Title:'] || '';
      const speaker = session['Presenter Information:'] || '';
      const descWithAudience = session['Session Description w/ (Audience):'] || '';
      const type = session['Session Type:'] || '';

      // Parse date
      const date = new Date(dateStr);
      const [startHour, startMin] = startTime.split(':').map(Number);
      const [endHour, endMin] = endTime.split(':').map(Number);

      const startDateTime = new Date(
        date.getFullYear(),
        date.getMonth(),
        date.getDate(),
        startHour,
        startMin
      );

      const endDateTime = new Date(
        date.getFullYear(),
        date.getMonth(),
        date.getDate(),
        endHour,
        endMin
      );

      // Extract audience
      let audience = 'All';
      let description = descWithAudience;
      const audienceMatch = descWithAudience.match(/\(([^)]+)\)\s*$/);
      if (audienceMatch) {
        const extracted = audienceMatch[1].trim();
        // Map to standard categories
        if (extracted.includes('New') || extracted.includes('Beginner')) {
          audience = 'Beginner';
        } else if (extracted.includes('Intermediate')) {
          audience = 'Intermediate';
        } else if (extracted.includes('Advanced') || extracted.includes('Developer')) {
          audience = 'Advanced';
        } else if (extracted.includes('Technical')) {
          audience = 'Technical';
        } else if (extracted.includes('Administrative') || extracted.includes('Administrators')) {
          audience = 'Administrative';
        } else if (extracted.includes('All')) {
          audience = 'All';
        } else {
          audience = extracted;
        }
        description = descWithAudience.replace(/\s*\([^)]+\)\s*$/, '').trim();
      }

      return {
        id: `2026-${index + 1}`,
        title,
        description,
        startTime: startDateTime.toISOString(),
        endTime: endDateTime.toISOString(),
        type,
        audience,
        speaker,
        location,
        tags: []
      };
    });

    return {
      year: 2026,
      lastUpdated: new Date().toISOString(),
      source: url,
      sessionCount: appSessions.length,
      sessions: appSessions
    };

  } catch (error) {
    console.error('Error:', error);
    throw error;
  } finally {
    await browser.close();
  }
}

// Run and output JSON
scrapeSchedule()
  .then(data => {
    // Output to stdout (so it can be piped to a file)
    console.log(JSON.stringify(data, null, 2));
  })
  .catch(error => {
    console.error('Failed:', error);
    process.exit(1);
  });
