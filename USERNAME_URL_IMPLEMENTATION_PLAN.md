# Username-Based Profile URL Implementation Plan

## Current State
- Profile URLs use MongoDB ObjectID: `/profile/6982bda1b7a73570da690db9`
- Backend API only accepts ObjectID for `/users/profile/:userId` endpoint
- Frontend navigation uses `artist.id` from Rising Stars

## Goal
- Profile URLs should use username: `/profile/dekzblaster2`
- Better SEO and user-friendly URLs
- Backend needs to support username lookup

---

## Implementation Steps

### Phase 1: Backend API Changes (api_dynamic_artist_monetization)

#### 1.1 Update User Profile Endpoint
**File:** `src/controllers/auth.controller.ts` or `src/controllers/user.controller.ts`

**Current:**
```typescript
GET /api/v1/users/profile/:userId
// Only accepts MongoDB ObjectID
```

**Required Change:**
```typescript
GET /api/v1/users/profile/:identifier
// Should accept EITHER ObjectID OR username

// Pseudo-code logic:
const getUserProfile = async (req, res) => {
  const { identifier } = req.params;
  
  let user;
  
  // Check if identifier is a valid MongoDB ObjectID
  if (mongoose.Types.ObjectId.isValid(identifier)) {
    // Lookup by ID
    user = await User.findById(identifier);
  } else {
    // Lookup by username (case-insensitive)
    user = await User.findOne({ 
      username: { $regex: new RegExp(`^${identifier}$`, 'i') }
    });
  }
  
  if (!user) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }
  
  // Return user profile with stats...
};
```

#### 1.2 Update Songs by Artist Endpoint
**File:** `src/controllers/song.controller.ts`

**Current:**
```typescript
GET /api/v1/songs/artist/:artistId
// Only accepts MongoDB ObjectID
```

**Required Change:**
```typescript
GET /api/v1/songs/artist/:identifier
// Should accept EITHER ObjectID OR username

// Similar logic as above:
// 1. Check if identifier is ObjectID
// 2. If yes, use User.findById()
// 3. If no, use User.findOne({ username })
// 4. Then fetch songs with the resolved user._id
```

#### 1.3 Add Username Validation
Ensure usernames are:
- Unique (already enforced in schema)
- URL-safe (lowercase, alphanumeric, underscores, hyphens only)
- Add validation middleware if not present

---

### Phase 2: Frontend Changes (dynamic_artist_monetization)

#### 2.1 Update Artist Ranking Card
**File:** `lib/features/rising_stars/widgets/artist_ranking_card.dart`

**Change:**
```dart
onTap: () {
  // Use username instead of ID
  context.go('/profile/${artist.username}');
},
```

#### 2.2 Update Route Configuration (Optional)
**File:** `lib/core/router/app_router.dart`

Consider renaming parameter for clarity:
```dart
GoRoute(
  path: '/profile/:username',  // Changed from :userId
  name: 'user-profile',
  pageBuilder: (context, state) {
    final username = state.pathParameters['username']!;
    return NoTransitionPage(
      key: state.pageKey,
      child: UserProfileScreen(userId: username),  // Pass username, backend handles it
    );
  },
),
```

#### 2.3 Update Provider (No Change Needed)
**File:** `lib/features/profile/providers/public_user_profile_provider.dart`

The provider already passes the identifier to the API:
```dart
final artist = await apiService.getArtistProfile(userId);
```

Since backend will now accept username, this will work without changes.

#### 2.4 Update Songs Provider (No Change Needed)
**File:** Already fixed to use `/songs/artist/$userId`

Backend will handle username lookup, so no frontend changes needed.

---

### Phase 3: Testing

#### 3.1 Backend Tests
1. Test `/users/profile/6982bda1b7a73570da690db9` (ObjectID) - should work
2. Test `/users/profile/dekzblaster2` (username) - should work
3. Test `/users/profile/InvalidUser` (non-existent) - should return 404
4. Test `/songs/artist/dekzblaster2` (username) - should work

#### 3.2 Frontend Tests
1. Navigate from Rising Stars to user profile
2. Verify URL shows `/profile/dekzblaster2`
3. Verify profile loads correctly
4. Verify songs list loads
5. Test direct URL access (paste URL in browser)
6. Test with different usernames (special characters, numbers, etc.)

#### 3.3 Edge Cases
- Username with uppercase (should be case-insensitive)
- Username that looks like ObjectID
- User changes username (old URLs break - need redirect strategy?)

---

### Phase 4: Deployment

#### 4.1 Backend Deployment
```bash
cd api_dynamic_artist_monetization
# Make changes to controllers
npm run build
pm2 restart artist-api-dev
```

#### 4.2 Frontend Deployment
```bash
cd dynamic_artist_monetization
# Update artist_ranking_card.dart
./deploy.sh
```

#### 4.3 Verification
- Test on production: https://artistmonetization.xyz/profile/dekzblaster2
- Check browser console for errors
- Test navigation flow

---

## Priority Implementation Order

1. **CRITICAL:** Backend - Update `/users/profile/:identifier` endpoint
2. **CRITICAL:** Backend - Update `/songs/artist/:identifier` endpoint  
3. **HIGH:** Frontend - Change `artist_ranking_card.dart` to use username
4. **MEDIUM:** Testing on staging/dev environment
5. **LOW:** Update route parameter name for clarity

---

## Estimated Time
- Backend changes: **30-45 minutes**
- Frontend changes: **5 minutes**
- Testing: **15-20 minutes**
- **Total: ~1 hour**

---

## Risks & Considerations

### Security
- Username enumeration (attackers can discover valid usernames)
- Mitigation: Already public info, not a major concern

### Performance
- Username lookup slightly slower than ObjectID lookup
- Mitigation: Add database index on username field (likely already exists)

### Breaking Changes
- Existing shared links with ObjectID will still work (backward compatible)
- Frontend updated to generate username URLs going forward

### Future Enhancement
- Consider slug-based URLs: `/profile/dekzblaster2-artist-name`
- Add username history/redirects if users can change usernames

---

## Backend Code Example

```typescript
// src/controllers/user.controller.ts
import mongoose from 'mongoose';

export const getUserProfile = async (req: Request, res: Response) => {
  try {
    const { identifier } = req.params;
    
    // Try to find user by ID or username
    let user;
    
    if (mongoose.Types.ObjectId.isValid(identifier) && identifier.length === 24) {
      // It's a valid ObjectID format, try ID lookup first
      user = await User.findById(identifier);
    }
    
    // If not found by ID, try username lookup
    if (!user) {
      user = await User.findOne({ 
        username: new RegExp(`^${identifier}$`, 'i') 
      });
    }
    
    if (!user) {
      return res.status(404).json({ 
        success: false, 
        message: 'User not found' 
      });
    }
    
    // Get user stats
    const stats = await getUserStats(user._id);
    
    return res.status(200).json({
      success: true,
      data: {
        user: user.toObject(),
        stats
      }
    });
  } catch (error) {
    console.error('Error fetching user profile:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Internal server error' 
    });
  }
};
```

---

## Next Steps

1. **YOU:** Review this plan
2. **ME:** Implement backend changes in api_dynamic_artist_monetization
3. **ME:** Update frontend to use username
4. **YOU:** Test on dev/staging
5. **ME:** Deploy to production
6. **YOU:** Verify and test live

---

## Questions to Resolve

1. Do usernames have validation rules already? (alphanumeric + underscore?)
2. Can users change their username? (affects URL persistence)
3. Is there a database index on username field?
4. Should we support old ObjectID URLs indefinitely?
