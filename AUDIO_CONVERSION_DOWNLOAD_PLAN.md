# Audio Conversion & Download Feature - Implementation Plan

**Date:** February 20, 2026  
**Feature:** Audio format conversion (MP3/WAV) and download system like Suno  
**Status:** Planning Phase

---

## 📋 Overview

Implement a professional audio conversion and download system that:
- Auto-converts all uploads to MP3 320kbps for streaming
- Preserves original format (WAV/FLAC) for high-quality downloads
- Provides download options (MP3 vs WAV) similar to Suno
- Tracks download analytics and usage
- Supports tier-based access (Free: MP3 only, Premium: WAV access)

---

## 🗄️ Database Schema Changes

### **1. Songs Collection (MongoDB) - Updates**

```typescript
interface Song {
  // Existing fields...
  _id: ObjectId;
  title: string;
  artistId: ObjectId;
  genre: string;
  price: number;
  description?: string;
  exclusive: boolean;
  playCount: number;
  createdAt: Date;
  updatedAt: Date;
  
  // ✨ NEW FIELDS - Audio Files
  audioUrl: string;                    // MP3 streaming URL (always available)
  audioFormat: 'mp3';                  // Streaming format (always MP3)
  audioBitrate: number;                // 320 (kbps)
  audioFileSize: number;               // File size in bytes
  
  originalAudioUrl?: string;           // Original upload URL (WAV/FLAC/etc)
  originalFormat?: string;             // 'wav', 'flac', 'm4a', 'ogg', 'aac'
  originalBitrate?: number;            // Original bitrate if applicable
  originalFileSize?: number;           // Original file size in bytes
  
  duration: number;                    // Duration in seconds
  waveformData?: number[];             // Audio waveform for visualization
  
  // ✨ NEW FIELDS - Download Settings
  downloadEnabled: boolean;            // Allow downloads (default: true)
  downloadCount: number;               // Total download count
  downloadFormats: string[];           // ['mp3', 'wav'] - available formats
  premiumDownloadOnly: boolean;        // Require premium for downloads
}
```

**Migration Script:**
```javascript
// migrate-songs-audio-fields.js
db.songs.updateMany(
  {},
  {
    $set: {
      audioFormat: 'mp3',
      audioBitrate: 320,
      downloadEnabled: true,
      downloadCount: 0,
      downloadFormats: ['mp3'],
      premiumDownloadOnly: false
    }
  }
);
```

---

### **2. Download History Collection (NEW)**

Track user download activity for analytics and rate limiting.

```typescript
interface DownloadHistory {
  _id: ObjectId;
  userId: ObjectId;                    // User who downloaded
  songId: ObjectId;                    // Song downloaded
  format: 'mp3' | 'wav' | 'flac';     // Download format
  fileSize: number;                    // Downloaded file size (bytes)
  downloadedAt: Date;                  // Timestamp
  ipAddress?: string;                  // For rate limiting
  userAgent?: string;                  // Device/browser info
  downloadDuration?: number;           // Time to download (ms)
  success: boolean;                    // Download completed?
  errorMessage?: string;               // If failed
}
```

**Indexes:**
```javascript
db.downloadHistory.createIndex({ userId: 1, downloadedAt: -1 });
db.downloadHistory.createIndex({ songId: 1, downloadedAt: -1 });
db.downloadHistory.createIndex({ userId: 1, songId: 1 });
db.downloadHistory.createIndex({ downloadedAt: -1 }); // For cleanup
```

---

### **3. User Preferences Collection - Updates**

```typescript
interface UserPreferences {
  // Existing fields...
  _id: ObjectId;
  userId: ObjectId;
  
  // ✨ NEW FIELDS - Download Preferences
  preferredDownloadFormat: 'mp3' | 'wav';  // Default: 'mp3'
  downloadQuality: '128' | '192' | '320';  // MP3 bitrate (default: '320')
  autoDownloadToLibrary: boolean;          // Auto-save to device
  downloadPath?: string;                   // Custom download location
  downloadNotifications: boolean;          // Notify on completion
  
  // Download limits (prevent abuse)
  dailyDownloadLimit: number;              // Downloads per day (Free: 10, Premium: unlimited)
  monthlyDownloadLimit: number;            // Downloads per month
  
  createdAt: Date;
  updatedAt: Date;
}
```

---

### **4. Conversion Jobs Collection (NEW)**

Track audio conversion status (for async processing).

