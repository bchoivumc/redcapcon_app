# REDCap Con - Technical Documentation

## Overview

REDCap Con is a Flutter-based mobile application for iOS and Android that provides access to REDCap Conference schedules from 2022-2026. The app features schedule browsing, search, personalized bookmarks, timeline views, and multiple theme options.

## Core Features

### 1. Multi-Year Schedule Access
- **Current Conference (2026)**: Oklahoma City, OK - August 31 - September 3
- **Historical Conferences**:
  - 2025: Stevens Point, WI
  - 2024: St. Petersburg, FL
  - 2023: Seattle, WA
  - 2022: Boston, MA
- Year selector with visual indicators (gold star for current year)
- Historical banner when viewing past conferences

### 2. Session Management
- **Browse**: View all sessions organized by day and time
- **Search**: Full-text search across all years with year filters
- **Bookmark**: Save favorite sessions (current year only)
- **Timeline View**: Chronological view of sessions with real-time indicators

### 3. User Interface
- **Splash Screen**: Animated "REDCap Con" logo with hat animation
- **Theme Support**: 5 color themes
  - REDCap Classic (default)
  - Dark Professional
  - Modern Blue
  - Warm Earth
  - Vibrant Creative
- **Material Design 3**: Modern UI with adaptive components
- **Responsive Layout**: Optimized for various screen sizes

### 4. Offline Support
- Local caching of schedules for offline access
- Automatic cache versioning and invalidation
- Bundled fallback data for all years

## Technical Architecture

### Data Flow

```
User Opens App
    ↓
Splash Screen (3s animation)
    ↓
Home Screen → Agenda Screen (default year: 2026)
    ↓
ScheduleService.fetchSchedule()
    ↓
1. Check cache version (clear if outdated)
2. Check local cache (if not force refresh)
3. Fetch from live API (2026 only)
4. Fallback to cached data
5. Fallback to bundled mock data
    ↓
Display Sessions
```

### Schedule Scraper Service

**File**: `lib/services/redcap_scraper_service.dart`

#### URL Configuration
```dart
static const Map<int, String> scheduleUrls = {
  2026: 'https://vakore.com/redcaps/redcapcon/redcapcon_2026_mockup.html',
  2025: 'https://redcap.vumc.org/surveys/?__report=R7MDEEJTA89C34MH',
  2024: 'https://redcap.vumc.org/surveys/?__report=LXMLYK3R3JHDJCP7',
};
```

#### HTML Parsing Strategy
1. **Fetch HTML**: HTTP GET request with 15-second timeout
2. **Parse Document**: Using `html` package (html_parser.parse)
3. **Extract Tables**: Query all `<table>` elements
4. **Extract Dates**: Find `.session-date` div siblings
5. **Extract Sessions**: Parse `<tbody> <tr>` rows
6. **Map to Model**: Convert to Session objects

#### Session Data Structure
Each session contains:
- **id**: Unique identifier
- **title**: Session name
- **description**: Full description and audience
- **startTime**: DateTime (UTC)
- **endTime**: DateTime (UTC)
- **type**: Session type (Workshop, Presentation, etc.)
- **audience**: Target audience level
- **speaker**: Presenter name(s)
- **location**: Room/venue
- **tags**: Searchable keywords

### Cache Mechanism

**File**: `lib/services/schedule_service.dart`

#### Cache Keys
- `cached_schedule_2022` - Boston schedule
- `cached_schedule_2023` - Seattle schedule
- `cached_schedule_2024` - St. Petersburg schedule
- `cached_schedule_2025` - Stevens Point schedule
- `cached_schedule_2026` - Oklahoma City schedule
- `cache_version` - Version number for invalidation
- `cache_timestamp` - Last cache update time
- `saved_sessions` - User bookmarks
- `last_update` - Last successful update timestamp

#### Cache Versioning
```dart
static const int _currentCacheVersion = 3;

Future<void> _checkCacheVersion() async {
  final prefs = await SharedPreferences.getInstance();
  final storedVersion = prefs.getInt(_cacheVersionKey) ?? 0;

  if (storedVersion != _currentCacheVersion) {
    // Clear all cached schedules
    for (var year in [2022, 2023, 2024, 2025, 2026]) {
      await prefs.remove(_getCachedScheduleKey(year));
    }
    await prefs.setInt(_cacheVersionKey, _currentCacheVersion);
  }
}
```

**Purpose**: When the cache version is incremented, all cached schedules are cleared on next app launch. This ensures users get fresh data after app updates or data structure changes.

#### Fetch Strategy (Priority Order)

1. **Cache Version Check**: Clear outdated cache if version mismatch
2. **Local Cache**: Return cached data if available (unless force refresh)
3. **Live API** (2026 only): Fetch from remote URL
4. **Cached Fallback**: Use cached data if live fetch fails
5. **Bundled Mock Data**: Use embedded data as final fallback

#### Storage Format
Sessions are serialized to JSON and stored in SharedPreferences:
```dart
final jsonList = sessions.map((s) => s.toJson()).toList();
await prefs.setString(_getCachedScheduleKey(year), jsonEncode(jsonList));
```

### Automatic Updates

**File**: `lib/screens/home_screen.dart`

