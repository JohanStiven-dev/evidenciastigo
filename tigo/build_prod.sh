#!/bin/bash

# Build the Flutter web application for production
# Domain: contigo.alohi.com.co
# API URL: https://tigo.alohi.com.co/api/v2

echo "Building Flutter Web for Production (contigo.alohi.com.co)..."

flutter build web \
  --release \
  --dart-define=API_URL=https://tigo.alohi.com.co/api/v2

echo "Build complete. Artifacts are in build/web/"
