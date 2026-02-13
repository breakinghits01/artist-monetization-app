# Discover More - Dynamic Dashboard Feature Plan

**Date**: February 13, 2026  
**Status**: Planning Phase  
**Goal**: Build a dynamic, real-time "Discover More" section with various card types including challenges, bundles, featured content, and artist recommendations.

---

## 🎯 Feature Overview

The "Discover More" section displays a dynamic masonry grid of various content cards that drive user engagement, monetization, and discovery. All rewards and pricing use **TOKENS ONLY** (no gems).

### Card Types:
1. **🏆 Challenge Cards** - Gamification quests with token rewards
2. **🎵 Featured Playlist Cards** - Trending/popular playlists
3. **👤 Artist Discovery Cards** - Recommended artists to follow
4. **🎁 Bundle Cards** - Purchasable song packs
5. **🎼 Premium Song Cards** - Individual premium songs for sale
6. **🤝 Referral Cards** - Invite friends for token rewards
7. **📚 Story Cards** - User stories/moments
8. **🎲 Daily Spin Cards** - Random reward wheel

---

## 📊 Database Schema

### 1. **Challenge Model** (Already Exists - Update)
```typescript
// MongoDB Collection: challenges
interface Challenge {
  _id: ObjectId;
  userId: ObjectId;                    // User who owns this challenge
  type: 'listen' | 'upload' | 'share' | 'follow' | 'purchase' | 'streak';
  title: string;                       // "Listen to 5 songs"
  description: string;                 // "Discover new music and earn tokens"
  icon: string;                        // "🏆" or icon URL
  
  // Progress tracking
  targetValue: number;                 // e.g., 5 for "listen to 5 songs"
  currentValue: number;                // Current progress (e.g., 3)
  
  // Rewards (TOKENS ONLY - NO GEMS)
  tokenReward: number;                 // e.g., 100 tokens
  
  // Status
  status: 'active' | 'completed' | 'claimed' | 'expired';
  
  // Timing
  startDate: Date;
  expiresAt: Date;                     // Challenge expiry (e.g., 24 hours)
  completedAt?: Date;
  claimedAt?: Date;
  
  // Display
  priority: number;                    // Higher = shown first
  backgroundColor?: string;            // Gradient color 1
  backgroundColorEnd?: string;         // Gradient color 2
  
  createdAt: Date;
  updatedAt: Date;
}

// Indexes
challenges.index({ userId: 1, status: 1 });
challenges.index({ expiresAt: 1 });
challenges.index({ priority: -1 });
```

### 2. **Bundle Model** (NEW)
```typescript
// MongoDB Collection: bundles
interface Bundle {
  _id: ObjectId;
  name: string;                        // "Summer Vibes Pack"
  description: string;
  
  // Content
  songIds: ObjectId[];                 // Array of song references
  songCount: number;                   // Cached count
  
  // Pricing (TOKENS ONLY)
  tokenPrice: number;                  // e.g., 500 tokens
  originalTokenPrice?: number;         // For showing discount
  
  // Display
  coverImage?: string;
  icon?: string;                       // "💎" or icon URL
  tags: string[];                      // ["summer", "pop", "chill"]
  backgroundColor?: string;
  backgroundColorEnd?: string;
  
  // Stats
  purchaseCount: number;
  viewCount: number;
  
  // Status
  isActive: boolean;
  isFeatured: boolean;
  isLimited: boolean;                  // Limited time offer
  expiresAt?: Date;
  
  // Metadata
  createdBy: ObjectId;                 // Admin or artist
  createdAt: Date;
  updatedAt: Date;
}

// Indexes
bundles.index({ isActive: 1, isFeatured: -1 });
bundles.index({ tokenPrice: 1 });
bundles.index({ purchaseCount: -1 });
```

### 3. **Featured Content Model** (NEW)
```typescript
// MongoDB Collection: featured_content
interface FeaturedContent {
  _id: ObjectId;
  type: 'playlist' | 'song' | 'artist' | 'bundle';
  contentId: ObjectId;                 // Reference to actual content
  
  // Display
  title: string;                       // "Hot Hits 2026"
  subtitle?: string;                   // "12K plays today"
  badge?: string;                      // "TRENDING", "NEW", "HOT"
  badgeColor?: string;                 // Badge background color
  
  coverImage: string;
  videoUrl?: string;                   // For animated backgrounds
  gifUrl?: string;
  
  backgroundColor?: string;
  backgroundColorEnd?: string;
  
  // Stats
  stats: {
    plays?: number;
    followers?: number;
    songs?: number;
    views?: number;
  };
  
  // Ranking
  priority: number;                    // Display order (higher first)
  score: number;                       // Algorithm score
  
  // Status
  isActive: boolean;
  
  // Timing
  startDate: Date;
  endDate?: Date;
  
  createdAt: Date;
  updatedAt: Date;
}

// Indexes
featured_content.index({ isActive: 1, priority: -1 });
featured_content.index({ type: 1, score: -1 });
featured_content.index({ endDate: 1 });
```

