# Profile Features Implementation Plan

**Created:** February 10, 2026  
**Status:** In Progress  
**Version:** 1.0

---

## 🎯 Overview

This document outlines the complete implementation plan for Profile Page features including My Songs, Liked Songs, and Playlists functionality.

### Current State

**Existing Components:**
- ✅ Profile screen with 3 tabs (My Songs, Liked, Playlists)
- ✅ Profile header with stats (10 Songs, 1.2K Followers, 567 Following)
- ✅ Sort functionality (Recent, Most Played, A-Z)
- ✅ Responsive grid layout (2-4 columns based on screen size)
- ✅ Empty states for Liked and Playlists tabs
- ✅ Song card component with album art and metadata

**Critical Issues:**
- ⚠️ **Profile uses separate Song model** - `lib/features/profile/models/song_model.dart`
- ⚠️ **Player uses different SongModel** - `lib/features/player/models/song_model.dart`
- ⚠️ **No connection between profile songs and audio player**
- ⚠️ **Playing from profile shows snackbar only, doesn't play audio**
- ⚠️ **Using mock/fake data, not real user songs**
- ⚠️ **Like state not synced across app**

---

## 📐 Architecture Overview

```
Profile Features
├── Data Layer
│   ├── Models (unified with player)
│   ├── Services (API integration)
│   └── Repositories
├── State Management
│   ├── User Songs Provider
│   ├── Liked Songs Provider
│   └── Playlists Provider
└── Presentation Layer
    ├── Screens (Profile, Playlist Detail, Create)
    └── Widgets (Cards, Lists, Dialogs)
```

---

## 🚀 Phase 1: Foundation & Integration (Priority: HIGH)

### Objective
Unify data models and connect profile to real audio player

### 1.1 Model Unification

**Problem:** Profile has its own `Song` class separate from player's `SongModel`

**Solution:**
```dart
// Remove: lib/features/profile/models/song_model.dart
// Use: lib/features/player/models/song_model.dart everywhere

// Add user ownership metadata to existing SongModel:
class SongModel {
  // ... existing fields
  final String? uploaderId;  // User who uploaded
  final DateTime? uploadDate;
  final int totalEarnings;    // Tokens earned from plays
  final bool isOwnedByUser;   // Quick check if current user owns this
}
```

**Files to Update:**
- `lib/features/profile/presentation/screens/profile_screen.dart`
- `lib/features/profile/widgets/song_card.dart`
- Remove `lib/features/profile/models/song_model.dart`
- Update all imports

**Estimated Time:** 1-2 hours

---

### 1.2 Connect Profile to Audio Player

**Current Behavior:**
```dart
void _handleSongPlay(Song song) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Playing: ${song.title}')),
  );
}
```

**New Behavior:**
```dart
void _handleSongPlay(SongModel song) {
  // Actually play the song through audio player
  ref.read(audioPlayerProvider.notifier).playSong(song);
  
  // Show mini player automatically
  // Highlight currently playing song in grid
}
```

**Implementation Steps:**
1. Import `audioPlayerProvider` and `currentSongProvider`
2. Replace snackbar with real play action
3. Add visual indicator for currently playing song
4. Test play/pause from profile grid

**Estimated Time:** 1 hour

---

### 1.3 Sync Like State

**Problem:** Liking a song in player doesn't reflect in profile, and vice versa

**Solution:** Create centralized like provider
```dart
// lib/features/profile/providers/liked_songs_provider.dart
class LikedSongsNotifier extends StateNotifier<Set<String>> {
  LikedSongsNotifier() : super({});

  bool isLiked(String songId) => state.contains(songId);
  
  void toggleLike(String songId) {
    if (state.contains(songId)) {
      state = {...state}..remove(songId);
    } else {
      state = {...state, songId};
    }
  }
  
  Future<void> fetchLikedSongs() async {
    // API call to get user's liked songs
  }
}

final likedSongsProvider = StateNotifierProvider<LikedSongsNotifier, Set<String>>(
  (ref) => LikedSongsNotifier(),
);
```

**Integration Points:**
- Full player like button
- Mini player like button (if exists)
- Profile song cards
- Discovery screen song tiles

**Estimated Time:** 2 hours

---

## 🎵 Phase 2: My Songs Tab (Priority: HIGH)

### Objective
Display and manage user's uploaded songs

### 2.1 User Songs Provider

```dart
// lib/features/profile/providers/user_songs_provider.dart
class UserSongsNotifier extends StateNotifier<AsyncValue<List<SongModel>>> {
  final Ref _ref;
  
  UserSongsNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> fetchUserSongs() async {
    state = const AsyncValue.loading();
    try {
      // For now, use sample songs filtered by user
      final songs = SampleSongs.songs; // Later: API call
      state = AsyncValue.data(songs);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteSong(String songId) async {
    // API call to delete song
    await fetchUserSongs(); // Refresh
  }
}
```

