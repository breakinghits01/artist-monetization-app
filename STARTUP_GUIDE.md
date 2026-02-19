# Startup Guide - Artist Monetization Platform

## 🚀 Quick Start After Machine Restart

### If PM2 Auto-Start is Configured
```bash
# Check if services are running
pm2 status
```

If you see all 3 services running (artist-api-dev, cloudflare-tunnel, flutter-web), you're good to go!

---

## 🔧 Manual Start (If Services Aren't Running)

### Start All Services
```bash
# 1. Navigate to API project
cd /Users/DekZ/Development/projects/app\ monitization/api_dynamic_artist_monetization

# 2. Start all services with PM2
pm2 start ecosystem.config.js

# 3. Verify all services are running
pm2 status
```

**Expected output:**
```
┌────┬────────────────────┬──────────┬──────┬───────────┐
│ id │ name               │ mode     │ ↺    │ status    │
├────┼────────────────────┼──────────┼──────┼───────────┤
│ 0  │ artist-api-dev     │ fork     │ X    │ online    │
│ 5  │ cloudflare-tunnel  │ fork     │ X    │ online    │
│ 4  │ flutter-web        │ fork     │ X    │ online    │
└────┴────────────────────┴──────────┴──────┴───────────┘
```

---

## ⚙️ Setup PM2 Auto-Start (One-Time Setup)

Run this once to make PM2 start automatically on boot:

```bash
# 1. Save current PM2 processes
pm2 save

# 2. Generate startup script for macOS
pm2 startup

# 3. Run the command it outputs (requires sudo)
# Example: sudo env PATH=$PATH:/usr/local/bin pm2 startup darwin -u DekZ --hp /Users/DekZ
```

---

## ✅ Verify Everything Works

### Check PM2 Status
```bash
pm2 status
```

### Check API Health
```bash
curl https://artistmonetization.xyz/api/v1/health
```

### Check Web App
```bash
open https://artistmonetization.xyz
```

Or visit in browser: https://artistmonetization.xyz

---

## 🔄 Individual Service Control

### Restart Specific Service
```bash
pm2 restart artist-api-dev      # Restart API server
pm2 restart flutter-web          # Restart Flutter web
pm2 restart cloudflare-tunnel    # Restart tunnel
```

### View Logs
```bash
pm2 logs artist-api-dev          # API logs
pm2 logs flutter-web             # Web server logs
pm2 logs cloudflare-tunnel       # Tunnel logs

pm2 logs --lines 100             # Last 100 lines of all logs
```

### Stop/Start All Services
```bash
pm2 stop all                     # Stop all services
pm2 start all                    # Start all services
pm2 restart all                  # Restart all services
```

### Delete All Processes (Clean Start)
```bash
pm2 delete all                   # Remove all processes
pm2 start ecosystem.config.js    # Start fresh
```

---

## 🌐 Access URLs

- **Web App:** https://artistmonetization.xyz
- **API:** https://artistmonetization.xyz/api/v1
- **Mobile APK:** https://drive.google.com/drive/folders/1o7aBL3wnuSaXHtyJUz0dlS7G5whIzlYa?usp=sharing

---

## 🐛 Troubleshooting

### Services Won't Start
```bash
# Check for port conflicts
lsof -i :3000    # API port
lsof -i :9000    # Web server port

# Kill conflicting processes if needed
kill -9 <PID>

# Restart services
pm2 restart all
```

### Can't Access Website
1. Check if Cloudflare tunnel is running: `pm2 status`
2. Check tunnel logs: `pm2 logs cloudflare-tunnel`
3. Restart tunnel: `pm2 restart cloudflare-tunnel`

### MongoDB Connection Issues
```bash
# Check if MongoDB is running
brew services list | grep mongodb

# Start MongoDB if needed
brew services start mongodb-community
```

---

## 📋 Service Details

| Service | Port | Process | URL |
|---------|------|---------|-----|
| API Server | 3000 | artist-api-dev | http://localhost:3000 |
| Web Server | 9000 | flutter-web | http://localhost:9000 |
| Cloudflare Tunnel | - | cloudflare-tunnel | https://artistmonetization.xyz |

---

## 🔐 Production URLs

All services are accessible globally via:
- **HTTPS:** https://artistmonetization.xyz
- **API Endpoint:** https://artistmonetization.xyz/api/v1
- **Secured by:** Cloudflare Tunnel + JWT Authentication
