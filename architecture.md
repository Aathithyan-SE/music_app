# Modizk Download - App Architecture

## Overview
Modizk Download is a music playback and download app optimized for Asian markets, featuring modern UI design, offline music playback, and local device music access.

## Core Architecture

### State Management
- **Provider Pattern**: Used for global state management
- **AudioService**: Manages music playback, playlist control, and playback state
- **StorageService**: Handles local data persistence, song management, and user preferences

### Color Palette (Asia-Optimized)
- **Primary Background**: #F8F8F8 (Very Light Gray)
- **Secondary Background**: #EEEEEE (Light Gray)
- **Primary Text**: #212121 (Very Dark Gray)
- **Primary Accent**: #FF5722 (Fiery Orange)
- **Secondary Accent**: #00BCD4 (Vivid Blue-Turquoise)
- **Secondary Text**: #757575 (Medium Gray)

## File Structure

```
lib/
├── main.dart                    # App entry point with provider setup
├── theme.dart                   # Material Design theme configuration
├── models/
│   ├── song.dart               # Song data model with sample data
│   └── playlist.dart           # Playlist data model with sample data
├── services/
│   ├── audio_service.dart      # Music playback and controls
│   └── storage_service.dart    # Local data persistence
├── screens/
│   ├── onboarding_screen.dart  # 3-screen intro carousel
│   ├── home_screen.dart        # Main app interface
│   ├── search_results_screen.dart # Search functionality
│   ├── song_player_screen.dart # Full-screen music player
│   ├── local_music_screen.dart # Device music with permissions
│   └── playlist_screen.dart    # Playlist management
└── widgets/
    └── mini_player.dart        # Persistent bottom player
```

## Key Features Implemented

### 1. Onboarding Experience
- 3 vibrant illustration screens
- Skip functionality
- Guest mode support
- Smooth page transitions

### 2. Home Screen
- Search bar with history
- Continue listening widget
- My Playlists section with mood icons
- Device music access with permission handling
- Content cards for different music categories

### 3. Audio Playback
- Background music playback
- Mini player persistent across screens
- Full-screen player with controls
- Progress bar with seek functionality
- Shuffle and repeat modes
- Next/previous song navigation

### 4. Music Management
- Local device music scanning
- Playlist creation and management
- Liked songs functionality
- Downloaded songs tracking
- Search with suggestions

### 5. Local Storage
- SharedPreferences for user settings
- JSON serialization for complex data
- Search history persistence
- Current song state preservation

## Technical Specifications

### Dependencies
- **audioplayers**: ^6.0.0 - Audio playback functionality
- **permission_handler**: ^12.0.0 - Device permissions
- **shared_preferences**: ^2.0.0 - Local data storage
- **provider**: ^6.0.0 - State management
- **path_provider**: ^2.0.0 - File system access
- **google_fonts**: ^6.1.0 - Typography

### Data Models
- **Song**: ID, title, artist, album art, file path, duration, liked/downloaded status
- **Playlist**: ID, name, image, song IDs, creation dates, system/user flag

### Navigation
- Material Page Routes
- Persistent mini player wrapper
- Back navigation handling
- Screen state preservation

## Sample Data
The app includes realistic sample data for development:
- 5 sample songs with different artists and durations
- System playlists (Liked, Downloaded, Recently Played)
- User playlists (Party Mix, Chill Vibes)
- Search history examples

## Permission Handling
- Storage permission for device music access
- User-friendly permission dialogs
- Settings redirect for denied permissions
- Graceful fallback for restricted access

## UI/UX Highlights
- Modern Material Design 3
- Vibrant color scheme optimized for Asian markets
- Responsive layouts for different screen sizes
- Smooth animations and transitions
- Accessibility considerations
- Dark/Light mode support via system settings

## Performance Optimizations
- Lazy loading for large lists
- Image caching and error handling
- Efficient state updates
- Background audio processing
- Minimal memory footprint

## Future Enhancements
- Cloud backup integration
- Voice search functionality
- Advanced equalizer
- Social sharing features
- Offline download management
- Multi-language support

## Development Notes
- Total implementation: 12 files (within complexity guidelines)
- MVP-focused feature set
- Modular component architecture
- Sample data for immediate testing
- Clean separation of concerns
- Comprehensive error handling