**Features:**
- Loading states (shimmer effect)
- Error handling with retry
- Pull to refresh
- Delete confirmation dialog
- Sort (Recent, Most Played, A-Z)

**Estimated Time:** 3 hours

---

### 2.2 Song Statistics

Add analytics view for each song:
```dart
// Bottom sheet or detail screen
- Total plays: 15.4K
- Total tokens earned: 1,250 tokens
- Likes: 890
- Added to playlists: 45 times
- Play trend chart (last 7 days)
- Top countries/regions
```

**Estimated Time:** 2 hours

---

### 2.3 Song Management Actions

```dart
// Long press or options menu
- Edit song details (title, genre, price)
- Delete song (with confirmation)
- View statistics
- Share song link
- Download (for offline)
- Add to featured (if artist tier allows)
```

**Estimated Time:** 2 hours

---

## ❤️ Phase 3: Liked Tab (Priority: MEDIUM)

### Objective
Display all songs user has liked across the app

### 3.1 Liked Songs List

```dart
// lib/features/profile/presentation/widgets/liked_songs_list.dart
class LikedSongsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedSongIds = ref.watch(likedSongsProvider);
    final allSongs = ref.watch(allSongsProvider); // Need to create this
    
    final likedSongs = allSongs.where((song) => 
      likedSongIds.contains(song.id)
    ).toList();
    
    return SliverGrid(...); // Same layout as My Songs
  }
}
```

**Features:**
- Real-time sync with player likes
- Remove from liked (swipe or long press)
- Play all liked songs (shuffle option)
- Sort by: Date Liked, Most Played, Artist, Genre
- Search within liked songs

**Estimated Time:** 3 hours

---

### 3.2 Bulk Actions

```dart
// Select mode (tap + hold to activate)
- Select multiple songs
- Remove from liked (batch)
- Add to playlist (batch)
- Download (batch)
- Share selected songs
```

**Estimated Time:** 2 hours

---

## 📚 Phase 4: Playlists Tab (Priority: MEDIUM)

### Objective
Full playlist management system

### 4.1 Playlist Model

```dart
// lib/features/profile/models/playlist.dart
class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final List<String> songIds; // References to songs
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final int playCount;
  
  // Computed properties
  int get songCount => songIds.length;
  Duration get totalDuration; // Sum of all song durations
  
  // Generate cover from first 4 songs (mosaic)
  String generateCoverMosaic(List<SongModel> songs);
}
```

**Estimated Time:** 1 hour

---

### 4.2 Playlist Grid Display

```dart
// lib/features/profile/presentation/widgets/playlist_card.dart
class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  
  // Shows:
  // - Cover image (mosaic or custom)
  // - Name (max 2 lines)
  // - Song count + total duration
  // - Play count
  // - Quick play button (plays entire playlist)
  // - Options menu (edit, delete, share)
}
```

**Features:**
- Create new playlist button (FAB)
- Empty state with create CTA
- Grid layout matching song cards
- Smooth animations

**Estimated Time:** 2 hours

---

### 4.3 Create Playlist Dialog

```dart
// Quick creation bottom sheet
showModalBottomSheet(
  context: context,
  builder: (context) => CreatePlaylistSheet(
    fields: [
      'Playlist Name' (required, max 50 chars)
      'Description' (optional, max 200 chars)
      'Public/Private' (toggle)
      'Add Songs' (optional, opens song picker)
    ]
  ),
);
```

**Validation:**
- Name required, unique per user
- Description max length
- Handle empty playlist creation

**Estimated Time:** 2 hours

---

### 4.4 Playlist Detail Screen

```dart
// lib/features/profile/presentation/screens/playlist_detail_screen.dart
class PlaylistDetailScreen extends ConsumerWidget {
  // Header:
  // - Cover image (tap to change)
  // - Name + Edit button
  // - Description + Edit button
  // - Stats (X songs, X mins, X plays)
  // - Action buttons (Play All, Shuffle, Share, Delete)
  
  // Song List:
  // - Draggable list (reorder songs)
  // - Song tiles with options
  // - Add songs button
  // - Remove from playlist
}
```

**Features:**
- Drag & drop reordering
- Swipe to remove
- Play from specific song
- Edit playlist info inline
- Change cover image (upload or mosaic)

**Estimated Time:** 4 hours

---

### 4.5 Add to Playlist Flow

```dart
// From any song (long press or options menu)
showModalBottomSheet(
  context: context,
  builder: (context) => AddToPlaylistSheet(
    song: selectedSong,
    playlists: userPlaylists,
    actions: [
      'Create New Playlist',
      ...userPlaylists.map((p) => PlaylistTile(p))
    ]
  ),
);
```

**Features:**
- Show all user playlists
- Search playlists
- Create new playlist inline
- Multi-select songs before opening sheet
- Feedback on add success

