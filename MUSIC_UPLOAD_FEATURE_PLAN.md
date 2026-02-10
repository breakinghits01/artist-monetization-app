# Music Upload Feature - Complete Implementation Plan

**Created:** February 10, 2026  
**Status:** Planning Phase  
**Version:** 1.0

---

## 🎯 Overview

Add a dedicated **Upload** navigation item to enable artists to upload their music directly from the app with complete metadata management, file upload, and database integration.

---

## 📱 Navigation Bar Analysis

### Current Navigation (4 items)
```
┌──────┬──────────┬─────────┬─────────┐
│ Home │ Discover │ Connect │ Profile │
└──────┴──────────┴─────────┴─────────┘
```

### Proposed Navigation (5 items)
```
┌──────┬──────────┬────────┬─────────┬─────────┐
│ Home │ Discover │ Upload │ Connect │ Profile │
└──────┴──────────┴────────┴─────────┴─────────┘
```

**Design Consideration:**
- ✅ 5 navigation items is acceptable for Material Design (max recommended: 5)
- ✅ Upload placed in center for easy thumb access
- ✅ Upload icon can use different style (FAB-like) to stand out
- ⚠️ May need to test on small screens (320px width)

**Alternative: Floating Action Button (FAB)**
- Keep 4 navigation items
- Add FAB for upload (overlay above nav bar)
- Pro: Prominent, doesn't clutter nav
- Con: May conflict with mini player

**Recommendation:** Add Upload as 5th nav item with distinctive icon (cloud_upload or add_circle)

---

## 🗄️ Database Schema

### 1. Enhanced Song Model (Already exists, needs extension)

#### Current Schema
```typescript
// api_dynamic_artist_monetization/src/models/Song.model.ts
interface ISong {
  _id: ObjectId;
  artistId: ObjectId;          // ref: User
  title: string;
  duration: number;            // seconds
  price: number;               // tokens
  coverArt?: string;           // URL
  audioUrl: string;            // URL
  exclusive: boolean;
  genre?: string;
  description?: string;
  playCount: number;
  featured: boolean;
  createdAt: Date;
  updatedAt: Date;
}
```

#### Required Additions
```typescript
interface ISong {
  // ... existing fields
  
  // Upload metadata
  uploadStatus: 'processing' | 'ready' | 'failed';
  uploadProgress: number;      // 0-100
  fileSize: number;            // bytes
  audioFormat: string;         // mp3, m4a, wav, etc.
  bitrate: number;             // kbps
  sampleRate: number;          // Hz
  
  // Content metadata
  lyrics?: string;
  releaseDate?: Date;
  albumName?: string;
  trackNumber?: number;
  isrc?: string;               // International Standard Recording Code
  
  // Rights & licensing
  copyright?: string;
  license?: 'all-rights-reserved' | 'creative-commons' | 'public-domain';
  allowDownload: boolean;
  allowRemix: boolean;
  
  // Moderation
  moderationStatus: 'pending' | 'approved' | 'rejected';
  moderationNotes?: string;
  moderatedBy?: ObjectId;      // ref: User (admin)
  moderatedAt?: Date;
  
  // Analytics
  totalEarnings: number;       // tokens earned
  uniqueListeners: number;
  averagePlayDuration: number; // seconds
  completionRate: number;      // percentage
  
  // Visibility
  isPublished: boolean;
  publishedAt?: Date;
  isDraft: boolean;
  isDeleted: boolean;
  deletedAt?: Date;
}
```

---

### 2. New: Upload Session Model

Track ongoing uploads for resumability and progress monitoring.