### 4. **Artist Recommendation Model** (NEW)
```typescript
// MongoDB Collection: artist_recommendations
interface ArtistRecommendation {
  _id: ObjectId;
  userId: ObjectId;                    // User receiving recommendation
  artistId: ObjectId;                  // Recommended artist
  
  // Recommendation reason
  reason: 'similar_genre' | 'trending' | 'new' | 'followed_by_friends' | 'random';
  
  // Display
  title?: string;                      // "Rising Star", "You might like"
  description?: string;
  
  // Stats (cached from artist)
  followerCount: number;
  songCount: number;
  
  // Scoring
  score: number;                       // Algorithm score
  priority: number;
  
  // Status
  isShown: boolean;                    // Has user seen this?
  isDismissed: boolean;                // User dismissed the card
  didFollow: boolean;                  // User followed from this card
  
  createdAt: Date;
  updatedAt: Date;
}

// Indexes
artist_recommendations.index({ userId: 1, isShown: 1 });
artist_recommendations.index({ userId: 1, score: -1 });
```

### 5. **Referral Model** (NEW)
```typescript
// MongoDB Collection: referrals
interface Referral {
  _id: ObjectId;
  referrerId: ObjectId;                // User who referred
  referredUserId?: ObjectId;           // User who signed up (null if pending)
  
  referralCode: string;                // Unique code
  
  // Rewards (TOKENS ONLY)
  tokenReward: number;                 // e.g., 100 tokens
  referrerTokenReward: number;         // Referrer gets this
  referredTokenReward: number;         // New user gets this
  
  // Status
  status: 'pending' | 'completed' | 'claimed';
  
  // Tracking
  clickCount: number;
  signupCompletedAt?: Date;
  rewardClaimedAt?: Date;
  
  createdAt: Date;
  updatedAt: Date;
}

// Indexes
referrals.index({ referrerId: 1, status: 1 });
referrals.index({ referralCode: 1 }, { unique: true });
```

### 6. **Daily Spin Model** (NEW)
```typescript
// MongoDB Collection: daily_spins
interface DailySpin {
  _id: ObjectId;
  userId: ObjectId;
  
  // Available spins
  spinsAvailable: number;              // Daily reset
  spinsUsed: number;
  lastSpinAt?: Date;
  lastResetAt: Date;                   // Last daily reset
  
  // History
  spinHistory: Array<{
    timestamp: Date;
    reward: {
      type: 'tokens' | 'song_credit' | 'bundle';
      amount?: number;
      itemId?: ObjectId;
    };
  }>;
  
  createdAt: Date;
  updatedAt: Date;
}

// Indexes
daily_spins.index({ userId: 1 }, { unique: true });
daily_spins.index({ lastResetAt: 1 });
```

### 7. **Purchase Model** (Already Exists - Extend)
```typescript
// MongoDB Collection: purchases
interface Purchase {
  _id: ObjectId;
  userId: ObjectId;
  
  // What was purchased
  itemType: 'song' | 'bundle' | 'bundle_pack';
  itemId: ObjectId;
  
  // Payment (TOKENS ONLY)
  tokenAmount: number;
  
  // Status
  status: 'completed' | 'failed' | 'refunded';
  
  // Metadata
  purchasedAt: Date;
  createdAt: Date;
}

// Indexes
purchases.index({ userId: 1, purchasedAt: -1 });
purchases.index({ itemType: 1, itemId: 1 });
```

### 8. **Dashboard Card Settings** (NEW)
```typescript
// MongoDB Collection: dashboard_settings
interface DashboardSettings {
  _id: ObjectId;
  
  // Card type configuration
  cardTypes: Array<{
    type: 'challenge' | 'featured' | 'artist' | 'bundle' | 'referral' | 'spin';
    enabled: boolean;
    maxCards: number;                  // Max cards to show
    refreshInterval: number;           // Minutes
    priority: number;                  // Display priority
  }>;
  
  // Refresh settings
  globalRefreshInterval: number;       // Minutes
  
  // A/B testing
  experiments: Array<{
    name: string;
    enabled: boolean;
    variants: string[];
  }>;
  
  updatedAt: Date;
}

// Single document for global settings
```

---

## 🎨 Card Display Logic