**Estimated Time:** 2 hours

---

## 🔌 Phase 5: API Integration (Priority: HIGH after UI done)

### 5.1 Backend Endpoints Needed

#### User Songs
```typescript
GET    /api/users/:userId/songs           // Fetch user's uploaded songs
POST   /api/songs                         // Upload new song (with file)
PATCH  /api/songs/:songId                // Update song details
DELETE /api/songs/:songId                // Delete song
GET    /api/songs/:songId/stats          // Analytics for song
```

#### Liked Songs
```typescript
GET    /api/users/:userId/liked          // Fetch liked song IDs
POST   /api/songs/:songId/like           // Like a song
DELETE /api/songs/:songId/like           // Unlike a song
GET    /api/songs/liked                  // Get full liked songs with details
```

#### Playlists
```typescript
GET    /api/users/:userId/playlists                // Fetch user playlists
POST   /api/playlists                              // Create playlist
GET    /api/playlists/:playlistId                 // Get playlist details
PATCH  /api/playlists/:playlistId                 // Update playlist info
DELETE /api/playlists/:playlistId                 // Delete playlist
POST   /api/playlists/:playlistId/songs           // Add songs to playlist
DELETE /api/playlists/:playlistId/songs/:songId   // Remove song
PATCH  /api/playlists/:playlistId/reorder         // Reorder songs
POST   /api/playlists/:playlistId/play            // Increment play count
```

**Estimated Time:** 8 hours (backend + frontend integration)

---

### 5.2 Service Layer

```dart
// lib/features/profile/services/user_songs_service.dart
class UserSongsService {
  final Dio _dio;
  
  Future<List<SongModel>> getUserSongs(String userId);
  Future<SongModel> uploadSong(File audioFile, Map<String, dynamic> metadata);
  Future<void> updateSong(String songId, Map<String, dynamic> updates);
  Future<void> deleteSong(String songId);
  Future<SongStats> getSongStats(String songId);
}

// lib/features/profile/services/playlist_service.dart
class PlaylistService {
  final Dio _dio;
  
  Future<List<Playlist>> getUserPlaylists(String userId);
  Future<Playlist> createPlaylist(CreatePlaylistDto dto);
  Future<Playlist> getPlaylistDetail(String playlistId);
  Future<void> updatePlaylist(String playlistId, Map<String, dynamic> updates);
  Future<void> deletePlaylist(String playlistId);
  Future<void> addSongsToPlaylist(String playlistId, List<String> songIds);
  Future<void> removeSongFromPlaylist(String playlistId, String songId);
  Future<void> reorderPlaylist(String playlistId, List<String> newOrder);
}
```

**Estimated Time:** 4 hours

---

## 🎨 Phase 6: UI/UX Enhancements (Priority: LOW)

### 6.1 Animations

```dart
// Hero animations
- Song card to full player
- Playlist card to detail screen

// List animations
- Staggered grid appearance (AnimatedList)
- Slide in/out for song removal
- Fade transitions for tab changes
- Ripple effect on tap

// Micro-interactions
- Like button heart animation (scale + color)
- Download progress indicator
- Loading shimmer
- Pull to refresh animation
```

**Estimated Time:** 3 hours

---

### 6.2 Advanced Features

```dart
// Search & Filter
- Search bar in app bar
- Filter by genre, date, play count
- Clear filters button

// Offline Mode
- Downloaded songs indicator
- Play offline songs only filter
- Cache management

// Statistics Dashboard (optional)
- Total plays chart (last 30 days)
- Top performing songs
- Earnings timeline
- Follower growth graph
- Genre distribution pie chart
```

**Estimated Time:** 6 hours

---

## 📊 Success Metrics

### Phase 1 Success Criteria
- [ ] Profile songs play through real audio player
- [ ] Currently playing song highlighted in profile grid
- [ ] Like state synced between player and profile
- [ ] No mock data, uses actual SongModel

### Phase 2 Success Criteria  
- [ ] User can view all their uploaded songs
- [ ] Sort functionality works (Recent, Most Played, A-Z)
- [ ] Can delete songs with confirmation
- [ ] Loading and error states handled gracefully

### Phase 3 Success Criteria
- [ ] Liked songs display correctly
- [ ] Real-time sync when liking from player
- [ ] Can remove songs from liked
- [ ] Empty state shows when no liked songs

### Phase 4 Success Criteria
- [ ] Can create playlists with name and description
- [ ] Playlists display in grid with cover mosaics
- [ ] Can add songs to playlists from anywhere
- [ ] Playlist detail screen shows all songs
- [ ] Can reorder songs in playlist
- [ ] Can delete playlists

### Phase 5 Success Criteria
- [ ] All features work with real API
- [ ] Proper error handling for network failures
- [ ] Loading states for all API calls
- [ ] Optimistic UI updates where appropriate