```typescript
// api_dynamic_artist_monetization/src/models/UploadSession.model.ts

interface IUploadSession extends Document {
  _id: ObjectId;
  userId: ObjectId;            // ref: User
  
  // File information
  fileName: string;
  fileSize: number;            // bytes
  fileType: string;            // audio/mpeg, audio/mp4, etc.
  fileHash: string;            // MD5 or SHA256 for integrity
  
  // Upload tracking
  uploadStatus: 'initiated' | 'uploading' | 'processing' | 'completed' | 'failed' | 'cancelled';
  uploadProgress: number;      // 0-100
  bytesUploaded: number;
  
  // Storage
  tempFilePath?: string;       // Temporary storage location
  finalAudioUrl?: string;      // Final CDN URL after processing
  finalCoverArtUrl?: string;   // Cover art CDN URL
  
  // Multipart upload (for large files)
  uploadId?: string;           // S3/Cloud Storage upload ID
  partETags?: Array<{
    partNumber: number;
    etag: string;
  }>;
  
  // Processing
  processingStartedAt?: Date;
  processingCompletedAt?: Date;
  processingError?: string;
  
  // Metadata (draft)
  metadata?: {
    title?: string;
    genre?: string;
    description?: string;
    price?: number;
    coverArtBase64?: string;   // Temporary until uploaded
  };
  
  // Session management
  expiresAt: Date;             // Auto-cleanup after 24 hours
  lastActivityAt: Date;
  
  createdAt: Date;
  updatedAt: Date;
}

const UploadSessionSchema = new Schema<IUploadSession>({
  userId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  fileName: {
    type: String,
    required: true,
  },
  fileSize: {
    type: Number,
    required: true,
    min: [0, 'File size cannot be negative'],
    max: [100 * 1024 * 1024, 'File size cannot exceed 100MB'],
  },
  fileType: {
    type: String,
    required: true,
    enum: ['audio/mpeg', 'audio/mp4', 'audio/wav', 'audio/aac', 'audio/ogg'],
  },
  fileHash: {
    type: String,
    required: true,
  },
  uploadStatus: {
    type: String,
    enum: ['initiated', 'uploading', 'processing', 'completed', 'failed', 'cancelled'],
    default: 'initiated',
    index: true,
  },
  uploadProgress: {
    type: Number,
    default: 0,
    min: 0,
    max: 100,
  },
  bytesUploaded: {
    type: Number,
    default: 0,
  },
  tempFilePath: String,
  finalAudioUrl: String,
  finalCoverArtUrl: String,
  uploadId: String,
  partETags: [{
    partNumber: Number,
    etag: String,
  }],
  processingStartedAt: Date,
  processingCompletedAt: Date,
  processingError: String,
  metadata: {
    type: Schema.Types.Mixed,
    default: {},
  },
  expiresAt: {
    type: Date,
    required: true,
    index: { expireAfterSeconds: 0 }, // TTL index
  },
  lastActivityAt: {
    type: Date,
    default: Date.now,
  },
}, {
  timestamps: true,
});

// Indexes
UploadSessionSchema.index({ userId: 1, uploadStatus: 1 });
UploadSessionSchema.index({ createdAt: -1 });
UploadSessionSchema.index({ expiresAt: 1 }); // For TTL

export default mongoose.model<IUploadSession>('UploadSession', UploadSessionSchema);
```

---

### 3. New: Audio Processing Queue Model

Track background processing jobs for audio transcoding, analysis, etc.

