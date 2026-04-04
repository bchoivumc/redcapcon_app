#!/usr/bin/env python3
"""
Web scraper for REDCap Conference schedule using Selenium
Requires: pip install selenium beautifulsoup4

This script uses a headless browser to load the dynamic content
"""

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup
import json
import time

def scrape_redcap_schedule():
    url = 'https://redcap.vumc.org/surveys/?__report=R7MDEEJTA89C34MH'

    # Setup headless Chrome
    chrome_options = Options()
    chrome_options.add_argument('--headless')
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')

    driver = webdriver.Chrome(options=chrome_options)

    try:
        print(f'Loading: {url}')
        driver.get(url)

        # Wait for the report to load (wait for the table or data container)
        print('Waiting for dynamic content to load...')
        wait = WebDriverWait(driver, 15)

        # Wait for report_parent_div to have content
        wait.until(EC.presence_of_element_located((By.ID, 'report_parent_div')))

        # Additional wait for DataTables to render
        time.sleep(3)

        # Get the page source after JavaScript execution
        html = driver.page_source

        # Save the rendered HTML
        with open('scripts/schedule_rendered.html', 'w', encoding='utf-8') as f:
            f.write(html)
        print('Saved rendered HTML')

        # Parse with BeautifulSoup
        soup = BeautifulSoup(html, 'html.parser')

        # Find the table
        tables = soup.find_all('table')
        print(f'Found {len(tables)} tables')

        sessions = []

        for table in tables:
            # Get headers
            headers = []
            header_row = table.find('thead')
            if header_row:
                headers = [th.get_text(strip=True) for th in header_row.find_all('th')]
                print(f'Table headers: {headers}')

            # Get data rows
            tbody = table.find('tbody')
            if tbody:
                rows = tbody.find_all('tr')
                print(f'Found {len(rows)} data rows')

                for row in rows:
                    cells = [td.get_text(strip=True) for td in row.find_all('td')]

                    if not cells:
                        continue

                    # Map cells to session data
                    session = {}
                    for i, header in enumerate(headers):
                        if i < len(cells):
                            session[header] = cells[i]

                    # Also store raw cells for inspection
                    session['_raw_cells'] = cells
                    sessions.append(session)

        # Save as JSON
        with open('scripts/schedule_parsed.json', 'w', encoding='utf-8') as f:
            json.dump(sessions, f, indent=2, ensure_ascii=False)

        print(f'\nParsed {len(sessions)} sessions')
        print('\nFirst 3 sessions:')
        for session in sessions[:3]:
            print(json.dumps(session, indent=2))

        return sessions

    finally:
        driver.quit()

if __name__ == '__main__':
    scrape_redcap_schedule()
