# REDCap Conference 2025 App

A Flutter mobile app for the REDCap Conference 2025, featuring the conference schedule, personal agenda planning, and filtering capabilities.

## Features

- 📅 **Full Conference Schedule** - Browse all 103+ sessions across 4 days
- 🔖 **Personal Schedule** - Save sessions to create your custom agenda
- 🔍 **Smart Filtering** - Filter by date, session type, and audience level
- 🔄 **Auto-Update Check** - Get notified when the schedule is updated
- 📱 **Mobile-First Design** - Optimized for mobile viewing
- 💾 **Offline Support** - All schedule data cached locally for offline access
- ⚡ **Pull-to-Refresh** - Manual refresh button to fetch latest updates

## Getting Started

### Installation

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Updating Schedule Data

The app automatically checks for schedule updates when:
- The app is opened
- The app is brought back to foreground from background
- The user pulls to refresh on the Agenda screen

### Option 1: Live Updates (Recommended)

Run the API server to enable live schedule fetching:

```bash
cd scripts
npm run server
```

This starts a server at `http://localhost:3000` that:
- Scrapes the REDCap survey on-demand
- Caches results for 1 hour
- Serves fresh data to the Flutter app

The app will automatically use this endpoint when available.

### Option 2: Manual Update

Update the bundled schedule data:

```bash
cd scripts
npm run update
```

This runs the scraper and updates `lib/data/mock_data.dart` with the latest data.

## Data Source

Schedule data is scraped from: https://redcap.vumc.org/surveys/?__report=R7MDEEJTA89C34MH