```typescript
// api_dynamic_artist_monetization/src/models/AudioProcessingQueue.model.ts

interface IAudioProcessingJob extends Document {
  _id: ObjectId;
  uploadSessionId: ObjectId;   // ref: UploadSession
  songId?: ObjectId;           // ref: Song (after creation)
  userId: ObjectId;            // ref: User
  
  // Job information
  jobType: 'transcode' | 'analyze' | 'generate-waveform' | 'extract-metadata';
  priority: number;            // 1 (high) to 10 (low)
  status: 'queued' | 'processing' | 'completed' | 'failed' | 'cancelled';
  
  // Input/Output
  inputFilePath: string;
  outputFilePath?: string;
  
  // Processing
  attempts: number;
  maxAttempts: number;
  lastAttemptAt?: Date;
  error?: string;
  
  // Results
  results?: {
    duration?: number;
    bitrate?: number;
    sampleRate?: number;
    audioFormat?: string;
    waveformData?: number[];
    metadata?: Record<string, any>;
  };
  
  // Timing
  queuedAt: Date;
  startedAt?: Date;
  completedAt?: Date;
  processingTime?: number;     // milliseconds
  
  createdAt: Date;
  updatedAt: Date;
}

const AudioProcessingQueueSchema = new Schema<IAudioProcessingJob>({
  uploadSessionId: {
    type: Schema.Types.ObjectId,
    ref: 'UploadSession',
    required: true,
  },
  songId: {
    type: Schema.Types.ObjectId,
    ref: 'Song',
  },
  userId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  jobType: {
    type: String,
    enum: ['transcode', 'analyze', 'generate-waveform', 'extract-metadata'],
    required: true,
  },
  priority: {
    type: Number,
    default: 5,
    min: 1,
    max: 10,
  },
  status: {
    type: String,
    enum: ['queued', 'processing', 'completed', 'failed', 'cancelled'],
    default: 'queued',
    index: true,
  },
  inputFilePath: {
    type: String,
    required: true,
  },
  outputFilePath: String,
  attempts: {
    type: Number,
    default: 0,
  },
  maxAttempts: {
    type: Number,
    default: 3,
  },
  lastAttemptAt: Date,
  error: String,
  results: Schema.Types.Mixed,
  queuedAt: {
    type: Date,
    default: Date.now,
  },
  startedAt: Date,
  completedAt: Date,
  processingTime: Number,
}, {
  timestamps: true,
});

// Indexes
AudioProcessingQueueSchema.index({ status: 1, priority: 1, queuedAt: 1 });
AudioProcessingQueueSchema.index({ userId: 1, status: 1 });
AudioProcessingQueueSchema.index({ uploadSessionId: 1 });

export default mongoose.model<IAudioProcessingJob>('AudioProcessingQueue', AudioProcessingQueueSchema);
```

---

### 4. Updated: User Model Extensions

Add upload-related stats to user model.

```typescript
// Add to existing User model
interface IUser {
  // ... existing fields
  
  // Upload stats
  totalSongsUploaded: number;
  storageUsed: number;         // bytes
  storageLimit: number;        // bytes (default: 1GB for free, 10GB for premium)
  uploadQuotaUsed: number;     // uploads this month
  uploadQuotaLimit: number;    // uploads per month (default: 10)
  uploadQuotaResetAt: Date;
  
  // Content stats
  totalPlays: number;
  totalEarnings: number;       // tokens
  averageRating: number;
  totalRatings: number;
}
```

---

## 📊 Database Indexes

### Performance Optimization

```typescript
// Song.model.ts
SongSchema.index({ artistId: 1, uploadStatus: 1 });
SongSchema.index({ artistId: 1, isDraft: 1 });
SongSchema.index({ moderationStatus: 1, createdAt: -1 });
SongSchema.index({ isPublished: 1, playCount: -1 });
SongSchema.index({ genre: 1, playCount: -1 });

// UploadSession.model.ts
UploadSessionSchema.index({ userId: 1, uploadStatus: 1 });
UploadSessionSchema.index({ uploadStatus: 1, expiresAt: 1 });
UploadSessionSchema.index({ fileHash: 1 }); // Duplicate detection

// AudioProcessingQueue.model.ts
AudioProcessingQueueSchema.index({ status: 1, priority: 1, queuedAt: 1 });
AudioProcessingQueueSchema.index({ userId: 1, jobType: 1 });
```

---

## 🔌 API Endpoints

### Upload Endpoints

