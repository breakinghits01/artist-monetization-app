#!/bin/bash

echo "🏗️  Building backend API..."
cd "/Users/DekZ/Development/projects/app monitization/api_dynamic_artist_monetization"
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Backend build failed!"
    exit 1
fi

echo ""
echo "🔄 Restarting API server (PM2)..."
pm2 restart artist-api-dev

echo ""
echo "🏗️  Building Flutter web..."
cd "/Users/DekZ/Development/projects/app monitization/dynamic_artist_monetization"
flutter build web --release

if [ $? -ne 0 ]; then
    echo "❌ Frontend build failed!"
    exit 1
fi

echo "🧹 Cleaning web-build directory..."
rm -rf "/Users/DekZ/Development/projects/app monitization/api_dynamic_artist_monetization/web-build"
mkdir -p "/Users/DekZ/Development/projects/app monitization/api_dynamic_artist_monetization/web-build"

echo "📦 Copying build files..."
cp -r build/web/* "/Users/DekZ/Development/projects/app monitization/api_dynamic_artist_monetization/web-build/"

echo ""
echo "🏗️  Building CMS Flutter web..."
cd "/Users/DekZ/Development/projects/app monitization/cms_dynamic_artist_monetization"
flutter build web --release

if [ $? -ne 0 ]; then
    echo "❌ CMS build failed!"
    exit 1
fi

echo "🧹 Cleaning cms-build directory..."
rm -rf "/Users/DekZ/Development/projects/app monitization/api_dynamic_artist_monetization/cms-build"
mkdir -p "/Users/DekZ/Development/projects/app monitization/api_dynamic_artist_monetization/cms-build"

echo "📦 Copying CMS build files..."
cp -r build/web/* "/Users/DekZ/Development/projects/app monitization/api_dynamic_artist_monetization/cms-build/"

echo ""
echo "🔄 Restarting Flutter web server (PM2)..."
cd "/Users/DekZ/Development/projects/app monitization/api_dynamic_artist_monetization"
pm2 restart flutter-web

echo ""
echo "🔄 Restarting CMS Flutter web server (PM2)..."
pm2 restart cms-flutter-web

echo ""
echo "✅ DEPLOYMENT COMPLETE!"
echo ""
echo "🌐 Production URLs:"
echo "   - Main App: https://artistmonetization.xyz"
echo "   - CMS Admin: https://cms.artistmonetization.xyz"
echo "   - API Endpoint: https://artistmonetization.xyz/api/v1"
echo ""
echo "💡 Local Development:"
echo "   - Proxy Server: http://localhost:9000"
echo "   - CMS Server: http://localhost:9001"
echo "   - API Server: http://localhost:3000"
echo ""
echo "⚠️  IMPORTANT: Clear your browser cache!"
echo "   - Chrome/Edge: Ctrl+Shift+Delete (Cmd+Shift+Delete on Mac)"
echo "   - Or do HARD REFRESH: Ctrl+Shift+R (Cmd+Shift+R on Mac)"
echo "   - Or open in Incognito/Private mode"
echo ""
