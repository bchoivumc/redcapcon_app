/**
 * Web scraper for REDCap Conference 2025 schedule
 */

import puppeteer from 'puppeteer';
import fs from 'fs/promises';

async function scrapeSchedule() {
  const url = 'https://redcap.vumc.org/surveys/?__report=R7MDEEJTA89C34MH';

  console.log('Launching browser...');
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  try {
    const page = await browser.newPage();

    console.log(`Loading: ${url}`);
    await page.goto(url, {
      waitUntil: 'networkidle2',
      timeout: 30000
    });

    // Wait for the report to load
    console.log('Waiting for content to load...');
    await page.waitForSelector('#report_parent_div', { timeout: 15000 });

    // Wait a bit more for DataTables to render
    await new Promise(resolve => setTimeout(resolve, 3000));

    // Get the rendered HTML
    const html = await page.content();
    await fs.writeFile('/Users/user/Documents/projects/redcapcon_beta/scripts/schedule_2025_rendered.html', html);
    console.log('Saved rendered HTML');

    // Extract table data
    const sessions = await page.evaluate(() => {
      const tables = document.querySelectorAll('table');
      const allSessions = [];

      tables.forEach((table, tableIndex) => {
        // Get headers
        const headers = [];
        const headerRow = table.querySelector('thead tr');
        if (headerRow) {
          headerRow.querySelectorAll('th').forEach(th => {
            headers.push(th.textContent.trim());
          });
        }

        console.log(`Table ${tableIndex} headers:`, headers);

        // Get data rows
        const tbody = table.querySelector('tbody');
        if (tbody) {
          const rows = tbody.querySelectorAll('tr');

          rows.forEach(row => {
            const cells = Array.from(row.querySelectorAll('td')).map(td =>
              td.textContent.trim()
            );

            if (cells.length === 0) return;

            const session = {};

            // Map cells to headers
            headers.forEach((header, i) => {
              if (i < cells.length) {
                session[header] = cells[i];
              }
            });

            // Also keep raw data
            session._raw = cells;
            session._tableIndex = tableIndex;

            allSessions.push(session);
          });
        }
      });

      return allSessions;
    });

    // Save as JSON
    await fs.writeFile(
      '/Users/user/Documents/projects/redcapcon_beta/scripts/schedule_2025_parsed.json',
      JSON.stringify(sessions, null, 2)
    );

    console.log(`\nParsed ${sessions.length} sessions`);

    if (sessions.length > 0) {
      console.log('\nFirst session:');
      console.log(JSON.stringify(sessions[0], null, 2));

      console.log('\nAll unique field names:');
      const allKeys = new Set();
      sessions.forEach(s => {
        Object.keys(s).forEach(k => {
          if (!k.startsWith('_')) allKeys.add(k);
        });
      });
      console.log(Array.from(allKeys));
    }

    return sessions;

  } catch (error) {
    console.error('Error:', error);
    throw error;
  } finally {
    await browser.close();
  }
}

// Run the scraper
scrapeSchedule()
  .then(() => {
    console.log('\nDone!');
    process.exit(0);
  })
  .catch(error => {
    console.error('Failed:', error);
    process.exit(1);
  });