---

## 🗂️ File Structure

```
lib/features/profile/
├── models/
│   ├── playlist.dart                    (NEW)
│   ├── song_stats.dart                  (NEW)
│   └── user_profile_model.dart          (EXISTING)
│   ❌ song_model.dart                   (DELETE - use player's SongModel)
├── providers/
│   ├── user_songs_provider.dart         (NEW)
│   ├── liked_songs_provider.dart        (NEW)
│   └── playlists_provider.dart          (NEW)
├── services/
│   ├── user_songs_service.dart          (NEW)
│   └── playlist_service.dart            (NEW)
├── presentation/
│   ├── screens/
│   │   ├── profile_screen.dart          (UPDATE)
│   │   ├── playlist_detail_screen.dart  (NEW)
│   │   └── create_playlist_screen.dart  (NEW - or use bottom sheet)
│   └── widgets/
│       ├── profile_header.dart          (EXISTING)
│       ├── song_card.dart               (UPDATE)
│       ├── liked_songs_list.dart        (NEW)
│       ├── playlist_card.dart           (NEW)
│       ├── playlist_song_tile.dart      (NEW)
│       ├── add_to_playlist_sheet.dart   (NEW)
│       ├── create_playlist_sheet.dart   (NEW)
│       └── song_options_sheet.dart      (EXTRACT from profile_screen.dart)
└── utils/
    └── playlist_utils.dart              (NEW - mosaic generation, etc.)
```

---

## ⏱️ Time Estimates

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| Phase 1: Foundation | Model unification, player integration, like sync | 4-5 hours |
| Phase 2: My Songs | Provider, UI updates, management actions | 7 hours |
| Phase 3: Liked Tab | List implementation, bulk actions | 5 hours |
| Phase 4: Playlists | Models, CRUD operations, detail screen | 10 hours |
| Phase 5: API Integration | Services, endpoints, error handling | 12 hours |
| Phase 6: Enhancements | Animations, advanced features | 9 hours |
| **TOTAL** | | **47-48 hours** |

---

## 🎯 Quick Win Strategy (2-3 hours)

For immediate visible progress:

1. **Remove mock data** (30 mins)
   - Delete profile song_model.dart
   - Update imports to use player's SongModel
   - Use SampleSongs.songs from player

2. **Connect to player** (1 hour)
   - Replace snackbar with real play action
   - Highlight currently playing song
   - Test play/pause functionality

3. **Basic like sync** (1.5 hours)
   - Create simple likedSongsProvider with Set<String>
   - Update song cards to show like state
   - Make like button functional

**Result:** Profile becomes a functional music player interface!

---

## 🚧 Known Challenges

1. **Data Consistency:** Keeping profile data in sync with player state
2. **Performance:** Large playlists (1000+ songs) need pagination
3. **Image Handling:** Playlist cover mosaics require image processing
4. **Offline Mode:** Complex caching strategy needed
5. **Real-time Updates:** WebSocket for follower count, play count updates

---

## 📝 Notes

- Profile screen currently at 400 lines - consider splitting into smaller widgets
- Mock data in `MockSongs` class has 10 songs - good for testing
- Profile header already implements follower stats - consider activity feed later
- Consider implementing social features (follow/unfollow) alongside this work

---

## ✅ Checklist

### Phase 1 (Foundation)
- [ ] Delete profile/models/song_model.dart
- [ ] Update all imports to use player SongModel
- [ ] Connect play action to audioPlayerProvider
- [ ] Create likedSongsProvider
- [ ] Sync like state across app
- [ ] Highlight currently playing song
- [ ] Test play/pause from profile

### Phase 2 (My Songs)
- [ ] Create userSongsProvider
- [ ] Add loading states
- [ ] Add error handling
- [ ] Implement delete with confirmation
- [ ] Add song statistics view
- [ ] Test all sort options

### Phase 3 (Liked)
- [ ] Implement liked songs list
- [ ] Add remove from liked action
- [ ] Implement bulk actions
- [ ] Add search/filter
- [ ] Test real-time sync

### Phase 4 (Playlists)
- [ ] Create Playlist model
- [ ] Create playlistsProvider
- [ ] Implement playlist grid
- [ ] Create playlist dialog
- [ ] Implement detail screen
- [ ] Add drag & drop reordering
- [ ] Implement add to playlist flow
- [ ] Test all CRUD operations

### Phase 5 (API)
- [ ] Define API contracts with backend team
- [ ] Create service layer
- [ ] Integrate all endpoints
- [ ] Add error handling
- [ ] Test with real data

### Phase 6 (Polish)
- [ ] Add animations
- [ ] Implement advanced features
- [ ] Performance optimization
- [ ] Final testing

---

**Last Updated:** February 10, 2026  
**Next Review:** After Phase 1 completion
