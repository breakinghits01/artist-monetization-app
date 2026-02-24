# Rising Stars Feature - Implementation Plan
**Date:** February 24, 2026  
**Status:** PENDING - Requires Engagement Metrics First

---

## Overview
Transform the single artist spotlight card into a "Rising Stars" collection featuring top 100 rising artist accounts with growth-based ranking.

---

## Ranking Formula (Approved - Option B: Balanced)

```javascript
risingScore = 
  (newSongsLast30Days × 200) +      // Recent uploads (highest priority)
  (newFollowersLast30Days × 100) +  // Growth momentum (second priority)
  (totalPlayCount × 0.05) +         // Engagement quality
  (totalSongs × 5) +                // Content library
  (totalFollowers × 2)              // Existing fanbase
```

### Weight Breakdown:
| Metric | Weight | Example | Points |
|--------|--------|---------|--------|
| New song (30 days) | ×200 | 1 song | 200 |
| New follower (30 days) | ×100 | 1 follower | 100 |
| Total songs | ×5 | 1 song | 5 |
| Total followers | ×2 | 1 follower | 2 |
| Total plays | ×0.05 | 20 plays | 1 |

### Example Calculation:
```javascript
// Active Rising Artist
newSongs: 3, newFollowers: 20, totalSongs: 5, totalFollowers: 25, plays: 800
= (3 × 200) + (20 × 100) + (800 × 0.05) + (5 × 5) + (25 × 2)
= 600 + 2000 + 40 + 25 + 50
= 2,715 points ⭐⭐⭐

// Established Artist (Not Rising)
newSongs: 0, newFollowers: 5, totalSongs: 50, totalFollowers: 500, plays: 50000
= (0 × 200) + (5 × 100) + (50000 × 0.05) + (50 × 5) + (500 × 2)
= 0 + 500 + 2500 + 250 + 1000
= 4,250 points ⭐⭐
```

---

## Technical Approach: Aggregation-Based (No Schema Changes)

### Data Sources (Existing):
- ✅ `Follow.createdAt` - Calculate new followers last 30 days
- ✅ `Song.createdAt` - Calculate new songs last 30 days
- ✅ `Song.playCount` - Sum total plays
- ✅ Total songs count
- ✅ Total followers count

### Backend Implementation:
```typescript
// Enhanced discoverArtists endpoint
GET /api/v1/users/discover?sortBy=risingScore&limit=100

// MongoDB Aggregation Pipeline:
1. Match artists (role: 'artist')
2. Lookup follows and songs
3. Calculate metrics:
   - newFollowers = filter follows by createdAt >= 30DaysAgo
   - newSongs = filter songs by createdAt >= 30DaysAgo
   - totalPlayCount = sum all song.playCount
4. Calculate risingScore using formula
5. Sort by risingScore DESC
6. Paginate results
```

### Performance Optimization:
```typescript
// Cache in Redis (1 hour TTL)
Key: 'rising_stars_top100'
Invalidate on:
  - New song upload
  - New follower
  - Every hour (auto-refresh)
```

---

## BLOCKER: Missing Engagement Metrics ⚠️

### Required Before Implementation:
- ❌ **Likes/Reactions** - Not implemented
- ❌ **Comments** - Not implemented  
- ❌ **Shares** - Not implemented
- ❌ **Ratings** - Exists in schema but not in UI

### Impact on Formula:
Without engagement metrics, the formula is incomplete:
- Can't measure viral potential
- Can't detect quality content
- Play count alone is insufficient

**Decision:** Implement engagement features first, then return to Rising Stars.

---

## Phase 1: Engagement Features (PRIORITY) 🎯

### 1. Like/Dislike System
- Add like/dislike icons to song cards
- Track user preferences
- Show like count publicly
- Use in risingScore calculation

### 2. Comments System
- Comment on songs
- Threaded replies
- Show comment count
- Use in engagement score

### 3. Share/Save Features
- Share song links
- Add to favorites
- Track share count
- Boost discovery

### Enhanced Formula (Post-Engagement):
```javascript
risingScore = 
  (newSongsLast30Days × 200) +
  (newFollowersLast30Days × 100) +
  (newLikesLast30Days × 80) +        // NEW
  (newCommentsLast30Days × 60) +     // NEW
  (newSharesLast30Days × 40) +       // NEW
  (totalPlayCount × 0.05) +
  (avgRating × 50) +                 // NEW
  (totalSongs × 5) +
  (totalFollowers × 2)
```

---

## Phase 2: Rising Stars UI

### Dashboard Card Update:
```dart
// Change from individual artist to collection
DashboardCardModel(
  type: DashboardCardType.risingStars,
  title: 'Rising Stars',
  subtitle: '⭐ 100 trending artists',
  badge: 'RISING STARS',
  metadata: {'artistCount': 100},
)
```

### New Screen: rising_stars_screen.dart
**Features:**
- Hero animation from dashboard card
- Top 100 artists grid (2 columns mobile, 4 desktop)
- Filter bar (Sort by: Score, Songs, Followers, Latest)
- Genre filter
- Rank badges (#1, #2, #3 with medals)
- Artist cards with:
  - Rank number
  - Profile picture
  - Username
  - Stats (songs, followers, score)
  - Follow button
  - Tap to view profile

### File Structure:
```
lib/features/rising_stars/
  ├── screens/
  │   └── rising_stars_screen.dart
  ├── providers/
  │   └── rising_stars_provider.dart
  └── widgets/
      ├── rising_artist_card.dart
      ├── filter_bar.dart
      └── rank_badge.dart
```

---

## Phase 3: Gamification & Retention

### Artist Notifications:
- "You're #5 in Rising Stars this week!"
- "You gained 50 new followers today!"
- "Your song hit 1,000 plays!"
- "Upload 2 more songs to reach Top 50!"

### Weekly Reset:
- Rankings reset every Monday
- Weekly leaderboard archive
- Achievement badges

### Categories:
- 🔥 Hot This Week (most plays)
- ⭐ Rising Stars (growth-based)
- 🎵 Most Prolific (uploads)
- 💎 Hidden Gems (quality + low followers)

---

## Database Indexes (Future Optimization):

```javascript
// Compound indexes for performance
db.follows.createIndex({ followingId: 1, createdAt: -1 });
db.songs.createIndex({ artistId: 1, createdAt: -1, playCount: -1 });
db.songs.createIndex({ createdAt: -1, playCount: -1 }); // For trending

// Text search
db.users.createIndex({ username: "text", bio: "text" });
```

---

## Timeline (Post-Engagement Implementation):

**Week 1:** Enhanced risingScore backend endpoint  
**Week 2:** Rising Stars screen + navigation  
**Week 3:** Caching layer + optimization  
**Week 4:** Gamification + notifications  

---

## Next Steps:

1. ✅ Document this plan
2. ⏸️ Pause Rising Stars implementation
3. 🎯 **PRIORITY:** Implement engagement features (likes, comments, shares)
4. 🔄 Return to Rising Stars with complete metrics

---

## Notes:

- Formula prioritizes active creators over established artists ✅
- No schema changes needed (uses existing timestamps) ✅
- Requires engagement metrics for accurate scoring ⚠️
- Caching required for performance at scale ✅
- Can evolve to full analytics schema later 🔄

---

**Status:** ON HOLD - Waiting for engagement features implementation
