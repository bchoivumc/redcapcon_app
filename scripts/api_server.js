/**
 * Simple API server to serve scraped REDCap Conference schedule data
 *
 * This server:
 * 1. Runs the Puppeteer scraper to fetch latest schedule
 * 2. Caches the result for 1 hour
 * 3. Serves the data as JSON via /api/schedule endpoint
 *
 * Install dependencies:
 *   npm install express
 *
 * Run:
 *   node scripts/api_server.js
 *
 * Test:
 *   curl http://localhost:3000/api/schedule
 */

import express from 'express';
import puppeteer from 'puppeteer';

const app = express();
const PORT = process.env.PORT || 3000;

// Cache configuration
let cachedData = null;
let lastFetchTime = null;
const CACHE_DURATION = 60 * 60 * 1000; // 1 hour in milliseconds

/**
 * Scrape the REDCap survey schedule
 */
async function scrapeSchedule() {
  const url = 'https://redcap.vumc.org/surveys/?__report=R7MDEEJTA89C34MH';

  console.log('Launching browser to scrape schedule...');
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
    await page.waitForSelector('#report_parent_div', { timeout: 15000 });
    await new Promise(resolve => setTimeout(resolve, 3000));

    // Extract table data
    const sessions = await page.evaluate(() => {
      const tables = document.querySelectorAll('table');
      const allSessions = [];

      tables.forEach((table, tableIndex) => {
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

    console.log(`Successfully scraped ${sessions.length} sessions`);
    return sessions;

  } finally {
    await browser.close();
  }
}

/**
 * Get schedule data (from cache or by scraping)
 */
async function getScheduleData() {
  const now = Date.now();

  // Return cached data if still valid
  if (cachedData && lastFetchTime && (now - lastFetchTime) < CACHE_DURATION) {
    console.log('Returning cached schedule data');
    return cachedData;
  }

  // Fetch fresh data
  console.log('Cache expired or empty, fetching fresh schedule...');
  try {
    const data = await scrapeSchedule();
    cachedData = data;
    lastFetchTime = now;
    return data;
  } catch (error) {
    console.error('Failed to scrape schedule:', error);

    // If we have cached data, return it even if expired
    if (cachedData) {
      console.log('Using expired cache due to scraping failure');
      return cachedData;
    }

    throw error;
  }
}

// API endpoint to get schedule
app.get('/api/schedule', async (req, res) => {
  try {
    const data = await getScheduleData();
    res.json(data);
  } catch (error) {
    console.error('Error serving schedule:', error);
    res.status(500).json({
      error: 'Failed to fetch schedule',
      message: error.message
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    cached: !!cachedData,
    cacheAge: lastFetchTime ? Date.now() - lastFetchTime : null
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'REDCap Conference Schedule API',
    version: '1.0.0',
    endpoints: {
      '/api/schedule': 'Get conference schedule (JSON)',
      '/health': 'Health check'
    }
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`\n🚀 REDCap Conference Schedule API running on port ${PORT}`);
  console.log(`   GET http://localhost:${PORT}/api/schedule`);
  console.log(`   GET http://localhost:${PORT}/health\n`);
});