```typescript
// POST /api/upload/initiate
// Initialize upload session
Request: {
  fileName: string;
  fileSize: number;
  fileType: string;
  fileHash: string;
}
Response: {
  uploadSessionId: string;
  uploadUrl: string;          // Pre-signed S3 URL or chunk upload endpoint
  uploadId?: string;          // For multipart uploads
  chunkSize: number;          // Recommended chunk size
}

// POST /api/upload/chunk/:sessionId
// Upload file chunk (for large files)
Request: FormData {
  chunk: File;
  chunkNumber: number;
  totalChunks: number;
}
Response: {
  chunkNumber: number;
  uploadProgress: number;
  etag: string;
}

// POST /api/upload/complete/:sessionId
// Complete upload and start processing
Request: {
  parts?: Array<{ partNumber: number; etag: string }>;
}
Response: {
  uploadSessionId: string;
  status: 'processing';
  processingJobId: string;
}

// GET /api/upload/status/:sessionId
// Get upload/processing status
Response: {
  uploadSessionId: string;
  status: 'uploading' | 'processing' | 'completed' | 'failed';
  uploadProgress: number;
  processingProgress?: number;
  error?: string;
  audioUrl?: string;         // Available when completed
  metadata?: object;
}

// POST /api/upload/cancel/:sessionId
// Cancel ongoing upload
Response: {
  success: boolean;
  message: string;
}

// POST /api/upload/metadata/:sessionId
// Add metadata to completed upload
Request: {
  title: string;
  genre?: string;
  description?: string;
  price: number;
  coverArt?: string;         // Base64 or URL
  releaseDate?: string;
  albumName?: string;
  lyrics?: string;
  allowDownload?: boolean;
  allowRemix?: boolean;
  license?: string;
}
Response: {
  songId: string;
  message: string;
}

// GET /api/upload/history
// Get user's upload history
Query: {
  status?: string;
  limit?: number;
  offset?: number;
}
Response: {
  uploads: Array<UploadSession>;
  total: number;
  hasMore: boolean;
}

// DELETE /api/upload/:sessionId
// Delete upload session and cleanup files
Response: {
  success: boolean;
  message: string;
}
```

### Song Management Endpoints (Extended)

```typescript
// POST /api/songs
// Create song from completed upload
Request: {
  uploadSessionId: string;
  // ... metadata
}
Response: {
  song: ISong;
}

// PATCH /api/songs/:songId
// Update song metadata
Request: {
  title?: string;
  description?: string;
  price?: number;
  // ... other fields
}
Response: {
  song: ISong;
}

// DELETE /api/songs/:songId
// Soft delete song
Response: {
  success: boolean;
  message: string;
}

// POST /api/songs/:songId/publish
// Publish draft song
Response: {
  song: ISong;
}

// POST /api/songs/:songId/unpublish
// Unpublish song (make draft)
Response: {
  song: ISong;
}

// GET /api/songs/drafts
// Get user's draft songs
Response: {
  drafts: ISong[];
}

// GET /api/songs/analytics/:songId
// Get detailed analytics for a song
Response: {
  song: ISong;
  analytics: {
    plays: { date: string; count: number }[];
    earnings: { date: string; amount: number }[];
    listeners: { unique: number; returning: number };
    demographics: { country: string; plays: number }[];
    devices: { platform: string; percentage: number }[];
  };
}
```

---

## 🎨 Frontend Implementation

### 1. Navigation Update

```dart
// lib/features/home/presentation/screens/dashboard_screen.dart

NavigationBar(
  selectedIndex: _selectedIndex,
  onDestinationSelected: _onItemTapped,
  destinations: const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Discover',
    ),
    NavigationDestination(
      icon: Icon(Icons.cloud_upload_outlined),
      selectedIcon: Icon(Icons.cloud_upload),
      label: 'Upload',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Connect',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ],
)
```

---

### 2. Upload Screen Structure

