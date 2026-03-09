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
echo "🏗️  Building Flutter web app..."
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
echo "🔄 Restarting Flutter web server (PM2)..."
cd "/Users/DekZ/Development/projects/app monitization/api_dynamic_artist_monetization"
pm2 restart flutter-web

echo ""
echo "✅ DEPLOYMENT COMPLETE!"
echo ""
echo "🌐 Production URL:"
echo "   - Main App: https://artistmonetization.xyz"
echo "   - API Endpoint: https://artistmonetization.xyz/api/v1"
echo ""
echo "⚠️  IMPORTANT: Clear your browser cache!"
echo "   - Chrome/Edge: Ctrl+Shift+Delete (Cmd+Shift+Delete on Mac)"
echo "   - Or do HARD REFRESH: Ctrl+Shift+R (Cmd+Shift+R on Mac)"
echo "   - Or open in Incognito/Private mode"
echo ""