### Priority Algorithm
```typescript
function calculateCardPriority(card: any, userId: ObjectId): number {
  let score = card.basePriority || 0;
  
  // Boost trending content
  if (card.badge === 'TRENDING') score += 20;
  
  // Boost content about to expire
  if (card.expiresAt) {
    const hoursLeft = (card.expiresAt - Date.now()) / (1000 * 60 * 60);
    if (hoursLeft < 6) score += 15;
  }
  
  // Boost incomplete challenges
  if (card.type === 'challenge' && card.currentValue > 0) {
    score += 10 * (card.currentValue / card.targetValue);
  }
  
  // Boost personalized recommendations
  if (card.reason === 'similar_genre') score += 10;
  
  // Decrease score for dismissed content
  if (card.isDismissed) score -= 50;
  
  return score;
}
```

### Card Mix Strategy
```typescript
interface CardMixRules {
  challenges: { min: 1, max: 3 },
  featured: { min: 1, max: 2 },
  artists: { min: 0, max: 2 },
  bundles: { min: 0, max: 2 },
  referral: { min: 0, max: 1 },
  spin: { min: 0, max: 1 }
}
```

---

## 🔌 API Endpoints

### Backend Routes (Node.js/Express)

```typescript
// Dashboard Cards
GET    /api/v1/dashboard/cards                 // Get mixed dashboard cards
GET    /api/v1/dashboard/cards/refresh         // Force refresh cards
POST   /api/v1/dashboard/cards/:id/dismiss     // Dismiss a card

// Challenges
GET    /api/v1/challenges                      // Get user challenges
GET    /api/v1/challenges/:id                  // Get challenge details
POST   /api/v1/challenges/:id/claim            // Claim challenge reward
PUT    /api/v1/challenges/:id/progress         // Update progress

// Bundles
GET    /api/v1/bundles                         // Get available bundles
GET    /api/v1/bundles/:id                     // Get bundle details
POST   /api/v1/bundles/:id/purchase            // Purchase bundle

// Featured Content
GET    /api/v1/featured                        // Get featured content
GET    /api/v1/featured/:type                  // Get by type

// Artist Recommendations
GET    /api/v1/recommendations/artists         // Get artist recommendations
POST   /api/v1/recommendations/artists/:id/follow  // Follow from recommendation

// Referrals
GET    /api/v1/referrals                       // Get user referral info
POST   /api/v1/referrals/generate              // Generate referral code
POST   /api/v1/referrals/apply                 // Apply referral code

// Daily Spin
GET    /api/v1/spin/status                     // Get spin status
POST   /api/v1/spin/play                       // Play spin (get reward)
```

---

## 📱 Frontend Structure

### Models
```dart
lib/features/dashboard/
├── models/
│   ├── dashboard_card_model.dart           // Base card model
│   ├── challenge_card_model.dart           // Challenge specific
│   ├── featured_card_model.dart            // Featured content
│   ├── artist_card_model.dart              // Artist recommendation
│   ├── bundle_card_model.dart              // Bundle pack
│   ├── referral_card_model.dart            // Referral
│   └── spin_card_model.dart                // Daily spin
```

### Providers (Riverpod)
```dart
lib/features/dashboard/
├── providers/
│   ├── dashboard_cards_provider.dart       // Mixed cards provider
│   ├── challenges_provider.dart            // User challenges
│   ├── bundles_provider.dart               // Available bundles
│   ├── featured_provider.dart              // Featured content
│   ├── recommendations_provider.dart       // Artist recommendations
│   ├── referral_provider.dart              // Referral system
│   └── spin_provider.dart                  // Daily spin
```

### Widgets
```dart
lib/features/dashboard/
├── widgets/
│   ├── dashboard_masonry_grid.dart         // Main grid (exists)
│   ├── challenge_card.dart                 // Challenge card
│   ├── featured_playlist_card.dart         // Featured playlist
│   ├── artist_discovery_card.dart          // Artist card
│   ├── bundle_card.dart                    // Bundle pack card
│   ├── premium_song_card.dart              // Premium song
│   ├── referral_card.dart                  // Refer a friend
│   └── daily_spin_card.dart                // Spin wheel card
```

---

## 🔄 Real-Time Updates

### WebSocket Events (Socket.io)
```typescript
// Client subscribes to events
socket.on('dashboard:challenge-completed', (data) => {
  // Update challenge card state
  // Show celebration animation
  // Update token balance
});

socket.on('dashboard:new-featured', (data) => {
  // Add new featured content card
  // Show "NEW" badge animation
});

socket.on('dashboard:bundle-purchased', (data) => {
  // Update bundle availability
  // Update user's owned bundles
});

socket.on('wallet:tokens-updated', (data) => {
  // Update token balance everywhere
});
```

### Polling Fallback
- Poll `/api/v1/dashboard/cards` every 5 minutes
- Use ETag caching to minimize data transfer
- Pull-to-refresh gesture for manual updates

---

## 🎮 Gamification Rules