```
lib/features/upload/
├── models/
│   ├── upload_session.dart
│   ├── upload_metadata.dart
│   └── upload_progress.dart
├── providers/
│   ├── upload_provider.dart
│   ├── draft_songs_provider.dart
│   └── upload_history_provider.dart
├── services/
│   ├── upload_service.dart
│   ├── file_picker_service.dart
│   └── audio_processor_service.dart
├── presentation/
│   ├── screens/
│   │   ├── upload_screen.dart           # Main upload screen
│   │   ├── upload_progress_screen.dart  # Active upload monitoring
│   │   ├── metadata_form_screen.dart    # Song details form
│   │   └── draft_songs_screen.dart      # Manage drafts
│   └── widgets/
│       ├── file_picker_button.dart
│       ├── upload_progress_card.dart
│       ├── metadata_form.dart
│       ├── cover_art_picker.dart
│       ├── genre_selector.dart
│       ├── price_selector.dart
│       ├── draft_song_card.dart
│       └── upload_guidelines.dart
└── utils/
    ├── file_validator.dart
    ├── audio_analyzer.dart
    └── upload_helper.dart
```

---

### 3. Upload Screen UI Flow

#### Step 1: File Selection
```
┌─────────────────────────────────┐
│  🎵 Upload Your Music           │
├─────────────────────────────────┤
│                                 │
│   ┌───────────────────────┐     │
│   │   📁                  │     │
│   │                       │     │
│   │  Tap to select audio  │     │
│   │  file or drag & drop  │     │
│   │                       │     │
│   └───────────────────────┘     │
│                                 │
│  Supported formats:             │
│  MP3, M4A, WAV, FLAC, OGG      │
│  Max size: 100MB                │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 📚 View My Drafts       │   │
│  └─────────────────────────┘   │
│                                 │
│  Upload Quota: 7/10 this month  │
│  Storage: 234MB / 1GB used      │
└─────────────────────────────────┘
```

#### Step 2: Upload Progress
```
┌─────────────────────────────────┐
│  ⬆️  Uploading                   │
├─────────────────────────────────┤
│  summer_vibes_final.mp3         │
│  15.2 MB • 00:03:24             │
│                                 │
│  ▓▓▓▓▓▓▓▓▓▓▓▓░░░░  72%        │
│  11.0 MB / 15.2 MB              │
│                                 │
│  🔄 Processing audio...          │
│                                 │
│  [Cancel Upload]                │
└─────────────────────────────────┘
```

#### Step 3: Metadata Form
```
┌─────────────────────────────────┐
│  📝 Song Details                 │
├─────────────────────────────────┤
│  Cover Art                      │
│  ┌────┐                         │
│  │ 🎨 │ [Change Image]          │
│  └────┘                         │
│                                 │
│  Title *                        │
│  └─────────────────────────┘   │
│                                 │
│  Genre                          │
│  └─ Pop ▼──────────────────┘   │
│                                 │
│  Description                    │
│  └─────────────────────────┘   │
│  └─────────────────────────┘   │
│                                 │
│  Price (Tokens)                 │
│  └─ 10 ────────────────────┘   │
│                                 │
│  ☐ Allow downloads              │
│  ☐ Allow remixes                │
│                                 │
│  [Save as Draft] [Publish]      │
└─────────────────────────────────┘
```

---

### 4. Upload Provider

