# Song Engagement Features - Implementation Plan
**Date:** February 24, 2026  
**Status:** PENDING - Required for Rising Stars Feature

---

## Overview
Add like/dislike, comments, and share functionality to songs to increase user engagement and provide better metrics for Rising Stars ranking.

---

## Current State Analysis

### ✅ Existing Backend:
- **Rating Model** (`Rating.model.ts`): Stars (1-5) + comment field
  - Already has userId, songId, stars, comment
  - Unique constraint: one rating per user per song
  - Prevents artists rating their own songs
  - Indexed for performance

### ❌ Missing Features:
- **Like/Dislike** - No model or endpoints
- **Comments as separate entity** - Rating.comment is limited to rating context
- **Shares** - No tracking
- **Song Details Screen** - No dedicated view for engagement
- **UI icons** - No engagement icons on discover screen

---

## Phase 1: Backend Schema & Endpoints 🗄️

### 1. Create Song Like/Reaction Model

**File:** `src/models/SongLike.model.ts`

```typescript
interface ISongLike extends Document {
  userId: ObjectId;
  songId: ObjectId;
  likeType: 'like' | 'dislike';  // or enum
  createdAt: Date;
}

// Indexes:
- { userId: 1, songId: 1 } - unique (one reaction per user per song)
- { songId: 1, likeType: 1 } - count likes/dislikes
- { createdAt: -1 } - recent activity
```

**Endpoints:**
```typescript
POST   /api/v1/songs/:songId/like         // Toggle like
POST   /api/v1/songs/:songId/dislike      // Toggle dislike  
DELETE /api/v1/songs/:songId/reaction     // Remove reaction
GET    /api/v1/songs/:songId/reaction     // Get user's reaction
GET    /api/v1/songs/:songId/likes/count  // Get counts { likes: 150, dislikes: 5 }
```

---

### 2. Create Song Comment Model

**File:** `src/models/Comment.model.ts`

```typescript
interface IComment extends Document {
  userId: ObjectId;
  songId: ObjectId;
  content: string;              // Max 500 chars
  parentCommentId?: ObjectId;   // For threaded replies
  likes: number;                // Comment likes
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;             // Soft delete
}

// Indexes:
- { songId: 1, createdAt: -1 } - Recent comments per song
- { userId: 1, createdAt: -1 } - User's comments
- { parentCommentId: 1 } - Thread replies
```

**Endpoints:**
```typescript
POST   /api/v1/songs/:songId/comments              // Create comment
GET    /api/v1/songs/:songId/comments              // List comments (paginated)
POST   /api/v1/comments/:commentId/reply          // Reply to comment
PATCH  /api/v1/comments/:commentId                // Edit comment
DELETE /api/v1/comments/:commentId                // Delete comment (soft)
POST   /api/v1/comments/:commentId/like           // Like comment
GET    /api/v1/comments/:commentId/replies        // Get thread
```

---

### 3. Create Song Share/Save Model

**File:** `src/models/SongShare.model.ts`

```typescript
interface ISongShare extends Document {
  userId: ObjectId;
  songId: ObjectId;
  shareType: 'link' | 'social' | 'download' | 'playlist';
  createdAt: Date;
}

// Indexes:
- { songId: 1, shareType: 1 } - Count shares by type
- { userId: 1, createdAt: -1 } - User share history
- { createdAt: -1 } - Recent shares
```

**Endpoints:**
```typescript
POST /api/v1/songs/:songId/share        // Track share event
GET  /api/v1/songs/:songId/shares/count // Get share count
```

---

### 4. Enhance Song Model

**Add aggregated counters** (updated via background jobs or hooks):

```typescript
interface ISong {
  // ... existing fields
  
  // Engagement metrics (cached from relations)
  likeCount: number;          // Count from SongLike
  dislikeCount: number;       // Count from SongLike
  commentCount: number;       // Count from Comment
  shareCount: number;         // Count from SongShare
  averageRating: number;      // Average from Rating
  ratingCount: number;        // Count from Rating
  
  // Engagement score (calculated)
  engagementScore: number;
  engagementUpdatedAt: Date;
}
```

**Engagement Score Formula:**
```typescript
engagementScore = 
  (likeCount × 5) +
  (commentCount × 10) +
  (shareCount × 15) +
  (playCount × 1) +
  (averageRating × 20) -
  (dislikeCount × 2)
```

---

## Phase 2: Frontend UI Components 🎨

### 1. Engagement Icons Row

**File:** `lib/features/discover/widgets/engagement_actions.dart`

**Design (Simplified):**
```
👍  💬  ↗️  ⭐
150  23  12  4.5
```

