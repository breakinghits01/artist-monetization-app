#!/bin/bash

echo "🏗️  Building Flutter web..."
flutter build web --release

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "🧹 Cleaning web-build directory..."
rm -rf "/Users/DekZ/Development/projects/app monitization/api_dynamic_artist_monetization/web-build"
mkdir -p "/Users/DekZ/Development/projects/app monitization/api_dynamic_artist_monetization/web-build"

echo "📦 Copying build files..."
cp -r build/web/* "/Users/DekZ/Development/projects/app monitization/api_dynamic_artist_monetization/web-build/"

echo ""
echo "✅ DEPLOYMENT COMPLETE!"
echo ""
echo "🌐 Access your app at: http://localhost:3000"
echo "🔗 Or via ngrok: https://caryl-exertive-treva.ngrok-free.dev/"
echo ""
echo "⚠️  IMPORTANT: Clear your browser cache!"
echo "   - Chrome/Edge: Ctrl+Shift+Delete (Cmd+Shift+Delete on Mac)"
echo "   - Or do HARD REFRESH: Ctrl+Shift+R (Cmd+Shift+R on Mac)"
echo "   - Or open in Incognito/Private mode"
echo ""
