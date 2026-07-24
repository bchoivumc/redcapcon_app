/**
 * Scrape REDCap Conference 2026 schedule and output as JSON API
 * This can be run on a schedule to keep the schedule updated
 *
 * Usage:
 *   node scrape_to_json.js > schedule_2026.json
 */

import puppeteer from 'puppeteer';

// Extract all session rows from the currently visible table page
function extractRowsFromPage() {
  const tables = document.querySelectorAll('table');
  const rows = [];

  tables.forEach((table) => {
    const headers = [];
    const headerRow = table.querySelector('thead tr');
    if (headerRow) {
      headerRow.querySelectorAll('th').forEach(th => {
        headers.push(th.textContent.trim());
      });
    }
    if (headers.length === 0) return;

    const tbody = table.querySelector('tbody');
    if (!tbody) return;

    tbody.querySelectorAll('tr').forEach(row => {
      const cells = Array.from(row.querySelectorAll('td')).map(td =>
        td.textContent.trim()
      );
      if (cells.length === 0) return;

      const session = {};
      headers.forEach((header, i) => {
        if (i < cells.length) session[header] = cells[i];
      });
      rows.push(session);
    });
  });

  return rows;
}

async function scrapeSchedule() {
  const url = 'https://redcap.vumc.org/surveys/?__report=Y7EMJR9L797FTX83';

  console.error('Launching browser...');
  const browser = await puppeteer.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-blink-features=AutomationControlled',
      '--window-size=1920,1080',
    ]
  });

  try {
    const page = await browser.newPage();
    await page.setUserAgent(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36'
    );
    await page.evaluateOnNewDocument(() => {
      Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    });

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

    // Try to set DataTables to show all rows at once
    const showAllWorked = await page.evaluate(() => {
      try {
        if (typeof jQuery !== 'undefined' && jQuery.fn.dataTable) {
          const api = jQuery('table').DataTable();
          api.page.len(-1).draw(false);
          return true;
        }
      } catch (e) {}
      // Fallback: select the largest available option in the length dropdown
      try {
        const sel = document.querySelector('select[name$="_length"]');
        if (sel) {
          const options = Array.from(sel.options).map(o => parseInt(o.value));
          const max = Math.max(...options.filter(v => v > 0));
          if (max > 0) {
            sel.value = String(max);
            sel.dispatchEvent(new Event('change'));
          }
        }
      } catch (e) {}
      return false;
    });
    console.error(`Show-all attempt: ${showAllWorked ? 'DataTables API' : 'fallback/failed'}`);
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Collect rows — paginate through all DataTables pages
    const allSessions = [];
    let pageNum = 1;

    while (true) {
      const rows = await page.evaluate(extractRowsFromPage);
      console.error(`Page ${pageNum}: ${rows.length} rows`);
      allSessions.push(...rows);

      // Check whether a non-disabled "Next" button exists
      const hasNext = await page.evaluate(() => {
        const next = document.querySelector(
          '.paginate_button.next:not(.disabled), #report_parent_div_next:not(.disabled)'
        );
        return !!next && !next.classList.contains('disabled');
      });

      if (!hasNext) break;

      await page.click(
        '.paginate_button.next:not(.disabled), #report_parent_div_next:not(.disabled)'
      );
      await new Promise(resolve => setTimeout(resolve, 1500));
      pageNum++;

      if (pageNum > 50) {
        console.error('Safety limit reached — stopping pagination');
        break;
      }
    }

    console.error(`Total scraped: ${allSessions.length} sessions across ${pageNum} page(s)`);

    // Transform to app format
    const appSessions = allSessions.map((session, index) => {
      const dateStr = session['Session Date'];
      const startTime = session['Start time'];
      const endTime = session['End time'];
      const location = session['Session Location:'] || '';
      const title = session['Session Title:'] || '';
      const speaker = session['Presenter Information:'] || '';
      const descWithAudience = session['Session Description w/ (Audience):'] || '';
      const type = session['Session Type:'] || '';

      // Parse date — timezone-independent regardless of where this runs.
      // We store times as CDT-as-UTC (CDT hour == UTC hour in the stored ISO string),
      // so a session at "7:30 CDT" is stored as T07:30:00.000Z. The Flutter app reads
      // the UTC hour directly and displays it with a "CDT" label.
      //
      // The survey renders dates as "Tuesday, September 1, 2026" (long locale format).
      // We extract month/day/year via regex to avoid any timezone-dependent Date parsing.
      const MONTHS = ['January','February','March','April','May','June','July','August','September','October','November','December'];
      let y, m, d;
      const isoMatch = dateStr && dateStr.match(/^(\d{4})-(\d{2})-(\d{2})/);
      const longMatch = dateStr && dateStr.match(/(\w+)\s+(\d{1,2}),\s+(\d{4})/);
      if (isoMatch) {
        y = parseInt(isoMatch[1]); m = parseInt(isoMatch[2]) - 1; d = parseInt(isoMatch[3]);
      } else if (longMatch) {
        y = parseInt(longMatch[3]); m = MONTHS.indexOf(longMatch[1]); d = parseInt(longMatch[2]);
      } else {
        console.error(`  WARN: unparseable date "${dateStr}" — skipping session "${title}"`);
        return null;
      }
      // Parse HH:MM time strings — guard against "TBD", empty, or malformed values.
      function parseHHMM(str) {
        const m = (str || '').match(/^(\d{1,2}):(\d{2})/);
        if (!m) { console.error(`  WARN: unparseable time "${str}" — defaulting to 0:00`); return [0, 0]; }
        return [parseInt(m[1], 10), parseInt(m[2], 10)];
      }
      const [startHour, startMin] = parseHHMM(startTime);
      const [endHour, endMin] = parseHHMM(endTime);

      // Build UTC datetimes where hour == CDT hour (CDT-as-UTC convention)
      const startDateTime = new Date(Date.UTC(y, m, d, startHour, startMin));
      const endDateTime = new Date(Date.UTC(y, m, d, endHour, endMin));

      // Extract audience
      let audience = 'All';
      let description = descWithAudience;
      const audienceMatch = descWithAudience.match(/\(([^)]+)\)\s*$/);
      if (audienceMatch) {
        const extracted = audienceMatch[1].trim();
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
    }).filter(Boolean);

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
    console.log(JSON.stringify(data, null, 2));
  })
  .catch(error => {
    console.error('Failed:', error);
    process.exit(1);
  });