```typescript
interface ConversionJob {
  _id: ObjectId;
  songId: ObjectId;                    // Song being converted
  artistId: ObjectId;                  // Artist who uploaded
  status: 'pending' | 'processing' | 'completed' | 'failed';
  
  // Input file
  inputUrl: string;                    // Original upload URL
  inputFormat: string;                 // Original format
  inputFileSize: number;               // Original size
  
  // Output files
  mp3Url?: string;                     // Converted MP3 URL
  mp3FileSize?: number;                // MP3 size
  
  // Conversion metadata
  startedAt?: Date;                    // When conversion started
  completedAt?: Date;                  // When conversion finished
  processingDuration?: number;         // Time taken (seconds)
  errorMessage?: string;               // If failed
  retryCount: number;                  // Retry attempts
  
  createdAt: Date;
  updatedAt: Date;
}
```

**Indexes:**
```javascript
db.conversionJobs.createIndex({ status: 1, createdAt: -1 });
db.conversionJobs.createIndex({ songId: 1 });
```

---

## 📦 R2 Storage Structure

### **Current Structure:**
```
r2://your-bucket/
├── audio/
│   └── song-12345-timestamp.mp3  (mixed formats, no organization)
```

### **✨ NEW Structure:**
```
r2://your-bucket/
├── audio/
│   ├── streaming/                    # MP3 files for playback (320kbps)
│   │   ├── 2026/02/                 # Organized by date
│   │   │   ├── song-12345.mp3       # Converted streaming files
│   │   │   └── song-12346.mp3
│   │   └── cache/                   # Temporary processing files
│   │
│   ├── original/                    # Original uploads (WAV/FLAC/etc)
│   │   ├── 2026/02/
│   │   │   ├── song-12345.wav       # Preserved originals
│   │   │   └── song-12346.flac
│   │   └── archive/                 # Old originals (>1 year)
│   │
│   └── temp/                        # Temporary conversion files
│       └── job-67890.tmp            # Deleted after conversion
```

**File Naming Convention:**
```
Streaming: audio/streaming/YYYY/MM/song-{songId}-{timestamp}.mp3
Original:  audio/original/YYYY/MM/song-{songId}-{timestamp}.{format}
```

---

## 🌐 API Endpoints

### **1. Upload with Conversion**

**POST `/api/v1/songs/upload`**

**Request (multipart/form-data):**
```typescript
{
  audio: File,              // Audio file (any supported format)
  title: string,
  genre: string,
  price: number,
  description?: string,
  exclusive: boolean,
  preserveOriginal: boolean  // Keep original format? (default: true)
}
```

**Response:**
```typescript
{
  success: true,
  data: {
    song: {
      id: string,
      title: string,
      audioUrl: string,           // MP3 streaming URL
      originalAudioUrl: string,   // Original format URL (if preserved)
      audioFormat: 'mp3',
      originalFormat: 'wav',
      audioFileSize: 7340032,     // 7MB
      originalFileSize: 30408704, // 29MB
      duration: 180,              // seconds
      conversionStatus: 'completed'
    }
  }
}
```

---

### **2. Download Endpoint**

**GET `/api/v1/songs/:songId/download?format=mp3|wav`**

**Query Parameters:**
- `format`: 'mp3' | 'wav' (default: 'mp3')

**Headers:**
```
Authorization: Bearer {token}  // Required for premium formats
```

**Response:**
- Status: 200
- Headers:
  ```
  Content-Type: audio/mpeg (or audio/wav)
  Content-Disposition: attachment; filename="song-title.mp3"
  Content-Length: 7340032
  X-Download-Format: mp3
  X-Original-Format: wav
  ```
- Body: File stream

**Error Responses:**
```typescript
// 403 - Premium required for WAV
{
  success: false,
  error: 'Premium subscription required for high-quality downloads',
  upgradeUrl: '/premium'
}

// 429 - Rate limit exceeded
{
  success: false,
  error: 'Daily download limit reached (10/10)',
  resetAt: '2026-02-21T00:00:00Z'
}

// 404 - Format not available
{
  success: false,
  error: 'WAV format not available for this song'
}
```

---

### **3. Download History**

**GET `/api/v1/downloads/history?page=1&limit=20`**

**Response:**
```typescript
{
  success: true,
  data: {
    downloads: [
      {
        id: string,
        song: {
          id: string,
          title: string,
          artist: string,
          albumArt: string
        },
        format: 'mp3',
        fileSize: 7340032,
        downloadedAt: '2026-02-20T10:30:00Z'
      }
    ],
    pagination: {
      currentPage: 1,
      totalPages: 5,
      total: 87,
      limit: 20
    },
    stats: {
      totalDownloads: 87,
      totalSize: 640000000,  // bytes
      downloadLimitRemaining: 3  // downloads left today
    }
  }
}
```

---

### **4. Conversion Status**

**GET `/api/v1/songs/:songId/conversion-status`**

**Response:**
```typescript
{
  success: true,
  data: {
    status: 'completed',      // pending | processing | completed | failed
    mp3Available: true,
    wavAvailable: true,
    progress: 100,            // percentage
    estimatedTimeRemaining: 0 // seconds
  }
}
```