```dart
// lib/features/upload/providers/upload_provider.dart

class UploadNotifier extends StateNotifier<AsyncValue<UploadState>> {
  final UploadService _uploadService;
  final Ref _ref;
  
  UploadNotifier(this._ref, this._uploadService) 
    : super(const AsyncValue.data(UploadState.idle()));

  // Initialize upload session
  Future<void> initiateUpload(File audioFile) async {
    state = const AsyncValue.loading();
    try {
      final session = await _uploadService.initiateUpload(audioFile);
      state = AsyncValue.data(UploadState.uploading(session));
      
      // Start upload with progress tracking
      await _startUpload(session, audioFile);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Upload file with progress
  Future<void> _startUpload(UploadSession session, File file) async {
    final stream = _uploadService.uploadWithProgress(session, file);
    
    await for (final progress in stream) {
      state = AsyncValue.data(UploadState.uploading(
        session.copyWith(uploadProgress: progress),
      ));
    }
    
    // Mark as processing
    state = AsyncValue.data(UploadState.processing(session));
    
    // Wait for processing
    await _pollProcessingStatus(session.id);
  }

  // Poll processing status
  Future<void> _pollProcessingStatus(String sessionId) async {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      
      final status = await _uploadService.getStatus(sessionId);
      
      if (status.uploadStatus == 'completed') {
        state = AsyncValue.data(UploadState.completed(status));
        break;
      } else if (status.uploadStatus == 'failed') {
        state = AsyncValue.error(status.error ?? 'Processing failed', StackTrace.current);
        break;
      }
      
      // Update progress
      state = AsyncValue.data(UploadState.processing(status));
    }
  }

  // Submit metadata and create song
  Future<void> submitMetadata(String sessionId, SongMetadata metadata) async {
    try {
      final song = await _uploadService.submitMetadata(sessionId, metadata);
      state = AsyncValue.data(UploadState.published(song));
      
      // Refresh user songs
      _ref.invalidate(userSongsProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Cancel upload
  Future<void> cancelUpload(String sessionId) async {
    try {
      await _uploadService.cancelUpload(sessionId);
      state = const AsyncValue.data(UploadState.idle());
    } catch (e) {
      print('Error canceling upload: $e');
    }
  }
}

final uploadProvider = StateNotifierProvider<UploadNotifier, AsyncValue<UploadState>>(
  (ref) => UploadNotifier(ref, ref.read(uploadServiceProvider)),
);
```

---

## 🔒 Security & Validation

### File Validation

```dart
class FileValidator {
  static const List<String> allowedExtensions = [
    'mp3', 'm4a', 'wav', 'flac', 'ogg', 'aac'
  ];
  
  static const List<String> allowedMimeTypes = [
    'audio/mpeg',
    'audio/mp4',
    'audio/wav',
    'audio/x-wav',
    'audio/flac',
    'audio/ogg',
    'audio/aac',
  ];
  
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
  static const int minFileSize = 100 * 1024; // 100KB
  static const int maxDuration = 15 * 60; // 15 minutes
  
  static Future<ValidationResult> validate(File file) async {
    // Check file size
    final fileSize = await file.length();
    if (fileSize > maxFileSize) {
      return ValidationResult.error('File too large. Max size: 100MB');
    }
    if (fileSize < minFileSize) {
      return ValidationResult.error('File too small. Min size: 100KB');
    }
    
    // Check file extension
    final extension = file.path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return ValidationResult.error('Invalid file format. Allowed: ${allowedExtensions.join(', ')}');
    }
    
    // Check MIME type
    final mimeType = lookupMimeType(file.path);
    if (mimeType == null || !allowedMimeTypes.contains(mimeType)) {
      return ValidationResult.error('Invalid audio file type');
    }
    
    // Analyze audio (duration, bitrate, etc.)
    final metadata = await AudioAnalyzer.analyze(file);
    if (metadata.duration > maxDuration) {
      return ValidationResult.error('Audio too long. Max duration: 15 minutes');
    }
    
    return ValidationResult.success(metadata);
  }
}
```

### Backend Validation

