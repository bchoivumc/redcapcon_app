import puppeteer from 'puppeteer';
import fs from 'fs/promises';

const url = 'https://redcap.vumc.org/surveys/?__report=RPK8CL8NETYCXEYK';
const outputFile = '/Users/user/Documents/projects/redcapcon_beta/scripts/schedule_2023_parsed.json';

(async () => {
  console.log('Launching browser...');
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();
  
  console.log('Navigating to', url);
  await page.goto(url, { waitUntil: 'networkidle2' });
  
  console.log('Waiting for content to load...');
  await page.waitForSelector('#report_parent_div', { timeout: 10000 });
  
  // Wait additional time for DataTables to render
  await new Promise(resolve => setTimeout(resolve, 3000));
  
  console.log('Extracting data...');
  const sessions = await page.evaluate(() => {
    const rows = document.querySelectorAll('#report_table tbody tr');
    const sessions = [];
    
    rows.forEach(row => {
      const cells = row.querySelectorAll('td');
      if (cells.length >= 7) {
        sessions.push({
          date: cells[0]?.innerText.trim() || '',
          time: cells[1]?.innerText.trim() || '',
          title: cells[2]?.innerText.trim() || '',
          description: cells[3]?.innerText.trim() || '',
          type: cells[4]?.innerText.trim() || '',
          audience: cells[5]?.innerText.trim() || '',
          speaker: cells[6]?.innerText.trim() || '',
          location: cells[7]?.innerText.trim() || ''
        });
      }
    });
    
    return sessions;
  });
  
  console.log(`Found ${sessions.length} sessions`);
  
  await fs.writeFile(outputFile, JSON.stringify(sessions, null, 2));
  console.log(`Saved to ${outputFile}`);
  
  await browser.close();
})();
