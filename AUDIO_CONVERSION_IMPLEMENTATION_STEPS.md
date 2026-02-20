# Audio Conversion & Download - Step-by-Step Implementation Plan

**Date:** February 20, 2026  
**Approach:** Incremental, test-driven, zero-downtime deployment  
**Priority:** Code quality, modularity, backward compatibility

---

## 🎯 Implementation Philosophy

- ✅ One feature at a time
- ✅ Test after each step
- ✅ Commit frequently
- ✅ Backward compatible (don't break existing uploads/playback)
- ✅ Modular code (single responsibility principle)
- ✅ Type-safe (TypeScript + Dart)

---

## 📦 PHASE 1: Backend Foundation (Days 1-2)

### **Step 1.1: Install FFmpeg Dependencies**
**Time:** 15 minutes  
**Risk:** Low

```bash
# Backend dependencies
cd api_dynamic_artist_monetization
npm install fluent-ffmpeg @types/fluent-ffmpeg
npm install ffmpeg-static  # Bundled FFmpeg binary
```

**Verify FFmpeg installation:**
```bash
npm run dev
# Should start without errors
```

**Commit:** `chore: Add FFmpeg dependencies for audio conversion`

---

### **Step 1.2: Create Audio Conversion Service (Modular)**
**Time:** 1 hour  
**Risk:** Low (isolated module)

**File:** `src/services/audio-converter.service.ts`

**Features:**
- Convert any format → MP3 320kbps
- Progress tracking
- Error handling
- Cleanup temp files

**Tests to run:**
- Convert WAV → MP3
- Convert FLAC → MP3
- Handle invalid files gracefully

**Commit:** `feat: Add audio conversion service with FFmpeg`

---

### **Step 1.3: Update Song Model (Backward Compatible)**
**Time:** 30 minutes  
**Risk:** Medium (database schema)

**File:** `src/models/Song.model.ts`

**Changes:**
- Add optional fields (don't break existing data)
- All new fields have defaults
- Existing songs work without migration

**New fields (all optional):**
```typescript
originalAudioUrl?: string;
originalFormat?: string;
originalFileSize?: number;
downloadEnabled?: boolean;
downloadCount?: number;
downloadFormats?: string[];
```

**Test:**
- Existing songs still load
- New uploads save correctly

**Commit:** `feat: Extend Song model with audio format fields (backward compatible)`

---

### **Step 1.4: Create Database Migration Script**
**Time:** 30 minutes  
**Risk:** Low (optional field migration)

**File:** `src/scripts/migrate-song-audio-fields.ts`

**Features:**
- Add defaults to existing songs
- Safe to run multiple times (idempotent)
- Dry-run mode for testing

**Test:**
- Run in dry-run mode
- Verify no data loss
- Run actual migration

**Commit:** `chore: Add migration script for Song audio fields`

---

## 📦 PHASE 2: Upload with Conversion (Days 2-3)

### **Step 2.1: Refactor Upload Middleware (Separate Concerns)**
**Time:** 1 hour  
**Risk:** Medium (touch existing upload)

**Current:** `src/middleware/upload.middleware.ts`  
**Goal:** Extract R2 upload logic, keep upload validation separate

**New structure:**
```
src/middleware/
  ├── upload.middleware.ts      (Multer config, validation only)
  └── r2-upload.service.ts      (R2 upload logic - extracted)

src/services/
  └── audio-converter.service.ts (FFmpeg conversion)
```

**Refactor:**
- Move `uploadAudioToR2()` → `r2-upload.service.ts`
- Keep backward compatibility
- Add tests for each function

**Test:**
- Existing uploads still work
- No breaking changes

**Commit:** `refactor: Extract R2 upload logic into dedicated service`

---

### **Step 2.2: Create R2 Storage Manager (Organized Paths)**
**Time:** 1 hour  
**Risk:** Low (new functionality)

**File:** `src/services/r2-storage-manager.service.ts`

**Features:**
- Generate organized paths: `audio/streaming/2026/02/song-123.mp3`
- Handle both streaming and original folders
- File naming conventions
- Cleanup utilities

**Methods:**
```typescript
generateStreamingPath(songId: string, format: string): string
generateOriginalPath(songId: string, format: string): string
uploadStreaming(buffer: Buffer, songId: string): Promise<string>
uploadOriginal(buffer: Buffer, songId: string, format: string): Promise<string>
deleteFile(url: string): Promise<void>
```

**Test:**
- Path generation correct
- Upload to correct folders
- Delete works

**Commit:** `feat: Add R2 storage manager with organized folder structure`

---

### **Step 2.3: Update Upload Controller (Add Conversion)**
**Time:** 2 hours  
**Risk:** High (core upload flow)

**File:** `src/controllers/song.controller.ts`

**Changes:**
1. Accept original file (any format)
2. Convert to MP3 320kbps using converter service
3. Upload MP3 to `audio/streaming/`
4. Upload original to `audio/original/` (optional)
5. Save both URLs in database
6. Return response with both formats

**Process flow:**
```
User uploads WAV file (30MB)
  ↓
Validate & save to temp
  ↓
Convert WAV → MP3 (7MB) [async]
  ↓
Upload MP3 to R2 streaming folder
  ↓
Upload WAV to R2 original folder (parallel)
  ↓
Save song with both URLs
  ↓
Cleanup temp files
  ↓
Return success response
```

**Feature flags:**
```typescript
const ENABLE_AUTO_CONVERSION = true;    // Can disable if issues
const PRESERVE_ORIGINALS = true;        // Save original files?
```

**Test extensively:**
- Upload MP3 (no conversion needed)
- Upload WAV (conversion needed)
- Upload FLAC (conversion needed)
- Upload invalid file (should fail gracefully)
- Test with existing Flutter app (backward compatible)

**Commit:** `feat: Add automatic audio conversion to upload flow`

---

## 📦 PHASE 3: Download Functionality (Days 3-4)

### **Step 3.1: Create Download Service**
**Time:** 1 hour  
**Risk:** Low (new service)

**File:** `src/services/download.service.ts`

**Features:**
- Generate download URLs
- Track download history
- Check user permissions (tier-based)
- Rate limiting checks
- Analytics tracking

**Methods:**
```typescript
canUserDownload(userId: string, format: string): Promise<boolean>
generateDownloadUrl(songId: string, format: string): Promise<string>
trackDownload(userId: string, songId: string, format: string): Promise<void>
getDownloadHistory(userId: string): Promise<DownloadHistory[]>
checkRateLimit(userId: string): Promise<boolean>
```

**Commit:** `feat: Add download service with permission checks`

---

### **Step 3.2: Create Download History Model**
**Time:** 30 minutes  
**Risk:** Low (new collection)

**File:** `src/models/DownloadHistory.model.ts`

**Schema:**
```typescript
{
  userId: ObjectId,
  songId: ObjectId,
  format: 'mp3' | 'wav',
  fileSize: number,
  downloadedAt: Date,
  success: boolean
}
```

**Indexes:**
```typescript
{ userId: 1, downloadedAt: -1 }
{ songId: 1 }
```

**Commit:** `feat: Add DownloadHistory model and indexes`

---

### **Step 3.3: Add Download API Endpoints**
**Time:** 2 hours  
**Risk:** Medium (new routes)

**File:** `src/routes/song.routes.ts`

**New routes:**
```typescript
// Download song in specified format
router.get('/songs/:id/download', authMiddleware, downloadSong);

// Get download history
router.get('/downloads/history', authMiddleware, getDownloadHistory);

// Get download stats
router.get('/downloads/stats', authMiddleware, getDownloadStats);
```

**Controller:** `src/controllers/download.controller.ts`

**Features:**
- Format validation (mp3 or wav)
- Permission checks (premium for wav)
- Rate limiting (10/day for free users)
- Stream file from R2
- Track download in history
- Proper headers (Content-Disposition, etc.)

**Test:**
- Download MP3 as free user ✓
- Download WAV as free user ✗ (403)
- Download WAV as premium ✓
- Rate limit works
- Download history saved

**Commit:** `feat: Add download endpoints with tier-based access control`

---

## 📦 PHASE 4: Frontend Download UI (Days 4-5)

### **Step 4.1: Add Flutter Dependencies**
**Time:** 10 minutes  
**Risk:** Low

**File:** `pubspec.yaml`

```yaml
dependencies:
  permission_handler: ^11.3.1
```

**Test:**
```bash
cd dynamic_artist_monetization
flutter pub get
# Should install without conflicts
```

**Commit:** `chore: Add permission_handler for download feature`

---

### **Step 4.2: Create Download Service (Flutter)**
**Time:** 2 hours  
**Risk:** Low (new service)

**File:** `lib/features/player/services/download_service.dart`

**Features:**
- Download songs using Dio
- Progress tracking
- Save to device storage
- Handle permissions (Android)
- Web download (trigger browser download)
- Error handling

**Methods:**
```dart
Future<void> downloadSong(String songId, String format);
Stream<DownloadProgress> downloadWithProgress(String songId, String format);
Future<List<DownloadHistoryItem>> getDownloadHistory();
Future<bool> checkPermissions();
Future<String> getDownloadPath();
```

**Platform-specific:**
- Android: Request storage permission
- iOS: Save to app documents
- Web: Trigger browser download
- Desktop: Save to downloads folder

**Commit:** `feat: Add download service with cross-platform support`

---

### **Step 4.3: Create Download Progress Provider**
**Time:** 1 hour  
**Risk:** Low

**File:** `lib/features/player/providers/download_provider.dart`

**State management:**
```dart
class DownloadState {
  final Map<String, DownloadProgress> activeDownloads;
  final List<DownloadHistoryItem> history;
  final bool hasPermission;
}
```

**Providers:**
```dart
final downloadProvider = StateNotifierProvider<DownloadNotifier, DownloadState>
final activeDownloadsProvider = Provider // Currently downloading songs
final downloadHistoryProvider = FutureProvider // Past downloads
```

**Commit:** `feat: Add download state management with Riverpod`

---

### **Step 4.4: Update Song Model (Flutter)**
**Time:** 30 minutes  
**Risk:** Low (add fields)

**File:** `lib/features/player/models/song_model.dart`

**Add fields:**
```dart
final String? originalAudioUrl;
final String? originalFormat;
final List<String> downloadFormats;
final bool downloadEnabled;
final bool premiumDownloadOnly;
```

**Backward compatible:**
- All fields optional
- Defaults provided
- Existing songs work

**Commit:** `feat: Extend SongModel with download metadata`

---

### **Step 4.5: Create Download Dialog**
**Time:** 1 hour  
**Risk:** Low (UI only)

**File:** `lib/features/player/widgets/download_dialog.dart`

**Features:**
- Show available formats (MP3, WAV)
- Show file sizes
- Premium badge for WAV
- Download progress bar
- Success/error states

**UI:**
```
┌─────────────────────────────┐
│   Download Song             │
├─────────────────────────────┤
│ ○ MP3 Audio (7 MB)         │
│   High quality • All users  │
│                             │
│ ○ WAV Audio (29 MB) 👑     │
│   Lossless • Premium only   │
├─────────────────────────────┤
│ [Cancel]  [Download]        │
└─────────────────────────────┘
```

**Commit:** `feat: Add download format selection dialog`

---

## 📦 PHASE 5: Desktop Mini Player (Days 5-6)

### **Step 5.1: Create Desktop Mini Player Component**
**Time:** 2 hours  
**Risk:** Low (extend existing)

**File:** `lib/features/player/widgets/desktop_mini_player.dart`

**New component (separate from mobile mini player):**
- Wider layout for desktop
- More action buttons
- Volume slider
- Better spacing

**Layout:**
```
[Album] [Title/Artist] [♥] [+] [↓] [⏮] [⏯] [⏭] [🔊━━━━] [⋯]
```

**Actions:**
1. ♥ Like/Favorite
2. + Add to Playlist
3. ↓ Download
4. ⏮ Previous
5. ⏯ Play/Pause
6. ⏭ Next
7. 🔊 Volume slider
8. ⋯ More options

**Commit:** `feat: Add desktop mini player with extended controls`

---

### **Step 5.2: Detect Desktop Platform**
**Time:** 30 minutes  
**Risk:** Low

**Update:** `lib/features/home/widgets/desktop_layout.dart`

**Logic:**
```dart
Widget build(BuildContext context, WidgetRef ref) {
  final isDesktop = Responsive.isDesktop(context);
  
  return PlayerWrapper(
    child: Scaffold(
      bottomSheet: currentSong != null && !isPlayerExpanded
          ? isDesktop 
              ? const DesktopMiniPlayer()  // NEW
              : const MiniPlayer()          // Existing
          : null,
    ),
  );
}
```

**Commit:** `feat: Show desktop mini player on large screens`

---

### **Step 5.3: Add Volume Control**
**Time:** 1 hour  
**Risk:** Low

**Features:**
- Volume slider (0-100%)
- Mute button
- Volume indicator icon
- Persist volume preference

**Provider:** `lib/features/player/providers/volume_provider.dart`

**Commit:** `feat: Add volume control to desktop mini player`

---

### **Step 5.4: Add Download Button to Mini Player**
**Time:** 1 hour  
**Risk:** Low

**Features:**
- Download icon button
- Shows format selection dialog
- Progress indicator on active download
- Success/error feedback

**Integration:**
- Uses download service
- Shows download dialog
- Tracks progress
- Updates UI on completion

**Commit:** `feat: Add download button to desktop mini player`

---

## 📦 PHASE 6: Testing & Polish (Day 6-7)

### **Step 6.1: Manual Testing Checklist**

**Upload Testing:**
- [ ] Upload MP3 (should skip conversion)
- [ ] Upload WAV (should convert to MP3)
- [ ] Upload FLAC (should convert to MP3)
- [ ] Upload M4A (should convert to MP3)
- [ ] Upload invalid file (should reject)
- [ ] Check both URLs saved correctly
- [ ] Verify files in correct R2 folders
- [ ] Test with mobile Flutter app
- [ ] Test with web Flutter app
- [ ] Test with desktop Flutter app

**Download Testing:**
- [ ] Download MP3 as free user
- [ ] Download WAV as free user (should block)
- [ ] Download WAV as premium user
- [ ] Download same song twice (check history)
- [ ] Exceed rate limit (should block)
- [ ] Download on Android (permissions)
- [ ] Download on iOS
- [ ] Download on Web (browser download)
- [ ] Download on Desktop
- [ ] Check file saved correctly
- [ ] Verify playback of downloaded file

**Mini Player Testing:**
- [ ] Desktop mini player shows on >900px
- [ ] Mobile mini player shows on <900px
- [ ] Volume slider works
- [ ] Like button works
- [ ] Download button shows dialog
- [ ] Download progress shows
- [ ] All buttons responsive
- [ ] Gradient styles consistent

**Performance Testing:**
- [ ] Conversion time: WAV → MP3 <30s
- [ ] Upload time reasonable
- [ ] Download speed good
- [ ] No memory leaks
- [ ] Temp files cleaned up
- [ ] R2 costs acceptable

---

### **Step 6.2: Error Scenarios**

Test all failure modes:
- [ ] FFmpeg not installed
- [ ] R2 upload fails
- [ ] Conversion fails
- [ ] Invalid audio file
- [ ] Corrupted file
- [ ] Network timeout
- [ ] Permission denied
- [ ] Rate limit exceeded
- [ ] Disk space full
- [ ] Concurrent downloads

---

### **Step 6.3: Code Quality Review**

- [ ] All TypeScript types correct
- [ ] All Dart types correct
- [ ] No `any` types
- [ ] Error handling comprehensive
- [ ] Logging sufficient
- [ ] No console.log (use logger)
- [ ] Comments where needed
- [ ] Function names descriptive
- [ ] File organization logical
- [ ] No duplicate code
- [ ] Constants extracted
- [ ] Environment variables used

---

### **Step 6.4: Documentation**

Create/update:
- [ ] API endpoint documentation
- [ ] Environment variables list
- [ ] Setup instructions (FFmpeg)
- [ ] Migration guide
- [ ] User guide (how to download)
- [ ] Troubleshooting guide

---

## 📊 Rollout Plan

### **Staging Deployment (Day 7)**
1. Deploy backend to staging
2. Run migrations
3. Test all features
4. Fix any issues
5. Performance monitoring

### **Production Deployment (Day 8)**
1. Deploy backend (zero-downtime)
2. Run migrations (safe - backward compatible)
3. Monitor error rates
4. Deploy Flutter web
5. Monitor downloads
6. Gradual rollout (feature flag if needed)

### **Monitoring (Ongoing)**
- Conversion success rate
- Download success rate
- R2 storage growth
- API latency
- Error rates
- User adoption

---

## 🔄 Rollback Plan

If critical issues:

**Backend:**
1. Disable auto-conversion (feature flag)
2. Revert to old upload flow
3. Keep new endpoints (safe, just unused)

**Frontend:**
1. Hide download buttons
2. Keep services (safe, just unused)

**Database:**
- No rollback needed (backward compatible)
- New fields optional

---

## 📝 Commit Strategy

Small, atomic commits:
- Each step = 1 commit
- Clear commit messages
- Reference issue numbers
- Tag major milestones

**Example commits:**
```
chore: Add FFmpeg dependencies
feat: Add audio conversion service
feat: Extend Song model with audio fields
refactor: Extract R2 upload into service
feat: Add auto-conversion to upload flow
feat: Add download endpoints
feat: Add download service (Flutter)
feat: Add desktop mini player with volume control
test: Add integration tests for conversion
docs: Update API documentation
```

---

## ✅ Success Criteria

Feature is complete when:
- [ ] All uploads auto-convert to MP3
- [ ] Original files preserved
- [ ] Downloads work on all platforms
- [ ] Desktop mini player functional
- [ ] Rate limiting works
- [ ] Analytics tracking works
- [ ] No regression in existing features
- [ ] Performance acceptable
- [ ] Code quality high
- [ ] Documentation complete

---

## 🚀 Ready to Start?

**First command:**
```bash
cd api_dynamic_artist_monetization
npm install fluent-ffmpeg @types/fluent-ffmpeg ffmpeg-static
```

**First file to create:**
`src/services/audio-converter.service.ts`

Let's proceed step by step! 🎯