```typescript
// File upload validation middleware
export const validateUpload = async (req, res, next) => {
  const { fileSize, fileType } = req.body;
  
  // Check file size
  const MAX_FILE_SIZE = 100 * 1024 * 1024; // 100MB
  if (fileSize > MAX_FILE_SIZE) {
    return res.status(400).json({ error: 'File size exceeds 100MB limit' });
  }
  
  // Check MIME type
  const allowedTypes = ['audio/mpeg', 'audio/mp4', 'audio/wav', 'audio/ogg', 'audio/aac'];
  if (!allowedTypes.includes(fileType)) {
    return res.status(400).json({ error: 'Invalid audio file type' });
  }
  
  // Check user's upload quota
  const user = await User.findById(req.user.id);
  if (user.uploadQuotaUsed >= user.uploadQuotaLimit) {
    return res.status(429).json({ error: 'Monthly upload quota exceeded' });
  }
  
  // Check storage limit
  const storageUsed = user.storageUsed + fileSize;
  if (storageUsed > user.storageLimit) {
    return res.status(507).json({ error: 'Storage limit exceeded' });
  }
  
  // Check song limit per artist
  const songCount = await Song.countDocuments({ artistId: req.user.id, isDeleted: false });
  if (songCount >= 10) {
    return res.status(400).json({ error: 'Maximum 10 songs limit reached. Delete old songs to upload new ones.' });
  }
  
  next();
};

// Virus scanning (integrate with ClamAV or similar)
export const scanForVirus = async (filePath: string) => {
  // Implementation using node-clamav or cloud service
  const result = await clamav.scanFile(filePath);
  if (result.isInfected) {
    throw new Error('File contains malicious content');
  }
};
```

---

## ☁️ File Storage Strategy

### Option 1: AWS S3 (Recommended)

**Pros:**
- Highly scalable and reliable
- Built-in CDN integration (CloudFront)
- Multipart upload support for large files
- Lifecycle policies for cleanup
- Cost-effective

**Implementation:**
```typescript
import AWS from 'aws-sdk';

const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION,
});

// Generate pre-signed URL for direct upload
export const generateUploadUrl = async (fileName: string, fileType: string) => {
  const key = `uploads/${Date.now()}-${fileName}`;
  
  const params = {
    Bucket: process.env.S3_BUCKET_NAME,
    Key: key,
    ContentType: fileType,
    Expires: 3600, // 1 hour
  };
  
  const uploadUrl = await s3.getSignedUrlPromise('putObject', params);
  
  return { uploadUrl, key };
};

// Initiate multipart upload (for large files)
export const initiateMultipartUpload = async (fileName: string, fileType: string) => {
  const key = `uploads/${Date.now()}-${fileName}`;
  
  const params = {
    Bucket: process.env.S3_BUCKET_NAME,
    Key: key,
    ContentType: fileType,
  };
  
  const result = await s3.createMultipartUpload(params).promise();
  
  return {
    uploadId: result.UploadId,
    key: result.Key,
  };
};
```

### Option 2: Google Cloud Storage

Similar implementation with `@google-cloud/storage` package.

### Option 3: Self-hosted (MinIO)

For cost savings, use MinIO as S3-compatible storage.

---

## 🎵 Audio Processing Pipeline

### Processing Steps

1. **Validation**
   - Verify audio format
   - Check file integrity
   - Scan for viruses

2. **Transcoding**
   - Convert to web-optimized format (128kbps MP3 for streaming)
   - Generate multiple quality versions (HQ for download)
   - Create preview clip (30 seconds)

3. **Analysis**
   - Extract duration, bitrate, sample rate
   - Generate waveform data
   - Detect silence/trim
   - Extract embedded metadata

4. **Thumbnail Generation**
   - Create waveform image
   - Generate color palette from cover art
   - Resize cover art (multiple sizes)

5. **CDN Upload**
   - Upload processed files to CDN
   - Generate streaming URLs
   - Update database

### Implementation with FFmpeg