#### App Lifecycle Monitoring
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _checkForUpdatesOnResume();
  }
}
```

When app resumes from background:
1. Check if remote schedule has updates
2. If updates found, automatically refresh
3. Show confirmation snackbar to user

### Search Implementation

**File**: `lib/screens/search_screen.dart`

#### Features
- **Multi-year search**: Search across all conference years
- **Year filters**: Toggle individual years on/off
- **Full-text search**: Searches title, speaker, description, location, type
- **Real-time results**: Updates as user types
- **Bookmark integration**: Shows bookmark status for current year sessions

#### Search Algorithm
```dart
sessions.where((session) {
  final searchLower = _searchQuery.toLowerCase();
  return session.title.toLowerCase().contains(searchLower) ||
         session.speaker.toLowerCase().contains(searchLower) ||
         session.description.toLowerCase().contains(searchLower) ||
         session.location.toLowerCase().contains(searchLower) ||
         session.type.toLowerCase().contains(searchLower);
}).toList();
```

### Bookmark System

**File**: `lib/services/schedule_service.dart`

#### Storage
Bookmarks are stored as comma-separated session IDs:
```dart
await prefs.setString(_savedSessionsKey, _savedSessions.join(','));
```

#### Restrictions
- Only available for current year (2026)
- Persists across app restarts
- Independent of schedule cache

## Platform-Specific Configuration

### Android

**File**: `android/app/build.gradle.kts`

#### Key Configuration
```kotlin
android {
    namespace = "com.redcap.conference"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.redcap.conference"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            storeFile = file("../../upload-keystore.jks")
            storePassword = keyProperties["storePassword"] as String
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
        }
    }
}
```

#### Permissions
**File**: `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.INTERNET" />
```
Required for fetching remote schedules.

### iOS

**File**: `ios/Runner/Info.plist`

No additional permissions required for basic functionality. HTTP requests work by default.

## Dependencies

### Core Packages
- **flutter**: SDK for cross-platform development
- **shared_preferences**: Local key-value storage for cache and bookmarks
- **http**: HTTP client for fetching remote schedules
- **html**: HTML parsing for schedule extraction
- **intl**: Date/time formatting and internationalization
- **provider**: State management for themes

### Dev Dependencies
- **flutter_test**: Testing framework
- **flutter_lints**: Code quality and style enforcement
- **flutter_launcher_icons**: App icon generation

## Build & Release

### Development Build
```bash
flutter run
```

### Production Builds

#### Android
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

#### iOS
```bash
flutter build ios --release
```

### Version Management
Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1
```
Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

## Data Sources

### 2026 Schedule
- **Source**: https://vakore.com/redcaps/redcapcon/redcapcon_2026_mockup.html
- **Format**: HTML table
- **Update Method**: Live fetch with caching

### 2025 Schedule
- **Source**: https://redcap.vumc.org/surveys/?__report=R7MDEEJTA89C34MH
- **Format**: HTML table
- **Update Method**: Bundled mock data (conference completed)

### 2024 Schedule
- **Source**: https://redcap.vumc.org/surveys/?__report=LXMLYK3R3JHDJCP7
- **Format**: HTML table
- **Update Method**: Bundled mock data (conference completed)

### 2023 & 2022 Schedules
- **Source**: Manually curated data
- **Format**: Dart code
- **Update Method**: Bundled mock data (conference completed)

## Performance Considerations

### Caching Strategy
- **Cache Duration**: Indefinite (version-based invalidation)
- **Cache Size**: ~50-100 sessions per year × 5 years ≈ 250-500KB
- **Cache Location**: SharedPreferences (platform-specific)

### Network Optimization
- **Timeout**: 15 seconds for HTTP requests
- **Retry**: No automatic retry (falls back to cache)
- **Compression**: Relies on server gzip (if available)

### Memory Management
- Sessions loaded per year (not all at once)
- Search loads all years but filters efficiently
- Image assets optimized for size

## Future Enhancements

### Potential Features
- Push notifications for session reminders
- Calendar export (iCal/Google Calendar)
- Session ratings and feedback
- Speaker profiles
- Venue maps
- Social features (attendee networking)

### Technical Improvements
- GraphQL API for more efficient data fetching
- Differential updates (only fetch changes)
- Background sync
- Analytics integration
- Crash reporting
- A/B testing framework

## Troubleshooting

### Android Cache Issues
If Android shows stale data:
1. Increment `_currentCacheVersion` in `schedule_service.dart`
2. Rebuild app
3. Cache will auto-clear on next launch

### Network Fetch Failures
Check:
1. INTERNET permission in AndroidManifest.xml
2. URL accessibility from device/emulator
3. Timeout duration (15s may be too short on slow networks)
4. Console logs for error messages

### Build Errors
- **Android signing**: Verify `key.properties` exists and is correct
- **Dependencies**: Run `flutter pub get`
- **Cache**: Run `flutter clean` then rebuild

## Contact & Support

For issues related to:
- **App functionality**: Check GitHub issues
- **Schedule data**: Contact conference organizers
- **REDCap platform**: Visit redcap.org

---

**Version**: 1.0.0
**Last Updated**: March 2026
**Maintained by**: REDCap Con Development Team