### Challenge Auto-Generation
```typescript
// Daily challenges (reset every 24 hours)
const dailyChallenges = [
  { type: 'listen', target: 5, reward: 50 },
  { type: 'share', target: 1, reward: 25 },
  { type: 'follow', target: 2, reward: 30 }
];

// Weekly challenges (reset every Monday)
const weeklyChallenges = [
  { type: 'listen', target: 30, reward: 200 },
  { type: 'upload', target: 1, reward: 150 }
];

// One-time challenges
const specialChallenges = [
  { type: 'complete_profile', target: 1, reward: 100 },
  { type: 'first_purchase', target: 1, reward: 50 }
];
```

### Token Economy Balance
- **Earn Tokens**: Listen (5), Share (25), Upload (50), Complete Challenge (50-200), Referral (100)
- **Spend Tokens**: Premium Songs (50-200), Bundles (300-1000), Tips to Artists (any)
- **Daily Cap**: Max 500 tokens earned per day from listening

---

## 📈 Analytics Tracking

### Events to Track
```typescript
// Card interactions
- dashboard_card_viewed
- dashboard_card_clicked
- dashboard_card_dismissed

// Challenge events
- challenge_started
- challenge_progress_updated
- challenge_completed
- challenge_claimed

// Purchase events
- bundle_viewed
- bundle_purchased
- song_purchased

// Social events
- artist_followed_from_recommendation
- referral_link_shared
- referral_signup_completed
```

---

## 🚀 Implementation Phases

### Phase 1: Foundation (Week 1)
- [x] Challenge model already exists
- [ ] Create Bundle, Featured, Recommendation, Referral models
- [ ] Database migrations and seed data
- [ ] Basic API endpoints for challenges and bundles
- [ ] Update token terminology (remove gems)

### Phase 2: Cards UI (Week 2)
- [ ] Challenge card widget with progress bar
- [ ] Featured playlist card with video/GIF background
- [ ] Artist discovery card with follow button
- [ ] Bundle card with token pricing
- [ ] Referral card with share functionality

### Phase 3: Backend Logic (Week 3)
- [ ] Challenge auto-generation system
- [ ] Featured content algorithm
- [ ] Artist recommendation engine
- [ ] Referral system with unique codes
- [ ] Purchase flow for bundles

### Phase 4: Real-Time (Week 4)
- [ ] WebSocket integration for live updates
- [ ] Push notifications for challenge completion
- [ ] Real-time token balance updates
- [ ] Live featured content rotation

### Phase 5: Polish (Week 5)
- [ ] Animations and transitions
- [ ] Card shimmer loading states
- [ ] Celebration effects on challenge completion
- [ ] Analytics integration
- [ ] A/B testing setup

---

## 🧪 Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Challenge progress calculation
- Token reward calculations
- Card priority algorithm

### Integration Tests
- API endpoint responses
- Database queries performance
- Token transaction flow
- Referral code generation

### E2E Tests
- Complete challenge flow
- Purchase bundle flow
- Follow artist from recommendation
- Referral signup flow

---

## 📋 Migration Notes

### Remove Gems → Use Tokens Only
```typescript
// Old schema (REMOVE)
gems: number;
gemReward: number;
gemPrice: number;

// New schema (USE THIS)
tokens: number;  // Already exists in wallet
tokenReward: number;
tokenPrice: number;
```

### Update Existing Collections
```javascript
// Migration script
db.challenges.updateMany(
  { gemReward: { $exists: true } },
  { 
    $rename: { "gemReward": "tokenReward" },
    $unset: { gems: "" }
  }
);

db.treasure_chests.updateMany(
  { gemsCost: { $exists: true } },
  { 
    $rename: { "gemsCost": "tokensCost" },
    $unset: { gems: "" }
  }
);
```

---

## 🎯 Success Metrics

### Engagement
- Daily Active Users (DAU) increase by 30%
- Average session time increase by 20%
- Challenge completion rate > 60%

### Monetization
- Bundle purchase rate > 5% of active users
- Average revenue per user (ARPU) increase by 25%
- Token circulation velocity

### Retention
- Day 7 retention > 40%
- Day 30 retention > 20%
- Referral conversion rate > 15%

---

## 🔐 Security Considerations

1. **Token Transactions**: Atomic operations with rollback
2. **Challenge Validation**: Server-side verification of progress
3. **Referral Codes**: Rate limiting to prevent abuse
4. **Purchase Verification**: Double-spend prevention
5. **WebSocket Authentication**: JWT tokens for real-time connections

---

## 📝 Next Steps

1. ✅ Review and approve this plan
2. ⏳ Create database migrations
3. ⏳ Implement backend models and routes
4. ⏳ Build frontend card widgets
5. ⏳ Integrate real-time updates
6. ⏳ Test and deploy

---

**Ready for Implementation?** Let me know which phase to start with! 🚀
