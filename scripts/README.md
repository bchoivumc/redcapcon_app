# Schedule Scraper & Auto-Update System

## Overview

This system allows the app to automatically fetch updated 2026 REDCapCon schedule data when the REDCap survey content changes.

## How It Works

1. **Scraper** (`scrape_to_json.js`) - Uses Puppeteer to scrape the REDCap survey and output JSON
2. **Hosted JSON** - The JSON is hosted on a publicly accessible URL
3. **App Fetches** - The Flutter app fetches from the JSON URL instead of using bundled data
4. **Auto-Updates** - When you update the JSON on the server, the app gets the new data automatically

## Setup Instructions

### Step 1: Generate the JSON

Run the scraper to create the latest schedule JSON:

```bash
cd scripts
node scrape_to_json.js > schedule_2026_api.json
```

This will:
- Scrape https://redcap.vumc.org/surveys/?__report=Y7EMJR9L797FTX83
- Parse all 102 sessions
- Output JSON in the format the app expects

### Step 2: Host the JSON

Upload `schedule_2026_api.json` to a publicly accessible location. Options:

#### Option A: GitHub Pages (Free & Easy)
```bash
# Create a gh-pages branch
git checkout -b gh-pages
cp scripts/schedule_2026_api.json schedule_2026_api.json
git add schedule_2026_api.json
git commit -m "Add schedule API"
git push origin gh-pages
```
URL will be: `https://YOUR_USERNAME.github.io/redcapcon_beta/schedule_2026_api.json`

#### Option B: Your Own Server
Upload to your web server:
```bash
scp scripts/schedule_2026_api.json user@yourserver.com:/var/www/html/
```
URL will be: `https://yourserver.com/schedule_2026_api.json`

#### Option C: Firebase Hosting
```bash
firebase deploy --only hosting
```

#### Option D: AWS S3
```bash
aws s3 cp scripts/schedule_2026_api.json s3://your-bucket/schedule_2026_api.json --acl public-read
```

### Step 3: Update the App

Edit `lib/services/json_api_service.dart` and replace the URL:

```dart
static const String apiUrl = 'https://YOUR_ACTUAL_URL/schedule_2026_api.json';
```

### Step 4: Bump Cache Version

Edit `lib/services/schedule_service.dart` and increment the cache version:

```dart
static const int _currentCacheVersion = 6; // Increment this
```

### Step 5: Rebuild the App

```bash
flutter run
```

## Updating the Schedule

When the REDCap survey content changes:

1. **Re-run the scraper:**
   ```bash
   cd scripts
   node scrape_to_json.js > schedule_2026_api.json
   ```

2. **Upload the new JSON** to your hosting location (same URL as before)

3. **Users get updates automatically:**
   - On next app launch
   - When they pull-to-refresh
   - After 24-hour cache expiration

**No app rebuild needed!** The app will fetch the updated JSON automatically.

## Automation (Optional)

Set up a cron job or GitHub Action to run the scraper daily:

### GitHub Actions Example

Create `.github/workflows/scrape-schedule.yml`:

```yaml
name: Scrape Schedule
on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight
  workflow_dispatch:  # Manual trigger

jobs:
  scrape:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: cd scripts && npm install
      - run: cd scripts && node scrape_to_json.js > schedule_2026_api.json
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./scripts
          keep_files: false
```

## Testing

Test the JSON URL manually:
```bash
curl https://YOUR_URL/schedule_2026_api.json | jq '.sessionCount'
```

Should return: `102`

## Troubleshooting

**App shows old data:**
- Increment cache version in `schedule_service.dart`
- Force refresh in the app (pull-to-refresh)

**JSON fetch fails:**
- Check URL is publicly accessible
- Verify CORS headers if hosting on custom server
- Check browser network tab for errors

**Scraper fails:**
- Check REDCap URL is still valid
- Ensure Puppeteer dependencies are installed
- Try running with `--headless=false` for debugging
