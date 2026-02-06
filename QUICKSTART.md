# Dynamic Artist Monetization Platform - Quick Start Guide

## 🚀 Getting Started

### Step 1: Start MongoDB with Docker

```bash
# Navigate to Flutter project root
cd "/Users/DekZ/Development/projects/app monitization/dynamic_artist_monetization"

# Start MongoDB and Mongo Express
docker-compose up -d

# Verify containers are running
docker ps
```

**Access Points:**
- MongoDB: `mongodb://localhost:27017`
- Mongo Express UI: `http://localhost:8081` (admin/pass)

---

### Step 2: Set Up Backend API

```bash
# Navigate to backend folder
cd "../api_dynamic_artist_monetization"

# Install dependencies (first time only)
npm install

# Start with PM2 (recommended - runs in background)
npm run pm2:dev

# Check status
npm run pm2:status

# View logs
npm run pm2:logs

# Stop server
npm run pm2:stop

# Alternative: Run without PM2 (blocks terminal)
# npm run dev
```

**Backend will run on:** `http://localhost:3000`

**Test it:**
```bash
curl http://localhost:3000/health

# Test registration
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test@1234",
    "role": "fan"
  }'
```

---

### Step 3: Run Flutter App

```bash
# Navigate back to Flutter project
cd "../dynamic_artist_monetization"

# Get Flutter dependencies
flutter pub get

# Run on web (for 30% discount feature)
flutter run -d chrome

# Or run on iOS simulator
flutter run -d ios

# Or run on Android emulator
flutter run -d android
```

---

## 📂 Project Structure

```
app monitization/
├── dynamic_artist_monetization/     # Flutter Frontend
│   ├── lib/
│   │   └── main.dart
│   ├── docker-compose.yml           # MongoDB + Mongo Express
│   ├── .env                         # Environment variables
│   └── QUICKSTART.md
│
└── api_dynamic_artist_monetization/ # Node.js Backend
    ├── src/
    │   ├── models/                  # Mongoose schemas
    │   ├── routes/                  # API routes
    │   ├── config/                  # Database & logger
    │   ├── middleware/              # Express middleware
    │   └── server.ts                # Main server
    ├── package.json
    ├── .env                         # Backend config
    └── README.md
```

---

## 🔧 Useful Commands

### Docker
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Restart MongoDB
docker-compose restart mongodb

# Remove all data (CAUTION!)
docker-compose down -v
```

### Backend
```bash
# Install dependencies
npm install

# Development mode (auto-reload)
npm run dev

# Build TypeScript
npm run build

# Production mode
npm start

# Run tests
npm test
```

### Flutter
```bash
# Get dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on specific device
flutter devices
flutter run -d <device-id>

# Build for production
flutter build web
flutter build apk
flutter build ios
```

---

## 🗄️ Database Access

### Via Mongo Express (Web UI)
1. Open browser: `http://localhost:8081`
2. Login: `admin` / `pass`
3. Select database: `artist_monetization`

### Via MongoDB Shell
```bash
docker exec -it dynamic_artist_mongodb mongosh -u admin -p adminpassword --authenticationDatabase admin

# Switch to database
use artist_monetization

# Show collections
show collections

# Query users
db.users.find().pretty()
```

---

## 🎯 What's Already Set Up

✅ MongoDB 7.0 with Docker  
✅ Mongo Express web interface  
✅ Node.js/Express backend with TypeScript  
✅ Complete database models (9 collections)  
✅ Environment configuration  
✅ API route structure  
✅ Error handling & logging  
✅ Security middleware (Helmet, CORS, Rate limiting)  

---

## 🔨 What Needs Implementation

### Backend
- [ ] Authentication controllers (register, login, JWT)
- [ ] User CRUD operations
- [ ] Song upload & management
- [ ] Bundle creation & management
- [ ] Rating system logic
- [ ] Tipping system with token transfer
- [ ] Stripe payment integration
- [ ] Treasure chest unlock mechanism
- [ ] Analytics & dashboard data
- [ ] File upload (Multer/AWS S3)

### Flutter Frontend
- [ ] Authentication screens
- [ ] Home feed
- [ ] Treasure chest UI with animations
- [ ] Song player
- [ ] Artist profile pages
- [ ] Rating interface
- [ ] Token wallet
- [ ] Tip sending UI
- [ ] Gallery system
- [ ] Bundle browser
- [ ] Navigation system with icons

---

## 🔐 Environment Variables

### Backend (.env in api_dynamic_artist_monetization)
```env
# Already configured - Update these:
MONGODB_URI=mongodb://admin:adminpassword@localhost:27017/artist_monetization?authSource=admin
JWT_SECRET=change-this-to-secure-random-string
STRIPE_SECRET_KEY=sk_test_your_key_here
```

### Flutter
Will need to configure API endpoint in Flutter app to point to:
```dart
const API_BASE_URL = 'http://localhost:3000/api/v1';
```

---

## 📊 Database Collections

1. **users** - Artists, fans, and admins
2. **songs** - Music tracks (10 max per artist)
3. **bundles** - Discounted song packages
4. **purchases** - Transaction records with platform tracking
5. **ratings** - Song reviews (1-5 stars)
6. **tips** - Peer-to-peer token transfers
7. **transactions** - Complete token history
8. **treasureChests** - Discovery mechanism
9. **follows** - Artist-fan relationships

---

## 🎨 Key Platform Features

### Token Economy
- 1 Token = $0.10 USD
- Purchase via Stripe
- Used for songs, bundles, tips

### Web Discount
- **30% OFF** when purchasing on web (vs app stores)
- Automatically applied based on platform detection

### Artist Constraints
- Maximum 10 songs per profile
- Can replace/delete songs
- Featured song option

### Discovery System
- Treasure chest mechanic
- 3 Rarity tiers: Common, Rare, Legendary
- Unlock with tokens

---

## 🐛 Troubleshooting

### MongoDB won't start
```bash
# Check if port 27017 is in use
lsof -ti:27017

# Kill process if needed
kill -9 <PID>

# Restart Docker
docker-compose down
docker-compose up -d
```

### Backend won't start
```bash
# Check if port 3000 is in use
lsof -ti:3000

# Install dependencies again
rm -rf node_modules package-lock.json
npm install
```

### Flutter issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

---

## 📚 Documentation

- **Backend API**: See `api_dynamic_artist_monetization/README.md`
- **Database Schema**: Check model files in `src/models/`
- **API Endpoints**: Defined in `src/routes/`

---

## 🚦 Status

**Current Phase**: Foundation Complete ✅

**Next Steps**:
1. Implement authentication (register/login)
2. Create Flutter UI structure
3. Build treasure chest animations
4. Set up Stripe integration
5. Implement song upload flow

---

## 💡 Pro Tips

1. Use Mongo Express to visualize database during development
2. Enable hot reload for faster Flutter development
3. Use Postman/Insomnia to test API endpoints
4. Check logs/ folder for backend errors
5. Web discount only works when running `flutter run -d chrome`

---

Need help? Check the README files or review the code comments!