---

## 🎨 Frontend Data Models (Flutter)

### **Updated Song Model**

```dart
class SongModel {
  final String id;
  final String title;
  final String artist;
  final String? albumArt;
  
  // Audio URLs
  final String audioUrl;              // MP3 streaming (always available)
  final String? originalAudioUrl;     // Original format (WAV/FLAC)
  
  // Audio metadata
  final String audioFormat;           // 'mp3'
  final String? originalFormat;       // 'wav', 'flac', etc.
  final int audioFileSize;            // bytes
  final int? originalFileSize;        // bytes
  final int duration;                 // seconds
  
  // Download settings
  final bool downloadEnabled;
  final List<String> downloadFormats; // ['mp3', 'wav']
  final bool premiumDownloadOnly;
  final int downloadCount;
  
  // Other fields...
  final String genre;
  final double price;
  final bool exclusive;
  final int playCount;
}
```

---

### **Download History Model**

```dart
class DownloadHistoryItem {
  final String id;
  final SongModel song;
  final String format;              // 'mp3' | 'wav'
  final int fileSize;               // bytes
  final DateTime downloadedAt;
  final bool success;
}
```

---

### **Download Progress Model**

```dart
class DownloadProgress {
  final String songId;
  final String format;
  final int totalBytes;
  final int receivedBytes;
  final double progress;            // 0.0 to 1.0
  final DownloadStatus status;      // downloading | completed | failed
  final String? filePath;           // Local file path when complete
  final String? error;
}

enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  cancelled
}
```

---

## 🔐 Access Control & Rate Limiting

### **Download Limits by User Tier**

```typescript
const DOWNLOAD_LIMITS = {
  free: {
    dailyLimit: 10,
    monthlyLimit: 50,
    allowedFormats: ['mp3'],
    maxConcurrentDownloads: 1
  },
  premium: {
    dailyLimit: -1,        // unlimited
    monthlyLimit: -1,      // unlimited
    allowedFormats: ['mp3', 'wav'],
    maxConcurrentDownloads: 3
  },
  artist: {
    dailyLimit: -1,        // unlimited
    monthlyLimit: -1,      // unlimited
    allowedFormats: ['mp3', 'wav'],
    maxConcurrentDownloads: 5,
    canDownloadOwnOriginals: true  // Download original uploads
  }
};
```

### **Rate Limiting Strategy**

```typescript
// Redis-based rate limiting
const RATE_LIMITS = {
  downloadPerMinute: 5,      // Max 5 downloads per minute
  downloadPerHour: 20,       // Max 20 downloads per hour
  downloadPerDay: 50,        // Max 50 downloads per day (free tier)
  bandwidthPerDay: 1GB       // Max 1GB bandwidth per day (free tier)
};
```

---

## 📊 Analytics & Tracking

### **Download Analytics Dashboard**

Track these metrics:
- Total downloads (by format)
- Most downloaded songs
- Download bandwidth usage
- Format preferences (MP3 vs WAV ratio)
- Download success/failure rate
- Average download speed
- Peak download hours

### **Artist Analytics**

Artists can see:
- Download count per song
- Format breakdown (% MP3 vs % WAV)
- Download trends over time
- Geographic distribution
- Revenue from downloads (if applicable)

---

## 🛠️ Technical Implementation Stack

### **Backend (Node.js/Express)**

```json
{
  "dependencies": {
    "fluent-ffmpeg": "^2.1.2",        // Audio conversion
    "@types/fluent-ffmpeg": "^2.1.24",
    "ffmpeg-static": "^5.2.0",        // FFmpeg binary
    "stream-throttle": "^0.1.3",      // Bandwidth limiting
    "archiver": "^7.0.0"              // For ZIP downloads
  }
}
```

### **Frontend (Flutter)**

```yaml
dependencies:
  dio: ^5.4.3+1                       # Already installed (downloads)
  path_provider: ^2.1.3               # Already installed (paths)
  permission_handler: ^11.3.1         # NEW - Storage permissions
```

---

## 🚀 Implementation Phases

### **Phase 1: Database & Schema (Week 1)**
- [ ] Create migration scripts for Song model
- [ ] Create DownloadHistory collection
- [ ] Create ConversionJobs collection
- [ ] Update User preferences
- [ ] Set up database indexes
- [ ] Test migrations on staging

### **Phase 2: Backend Conversion (Week 1-2)**
- [ ] Install FFmpeg dependencies
- [ ] Create audio conversion service
- [ ] Update upload endpoint (auto-convert to MP3)
- [ ] Implement R2 storage organization
- [ ] Create conversion job queue
- [ ] Add conversion status endpoint

