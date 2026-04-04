# Schedule Update Guide

This app automatically fetches the latest 2026 REDCapCon schedule from GitHub Pages. You have **TWO OPTIONS** to update the schedule.

---

## ✅ Option 1: MANUAL Update (When You Know Survey Changed)

### Steps in VSCode/Terminal:

1. **Open terminal** in this project folder

2. **Run the scraper:**
   ```bash
   cd scripts
   node scrape_to_json.js > ../docs/schedule_2026_api.json
   ```

   You'll see output like:
   ```
   Launching browser...
   Loading: https://redcap.vumc.org/surveys/...
   Scraped 102 sessions
   ```

3. **Commit and push:**
   ```bash
   cd ..
   git add docs/schedule_2026_api.json
   git commit -m "Update 2026 schedule data"
   git push
   ```

4. **Wait ~30 seconds** for GitHub Pages to update

5. **Done!** Users get the update on next app launch or pull-to-refresh

### When to use manual:
- ✅ You know the REDCap survey was just updated
- ✅ You want immediate control over timing
- ✅ You want to verify changes before publishing

---

## 🤖 Option 2: AUTOMATED Update (Daily)

A GitHub Action runs **daily at 2 AM UTC** and:
1. Scrapes the REDCap survey
2. Compares to current schedule
3. Only commits if something changed
4. Auto-deploys to GitHub Pages

### When to use automated:
- ✅ You want hands-off updates
- ✅ Schedule changes frequently
- ✅ You prefer "always current" approach

### Manual trigger (on-demand):
1. Go to: https://github.com/bchoivumc/redcapcon_app/actions
2. Click "Update Schedule" workflow
3. Click "Run workflow" → "Run workflow"
4. Wait ~2 minutes for completion

---

## 🔍 How to Check if Schedule Changed

### In GitHub:
- View latest commit: https://github.com/bchoivumc/redcapcon_app/commits/main
- Check file: https://github.com/bchoivumc/redcapcon_app/blob/main/docs/schedule_2026_api.json
- Look at `lastUpdated` timestamp

### Live API:
- Visit: https://bchoivumc.github.io/redcapcon_app/schedule_2026_api.json
- Check `lastUpdated` field

### In the App:
- Users can pull-to-refresh on Agenda screen
- App checks for updates on every launch
- Cache refreshes after 24 hours

---

## 📊 What Gets Updated

The scraper fetches from:
`https://redcap.vumc.org/surveys/?__report=Y7EMJR9L797FTX83`

And extracts:
- ✅ All 102+ sessions
- ✅ Session titles, descriptions
- ✅ Start/end times
- ✅ Locations
- ✅ Speakers
- ✅ Session types
- ✅ Target audiences

---

## 🛠️ Troubleshooting

### Manual scraper fails:
```bash
# Make sure you're in the scripts folder
cd scripts

# Install dependencies if needed
npm install

# Run again
node scrape_to_json.js > ../docs/schedule_2026_api.json
```

### Automated scraper fails:
1. Check: https://github.com/bchoivumc/redcapcon_app/actions
2. Click the failed workflow
3. Read the error logs
4. Usually means REDCap URL changed or is down

### App not getting updates:
1. Check GitHub Pages is enabled (Settings → Pages)
2. Verify URL is accessible: https://bchoivumc.github.io/redcapcon_app/schedule_2026_api.json
3. In app, try pull-to-refresh
4. Check app logs for fetch errors

---

## 🎯 Best Practice

**Recommended workflow:**
1. Keep automated daily updates **ON** (background maintenance)
2. When you make major schedule changes → run **manual update** (immediate)
3. This gives you both automatic maintenance AND manual control

---

## 📝 Schedule Source URLs

- **2026**: https://redcap.vumc.org/surveys/?__report=Y7EMJR9L797FTX83
- **2025**: https://redcap.vumc.org/surveys/?__report=R7MDEEJTA89C34MH
- **2024**: https://redcap.vumc.org/surveys/?__report=LXMLYK3R3JHDJCP7

To add other years, update `scripts/scrape_to_json.js` with the new URL.