Or even simpler - icons only, no counts:
```
👍  💬  ↗️  
```
(Counts shown only inside bottom sheets)

**Features:**
- Like button (simple icon, no text - shows count in tooltip/long-press)
- Comment button (opens comments bottom sheet with count in header)
- Share button (opens share sheet)
- Rating stars (optional - only if song has ratings)

**Visual Flow When Tapping Comment Icon:**

```
User taps [💬 23] 
        ↓
Bottom sheet slides up (500ms animation)
        ↓
Shows scrollable comments list + input at bottom
        ↓
User can:
  - Read existing comments
  - Type new comment → Tap Send
  - Reply to comment → Opens nested input
  - Like a comment → Heart turns red
  - Swipe down / Tap X → Close sheet
```

**States:**
- Liked: Red/pink filled heart
- Not liked: Gray outlined heart
- Disabled during API call (loading)

---

### 2. Update Song List Tile

**File:** `lib/features/discover/widgets/song_list_tile.dart`

**Add engagement row below genre/playcount:**

**Implementation (Matching existing playcount pattern):**
```dart
subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const SizedBox(height: 4),
    
    // Artist name
    Text(
      song.artist,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    
    const SizedBox(height: 4),
    
    // Existing row: Genre, playCount, tokens, premium
    Row(
      children: [
        Text(
          song.genre ?? 'Unknown',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.headphones, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 4),
        Text('${song.playCount}', style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        )),
        // ... tokens and premium badge
      ],
    ),
    
    const SizedBox(height: 4),
    
    // NEW: Engagement row (same pattern)
    Row(
      children: [
        // Like
        GestureDetector(
          onTap: () => _toggleLike(),
          child: Row(
            children: [
              Icon(
                isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                size: 12,
                color: isLiked 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(song.likeCount ?? 0),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        
        // Comment
        GestureDetector(
          onTap: () => _showCommentsSheet(context, song),
          child: Row(
            children: [
              Icon(Icons.mode_comment_outlined, size: 12, 
                color: theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                _formatCount(song.commentCount ?? 0),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        
        // Share
        GestureDetector(
          onTap: () => _showShareSheet(context, song),
          child: Row(
            children: [
              Icon(Icons.share_outlined, size: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                _formatCount(song.shareCount ?? 0),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        
        // Rating (if exists)
        if (song.averageRating != null && song.averageRating! > 0) ...[
          const SizedBox(width: 8),
          Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            song.averageRating!.toStringAsFixed(1),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ],
    ),
  ],
)

// Helper method
String _formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
  return '$count';
}
```

// Methods:
void _showCommentsSheet(BuildContext context, Song song) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allow custom height
    backgroundColor: Colors.transparent,
    builder: (context) => CommentsBottomSheet(songId: song.id),
  );
}

void _showShareSheet(BuildContext context, Song song) {
  showModalBottomSheet(
    context: context,
    builder: (context) => ShareBottomSheet(song: song),
  );
}
```

---

### 3. Comments Bottom Sheet

**File:** `lib/features/song/widgets/comments_bottom_sheet.dart`

**Trigger:** Tap the [💬 23] icon on any song tile

**Animation:** Bottom sheet slides up from bottom (like Instagram/YouTube comments)

**Features:**
- Slide-up modal (covers 75% of screen height)
- Comment list (paginated, newest first)
- Text input at bottom (fixed position)
- Threaded replies (indent + "Show replies" button)
- User avatar + username
- Time ago (2h ago, 3d ago)
- Like comment button
- Delete own comments
- Report inappropriate comments
- Pull to refresh
- Swipe down to dismiss

**UI Structure:**
```
                                    ← Tap [💬 23] icon
                                    
┌─────────────────────────────┐
│ ════ (drag handle)          │  ← Swipe down to close
│ 💬 Comments (23)        [×] │  ← Header with close button
├─────────────────────────────┤
│ 👤 user123  • 2h ago        │  ← Avatar + username + timestamp
│    Great song! 🔥           │  ← Comment content
│    [❤️ 5] [↩️ Reply]        │  ← Like count + Reply button
│                             │
│ 👤 artist1  • 5h ago        │
│    Thank you! More coming   │
│    [❤️ 12] [↩️ Reply]       │
│    └─ 👤 user456 • 3h ago   │  ← Nested reply (indented)
│       Can't wait!           │
│       [❤️ 2]                │
│                             │
│ 👤 jazzfan99  • 1d ago      │
│    🔥🔥🔥                    │
│ Trigger:** Tap the [🔗 12] share icon on any song tile

**Animation:** Bottom sheet slides up from bottom (shorter, ~50% height)