### **Phase 3: Download API (Week 2)**
- [ ] Create download endpoint with format selection
- [ ] Implement rate limiting (Redis)
- [ ] Add tier-based access control
- [ ] Track download history
- [ ] Implement bandwidth throttling
- [ ] Add download analytics

### **Phase 4: Frontend Download UI (Week 2-3)**
- [ ] Add permission_handler package
- [ ] Create download service (Dio-based)
- [ ] Add download button to mini player
- [ ] Add format selection dialog
- [ ] Implement download progress tracking
- [ ] Add download history screen
- [ ] Show download notifications

### **Phase 5: Desktop Mini Player Enhancement (Week 3)**
- [ ] Add volume control slider
- [ ] Add like/favorite button
- [ ] Add download button with menu
- [ ] Add "Add to Playlist" button
- [ ] Add more options menu
- [ ] Responsive layout adjustments

### **Phase 6: Testing & Optimization (Week 3-4)**
- [ ] Load testing (concurrent downloads)
- [ ] Conversion performance testing
- [ ] Storage cost analysis
- [ ] Rate limiting validation
- [ ] Cross-platform testing (Web/Mobile/Desktop)
- [ ] Analytics validation

---

## 💰 Cost Estimation

### **Storage Costs (R2)**

**Assumptions:**
- Average song: 30MB WAV → 7MB MP3
- 1000 songs uploaded per month
- 50% keep original format

**Monthly Storage:**
```
Streaming (MP3): 1000 × 7MB = 7GB
Originals (WAV): 500 × 30MB = 15GB
Total: 22GB/month

R2 Pricing:
- Storage: $0.015/GB/month
- Monthly cost: 22GB × $0.015 = $0.33/month
- Yearly growth: ~264GB = $3.96/month (year 1)
```

**Bandwidth Costs:**
```
Assumptions:
- 10,000 downloads/month (80% MP3, 20% WAV)
- MP3: 8,000 × 7MB = 56GB
- WAV: 2,000 × 30MB = 60GB
- Total: 116GB/month

R2 Pricing:
- Egress: FREE (Cloudflare R2 has no egress fees!)
- Cost: $0/month 🎉
```

**Total Estimated Cost:**
- Month 1: $0.33
- Month 12: $3.96/month
- Very affordable! 💚

---

## ⚠️ Risks & Mitigation

### **Risk 1: Storage Explosion**
**Mitigation:**
- Implement original file expiration (delete after 1 year)
- Compress WAV files to FLAC (lossless, 50% smaller)
- Offer "premium only" original downloads

### **Risk 2: Bandwidth Abuse**
**Mitigation:**
- Strict rate limiting (10 downloads/day for free users)
- CAPTCHA for suspicious download patterns
- IP-based blocking for abuse
- Require email verification

### **Risk 3: Conversion Queue Backlog**
**Mitigation:**
- Use background job queue (Bull/Redis)
- Auto-scale conversion workers
- Prioritize premium users
- Show estimated wait time

### **Risk 4: Legal/Copyright Issues**
**Mitigation:**
- Clear terms: "Download for personal use only"
- Watermark/ID3 tags with platform info
- Track download analytics for DMCA compliance
- Artist can disable downloads per song

---

## 📝 Success Metrics

Track these KPIs:
- ✅ Download feature adoption rate (% of users who download)
- ✅ Format preference (MP3 vs WAV ratio)
- ✅ Premium conversion rate (downloads as motivation)
- ✅ Average downloads per user
- ✅ Download completion rate
- ✅ Storage cost per song
- ✅ Conversion processing time (target: <30s)

---

## 🔄 Future Enhancements

1. **Bulk Downloads** - Download entire albums/playlists as ZIP
2. **Offline Mode** - Auto-download for offline playback
3. **Smart Quality** - Auto-select format based on device/connection
4. **Custom Formats** - FLAC, ALAC for audiophiles
5. **Download Scheduling** - Queue downloads for later
6. **Cloud Sync** - Sync downloads across devices

---

## 📚 Documentation Links

- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [Fluent-FFmpeg Guide](https://github.com/fluent-ffmpeg/node-fluent-ffmpeg)
- [R2 Storage Docs](https://developers.cloudflare.com/r2/)
- [Dio Downloads](https://pub.dev/packages/dio)
- [Permission Handler](https://pub.dev/packages/permission_handler)

---

## ✅ Approval Checklist

Before implementation:
- [ ] Database schema reviewed and approved
- [ ] API endpoints reviewed and approved
- [ ] Storage structure approved
- [ ] Cost estimation acceptable
- [ ] Rate limits agreed upon
- [ ] Timeline feasible
- [ ] Ready to proceed

---

**Next Steps:**
1. Review this document
2. Approve schema changes
3. Begin Phase 1 implementation
4. Regular progress updates

**Estimated Total Time:** 3-4 weeks  
**Estimated Total Cost:** <$5/month (storage + compute)