```typescript
import ffmpeg from 'fluent-ffmpeg';
import { promisify } from 'util';

export class AudioProcessor {
  // Transcode to web-optimized MP3
  async transcode(inputPath: string, outputPath: string): Promise<void> {
    return new Promise((resolve, reject) => {
      ffmpeg(inputPath)
        .audioCodec('libmp3lame')
        .audioBitrate('128k')
        .audioFrequency(44100)
        .audioChannels(2)
        .on('end', () => resolve())
        .on('error', (err) => reject(err))
        .save(outputPath);
    });
  }

  // Extract audio metadata
  async extractMetadata(filePath: string): Promise<AudioMetadata> {
    return new Promise((resolve, reject) => {
      ffmpeg.ffprobe(filePath, (err, metadata) => {
        if (err) return reject(err);
        
        const audioStream = metadata.streams.find(s => s.codec_type === 'audio');
        
        resolve({
          duration: metadata.format.duration,
          bitrate: metadata.format.bit_rate,
          sampleRate: audioStream?.sample_rate,
          channels: audioStream?.channels,
          format: metadata.format.format_name,
          size: metadata.format.size,
        });
      });
    });
  }

  // Generate waveform data
  async generateWaveform(inputPath: string): Promise<number[]> {
    // Use audiowaveform or similar library
    const waveformData = await generateWaveformData(inputPath, {
      samples: 1000,
      channels: 1,
    });
    
    return waveformData;
  }
}
```

---

## 💰 Pricing & Limits

### Free Tier
- 10 songs max
- 1GB storage
- 10 uploads per month
- 128kbps streaming quality
- No analytics

### Premium Tier ($9.99/month)
- 100 songs max
- 10GB storage
- Unlimited uploads
- 320kbps streaming quality
- Detailed analytics
- Priority processing
- Custom branding

### Enterprise (Custom)
- Unlimited songs
- Unlimited storage
- White-label options
- API access
- Dedicated support

---

## 📈 Success Metrics

### User Engagement
- Upload success rate (target: >95%)
- Average time to complete upload (target: <5 min)
- Metadata completion rate (target: >80%)
- Draft to published ratio (target: >70%)

### Technical Performance
- Upload speed (target: >1MB/s)
- Processing time (target: <2 min for standard file)
- Failed upload rate (target: <5%)
- Storage efficiency (compression ratio)

### Business Metrics
- Premium conversion from upload feature
- Storage usage per user
- Average song earnings
- Upload frequency per user

---

## ⏱️ Implementation Timeline

### Phase 1: Backend Foundation (2 weeks)
- Week 1: Database models, API endpoints
- Week 2: File upload service, S3 integration

### Phase 2: Audio Processing (1 week)
- Audio transcoding pipeline
- Metadata extraction
- Waveform generation

### Phase 3: Frontend Upload (2 weeks)
- Week 1: Upload screen UI, file picker
- Week 2: Progress tracking, metadata form

### Phase 4: Integration & Testing (1 week)
- End-to-end testing
- Performance optimization
- Bug fixes

### Phase 5: Launch & Monitor (Ongoing)
- Beta testing with select users
- Gradual rollout
- Monitor metrics
- Iterate based on feedback

**Total Estimated Time:** 6-7 weeks

---

## 🚀 Quick Start Implementation Order

1. **Add Navigation Item** (2 hours)
   - Update dashboard_screen.dart
   - Add Upload screen placeholder
   - Test navigation

2. **Backend Models** (1 day)
   - Create UploadSession model
   - Create AudioProcessingQueue model
   - Update Song model

3. **Basic Upload Endpoint** (2 days)
   - File validation
   - S3 integration
   - Upload initiation

4. **Frontend File Picker** (1 day)
   - File selection UI
   - Validation
   - Basic upload

5. **Progress Tracking** (1 day)
   - Upload progress UI
   - Status polling
   - Error handling

6. **Metadata Form** (2 days)
   - Form UI
   - Validation
   - Song creation

7. **Audio Processing** (3 days)
   - FFmpeg integration
   - Background queue
   - Status updates

**MVP Timeline:** 2 weeks

---

## 📝 Notes

- Consider using WebSocket for real-time upload progress instead of polling
- Implement resume functionality for interrupted uploads
- Add duplicate detection using audio fingerprinting (AcoustID)
- Consider adding collaborative features (multiple artists on one song)
- Plan for future features: stems upload, music videos, lyrics sync

---

**Last Updated:** February 10, 2026  
**Next Review:** After backend implementation