**UI Structure:**
```
┌─────────────────────────────┐
│ ════ (drag handle)          │
│ Share "Song Title"      [×] │
├─────────────────────────────┤
│                             │
│ 🔗 Copy Link to Song        │  ← Tap → Copy + show toast
│                             │
│ 📱 Share via...             │  ← Opens native share (iOS/Android)
│                             │
│ ➕ Add to Playlist          │  ← Opens playlist selector
│                             │
│ 👤 Share Artist Profile     │  ← Share artist link
│                             │
│ ⬇️ Download (Premium)       │  ← If user purchased/artist
│                             │
└─────────────────────────────┘
```

**Options:**
- 📋 **Copy Link** → Copies `app.domain.com/song/123` + Toast "Link copied!"
- 📱 **Share via...** → Native share sheet (WhatsApp, Twitter, etc.)
- ⬇️ **Download Song** → Only if purchased or artist owns it
- ➕ **Add to Playlist** → Opens playlist selection dialog
- 🔗 **Share Artist Profile** → Share artist page link

**Interaction Flow:**

1. **User taps [🔗 12]:**
   - Bottom sheet slides up
   - Shows 5 share options
   - Track share event: `song.share_opened`

2. **Copy Link:**
   - Tap → Clipboard.copy()
   - Show toast: "✓ Link copied to clipboard"
   - Auto-close sheet after 1s
   - Track event: `song.shared.link`

3. **Share via native:**
   - Opens platform share sheet
   - User picks app (WhatsApp, Twitter, etc.)
   - Track event: `song.shared.social`

4. **Download:**
   - Check if user has access
   - If no: Show "Purchase to download"
   - If yes: Download MP3, show progress
   - Track event: `song.downloaded`nd]  │  ← Send button (enabled when text)
└─────────────────────────────┘
```

**Interaction Flow:**

1. **User taps [💬 23]:**
   - Bottom sheet slides up (500ms ease-out animation)
   - Shows loading skeleton while fetching comments
   - Loads first 20 comments

2. **Reading comments:**
   - Scroll to see more
   - Pull down to refresh
   - Tap "Load more" for pagination

3. **Adding comment:**
   - Tap text input → Keyboard appears
   - Type comment (max 500 chars, show counter)
   - Tap [Send] → API call + optimistic UI update
   - New comment appears at top with "Sending..." indicator
   - Success: Indicator removed, comment count +1
   - Error: Show retry button

4. **Replying to comment:**
   - Tap [↩️ Reply] → Input gains focus
   - Shows "Replying to @username" above input
   - Tap [X] to cancel reply
   - Send → Nested under parent comment

5. **Liking comment:**
   - Tap [❤️] → Heart turns red, count +1
   - Tap again → Heart gray, count -1
   - Optimistic update (instant feedback)

6. **Closing sheet:**
   - Swipe down (drag handle)
   - Tap [×] button
   - Tap outside sheet (dimmed background)
   - Sheet slides down (300ms animation)

---

### 4. Share Bottom Sheet

**File:** `lib/features/song/widgets/share_bottom_sheet.dart`

**Options:**
- 📋 Copy Link
- 📱 Share to Social Media (native share)
- ⬇️ Download Song (if purchased)
- ➕ Add to Playlist
- 🔗 Share Artist Profile

---

### 5. Rating Dialog

**File:** `lib/features/song/widgets/rating_dialog.dart`

**Features:**
- 5-star rating selector
- Optional comment (uses existing Rating model)
- Submit button
- Shows current user's rating (if exists)
- Can update existing rating

---

## Phase 3: State Management 📡

### Providers Structure:

```dart
// Like/Reaction Provider
final songLikeProvider = StateNotifierProvider.family<LikeNotifier, AsyncValue<LikeState>, String>

// Comments Provider
final songCommentsProvider = StateNotifierProvider.family<CommentsNotifier, AsyncValue<List<Comment>>, String>

// Rating Provider
final songRatingProvider = StateNotifierProvider.family<RatingNotifier, AsyncValue<Rating?>, String>

// Engagement Stats Provider
final engagementStatsProvider = FutureProvider.family<EngagementStats, String>
```

---

## Phase 4: Song Details Screen (Optional) 📱

**File:** `lib/features/song/screens/song_details_screen.dart`

**Features:**
- Large album art
- Song info (title, artist, genre, duration)
- Play/pause button
- Engagement actions (prominent)
- Waveform visualization
- Lyrics (future)
- Related songs
- Comments section
- Purchase options (if premium)

**Navigation:**
- Tap song tile → Opens details screen
- Tap play → Plays in-place (existing behavior)
- Long press → Show context menu

---

## Phase 5: Analytics Integration 📊

### Track Engagement Events:

```typescript
// Backend analytics
POST /api/v1/analytics/event

