# Discover Feature - Dynamic & Realtime Implementation Plan

**Date:** February 13, 2026  
**Status:** Planning Phase  
**Goal:** Replace dummy data with real-time API integration

---

## Current State Analysis

### ✅ What's Already Working
1. **Backend API** - Fully functional
   - `/api/v1/songs/discover` - Returns paginated songs with filters
   - `/api/v1/songs/genres` - Returns available genres
   - Proper artistId population with username
   - Pagination working (currentPage, totalPages, hasMore)

2. **Infrastructure** - Already implemented
   - ✅ `SongApiService` - API client methods ready
   - ✅ `SongListNotifier` - Provider with state management
   - ✅ Pagination logic implemented
   - ✅ Filters (search, genre, sort) ready
   - ✅ `SongModel` - Proper model with Artist data

3. **UI Components** - Existing widgets
   - ✅ `SongListTile` - Already using theme colors
   - ✅ Responsive design

### ❌ What Needs Implementation
1. **Discover Screen** - Currently using `SampleSongs.songs` (dummy data)
2. **No loading states** - No shimmer/skeleton loaders
3. **No error handling UI** - When API fails
4. **No empty state** - When no songs found
5. **No pull-to-refresh** - Manual refresh needed
6. **No search/filter UI** - Providers exist but no UI controls
7. **No infinite scroll** - Load more not triggered

---

## API Response Structure

```json
{
  "success": true,
  "data": {
    "songs": [
      {
        "_id": "698d70915c3e217a59223300",
        "artistId": {
          "_id": "6982bda1b7a73570da690db9",
          "email": "frederick@breakinghits.com",
          "username": "dekzblaster2"
        },
        "title": "Sikap",
        "duration": 293,
        "price": 10,
        "coverArt": "https://via.placeholder.com/300",
        "audioUrl": "/uploads/Sikap-1770877071948-949355635.mp3",
        "exclusive": false,
        "genre": "Hip Hop",
        "description": "sikap at tyaga",
        "playCount": 0,
        "featured": false,
        "createdAt": "2026-02-12T06:17:53.973Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 1,
      "totalSongs": 4,
      "limit": 10,
      "hasMore": false
    }
  }
}
```

---

## Implementation Plan

### Phase 1: Core Integration (High Priority)
**Goal:** Replace dummy data with real API calls

#### 1.1 Update Discover Screen ✏️
- [ ] Replace `SampleSongs.songs` with `songListProvider`
- [ ] Add loading state (circular progress or shimmer)
- [ ] Add error state with retry button
- [ ] Add empty state ("No songs found")
- [ ] Implement pull-to-refresh with `RefreshIndicator`

**Files to modify:**
- `lib/features/discover/screens/discover_screen.dart`

#### 1.2 Add Infinite Scroll ✏️
- [ ] Add `ScrollController` to detect bottom
- [ ] Call `songListNotifier.loadMore()` at threshold
- [ ] Show loading indicator at bottom when loading more
- [ ] Handle "no more items" state

#### 1.3 Model Mapping Fix ✏️
- [ ] Ensure `SongModel` in discover matches player `SongModel`
- [ ] Handle null artistId cases (old data)
- [ ] Map `price` → `tokenReward`
- [ ] Convert relative `audioUrl` to absolute

**Current issue:** Discover has its own `SongModel` that may not match player model

---

### Phase 2: Search & Filters (Medium Priority)
**Goal:** Add interactive filtering

#### 2.1 Search Bar ✏️
- [ ] Add search TextField in app bar or header
- [ ] Debounce search input (500ms delay)
- [ ] Update `searchQueryProvider` on change
- [ ] Trigger `applyFilters()` after debounce
- [ ] Show "Searching..." indicator
- [ ] Clear search button

#### 2.2 Genre Filter ✏️
- [ ] Fetch genres from API via `genresProvider`
- [ ] Show horizontal scrollable genre chips
- [ ] "All" chip to clear filter
- [ ] Highlight selected genre
- [ ] Update `selectedGenreProvider`
- [ ] Trigger `applyFilters()`

#### 2.3 Sort Options ✏️
- [ ] Add dropdown or bottom sheet for sort
- [ ] Options: "Latest", "Most Played", "Price: Low-High", "Price: High-Low"
- [ ] Map to API sort parameters
- [ ] Update `selectedSortProvider`
- [ ] Trigger `applyFilters()`

**UI Placement:**
```
┌─────────────────────────────┐
│ 🔍 Search...         [Sort] │
├─────────────────────────────┤
│ [All] [Hip Hop] [Pop]...    │
├─────────────────────────────┤
│ Song List                   │
│ ...                         │
```

---

### Phase 3: Enhanced UX (Low Priority)
**Goal:** Polish user experience

#### 3.1 Shimmer Loading ✏️
- [ ] Create `SongListTileShimmer` widget
- [ ] Show 5-6 shimmer tiles while loading
- [ ] Smooth fade-in when songs load

#### 3.2 Featured Songs Section ✏️
- [ ] Horizontal scrollable featured songs
- [ ] Larger cards with gradient overlay
- [ ] Show above main list
- [ ] Filter: `featured=true`