Events:
- song.liked
- song.unliked
- song.commented
- song.shared
- song.rated
- comment.liked
- comment.replied
```

### Use in Rising Stars:

```typescript
// Enhanced risingScore formula
risingScore = 
  (newSongsLast30Days × 200) +
  (newFollowersLast30Days × 100) +
  (newLikesLast30Days × 80) +        // NEW
  (newCommentsLast30Days × 60) +     // NEW
  (newSharesLast30Days × 40) +       // NEW
  (totalPlayCount × 0.05) +
  (averageRating × 50) +             // Enhanced
  (totalSongs × 5) +
  (totalFollowers × 2)
```

---

## Implementation Timeline 📅

### Week 1: Backend Foundation
- ✅ Day 1-2: Create models (SongLike, Comment, SongShare)
- ✅ Day 3-4: Build endpoints (CRUD operations)
- ✅ Day 5: Add to Song model (counters, engagement score)
- ✅ Day 6-7: Test endpoints, add indexes

### Week 2: Basic UI
- ✅ Day 1-2: Engagement icons row component
- ✅ Day 3: Update song list tile
- ✅ Day 4: Like/unlike functionality
- ✅ Day 5-6: Comments bottom sheet
- ✅ Day 7: Share functionality

### Week 3: Advanced Features
- ✅ Day 1-2: Rating dialog + integration
- ✅ Day 3-4: Threaded comments (replies)
- ✅ Day 5-6: Comment likes
- ✅ Day 7: Polish + animations

### Week 4: Integration & Testing
- ✅ Day 1-2: Song details screen (optional)
- ✅ Day 3-4: Analytics integration
- ✅ Day 5-6: Update Rising Stars with engagement metrics
- ✅ Day 7: Testing + bug fixes

---

## Database Indexes for Performance 🚀

```javascript
// SongLike indexes
db.songlikes.createIndex({ songId: 1, likeType: 1 });
db.songlikes.createIndex({ userId: 1, songId: 1 }, { unique: true });
db.songlikes.createIndex({ createdAt: -1 });

// Comment indexes
db.comments.createIndex({ songId: 1, createdAt: -1 });
db.comments.createIndex({ userId: 1 });
db.comments.createIndex({ parentCommentId: 1 });

// Share indexes
db.songshares.createIndex({ songId: 1 });
db.songshares.createIndex({ userId: 1, createdAt: -1 });

// Compound for aggregation
db.songs.createIndex({ engagementScore: -1, createdAt: -1 });
```

---

## API Response Examples 📋

### Song with Engagement:
```json
{
  "id": "song123",
  "title": "Amazing Track",
  "artist": "Artist Name",
  "playCount": 5000,
  "likeCount": 150,
  "dislikeCount": 5,
  "commentCount": 23,
  "shareCount": 45,
  "averageRating": 4.5,
  "ratingCount": 89,
  "engagementScore": 2150,
  "userEngagement": {
    "hasLiked": true,
    "hasDisliked": false,
    "hasRated": true,
    "userRating": 5,
    "hasCommented": false
  }
}
```

### Comment:
```json
{
  "id": "comment123",
  "userId": "user456",
  "username": "musiclover",
  "content": "Great song! 🔥",
  "likes": 12,
  "replyCount": 3,
  "createdAt": "2026-02-24T10:30:00Z",
  "userHasLiked": false
}
```

---

## UX Considerations 🎯

### Optimistic Updates:
- Like button responds instantly (update UI first, API second)
- Revert on error with toast message

### Loading States:
- Skeleton loaders for comments
- Shimmer effect while loading engagement stats

### Error Handling:
- Network errors: Show retry button
- Auth errors: Prompt login
- Rate limiting: Show cooldown timer

### Accessibility:
- Semantic labels for screen readers
- Keyboard navigation support
- High contrast mode support

---

## Next Steps:

1. ✅ Document this plan
2. 🎯 **START:** Implement backend models (SongLike, Comment, SongShare)
3. 🎯 Build REST API endpoints
4. 🎯 Create Flutter UI components
5. 🎯 Integrate with Rising Stars formula
6. 🔄 Test & deploy

---

## Questions to Answer:

1. **Comment Moderation:** Manual review or auto-filter profanity?
2. **Like vs Reaction:** Simple like/dislike or emoji reactions (❤️😍🔥👍)?
3. **Share Tracking:** Track all shares or just in-app?
4. **Rating vs Like:** Keep both or merge into one system?
5. **Notifications:** Notify artist on comments/likes?

---

**Status:** READY FOR IMPLEMENTATION  
**Priority:** HIGH (Blocks Rising Stars feature)  
**Estimated Effort:** 3-4 weeks for full implementation