#### 3.3 Optimizations ✏️
- [ ] Cache API responses (5 min)
- [ ] Prefetch next page on scroll
- [ ] Image caching with `CachedNetworkImage`
- [ ] Lazy loading for off-screen items

---

## File Structure

```
lib/features/discover/
├── models/
│   └── song_model.dart          ✅ Already exists
├── providers/
│   └── song_provider.dart       ✅ Needs wire-up
├── screens/
│   └── discover_screen.dart     ❌ UPDATE: Remove dummy data
├── services/
│   └── song_api_service.dart    ✅ Already complete
└── widgets/
    ├── song_list_tile.dart       ✅ Already using theme
    ├── song_list_shimmer.dart    ❌ CREATE: Loading skeleton
    ├── genre_filter_chips.dart   ❌ CREATE: Genre selector
    └── search_bar_widget.dart    ❌ CREATE: Search input
```

---

## Code Changes Preview

### 1. Updated Discover Screen Structure
```dart
class DiscoverScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(songListProvider.notifier).loadMore();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songListProvider);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(songListProvider.notifier).fetchSongs(refresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader()),
            
            // Content based on state
            songsAsync.when(
              loading: () => SliverToBoxAdapter(child: _buildLoading()),
              error: (e, s) => SliverToBoxAdapter(child: _buildError(e)),
              data: (songs) => songs.isEmpty 
                ? SliverToBoxAdapter(child: _buildEmpty())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => SongListTile(song: songs[index]),
                      childCount: songs.length,
                    ),
                  ),
            ),
            
            // Load more indicator
            if (songsAsync.hasValue && songsAsync.value!.isNotEmpty)
              SliverToBoxAdapter(child: _buildLoadMoreIndicator()),
          ],
        ),
      ),
    );
  }
}
```

### 2. Model Conversion
Since discover has its own `SongModel`, need to convert to player `SongModel`:
```dart
import '../../player/models/song_model.dart' as PlayerSongModel;

PlayerSongModel.SongModel _toPlayerModel(SongModel discoverSong) {
  return PlayerSongModel.SongModel(
    id: discoverSong.id,
    title: discoverSong.title,
    artist: discoverSong.artist.username,
    artistId: discoverSong.artist.id,
    albumArt: discoverSong.coverArt,
    audioUrl: discoverSong.audioUrl,
    duration: Duration(seconds: discoverSong.duration),
    tokenReward: discoverSong.price,
    genre: discoverSong.genre,
    isPremium: discoverSong.exclusive,
  );
}
```

---

## Testing Checklist

### API Integration
- [ ] Songs load on screen open
- [ ] Pull-to-refresh works
- [ ] Pagination loads next page
- [ ] No duplicate songs after refresh
- [ ] Loading states show correctly
- [ ] Error handling works (turn off backend)
- [ ] Empty state shows when no songs

### Search & Filters
- [ ] Search updates results after typing
- [ ] Genre filter works
- [ ] Sort options change order
- [ ] Filters can be combined
- [ ] Clear filters returns to all songs

### Performance
- [ ] Smooth scrolling (60fps)
- [ ] No memory leaks on refresh
- [ ] Images load without lag
- [ ] Works with 100+ songs

### Edge Cases
- [ ] Handle null artistId (old songs)
- [ ] Handle missing cover art
- [ ] Handle invalid audio URLs
- [ ] Network timeout handling
- [ ] Empty genres list

---

## Estimated Effort

| Phase | Tasks | Time | Priority |
|-------|-------|------|----------|
| Phase 1: Core | 3 tasks | 2-3 hours | HIGH |
| Phase 2: Filters | 3 tasks | 2 hours | MEDIUM |
| Phase 3: Polish | 3 tasks | 1-2 hours | LOW |
| **Total** | **9 tasks** | **5-7 hours** | - |

---

## Implementation Order

1. ✅ **First:** Update discover screen with API integration (30 min)
2. ✅ **Second:** Add loading/error/empty states (30 min)
3. ✅ **Third:** Implement pull-to-refresh (15 min)
4. ✅ **Fourth:** Add infinite scroll (30 min)
5. ⏭️ **Fifth:** Add search bar (45 min)
6. ⏭️ **Sixth:** Add genre filters (45 min)
7. ⏭️ **Seventh:** Add sort options (30 min)
8. ⏭️ **Eighth:** Create shimmer loading (45 min)
9. ⏭️ **Ninth:** Test & polish (1 hour)

---

## Risk Assessment

### High Risk
- **Model mismatch:** Discover `SongModel` ≠ Player `SongModel`
  - **Mitigation:** Create converter function or unify models

### Medium Risk
- **Old songs with null artistId:** Will cause crashes
  - **Mitigation:** Add null checks, show "Unknown Artist"

### Low Risk
- **Performance with many songs:** Might slow down
  - **Mitigation:** Use pagination, lazy loading

---

## Next Steps

1. **Review this plan** with team/user
2. **Approve implementation order**
3. **Start with Phase 1** (Core Integration)
4. **Test each phase** before moving to next
5. **Deploy incrementally** to catch issues early

---

**Ready to proceed?** 🚀
