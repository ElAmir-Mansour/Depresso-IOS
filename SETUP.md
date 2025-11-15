# Depresso - Complete Setup Guide

This guide walks you through setting up Depresso from scratch.

## Quick Start (5 minutes)

```bash
# 1. Clone the repository
git clone https://github.com/ElAmir-Mansour/Depresso-IOS.git
cd Depresso-IOS

# 2. Setup backend
cd depresso-backend
npm install
cp .env.example .env
# Edit .env with your credentials
npm start

# 3. Setup iOS app
cd ..
open Depresso.xcodeproj
# Update BackendClients.swift with your IP
# Build and run in Xcode
```

## Detailed Setup

### Part 1: Backend Server (15 minutes)

#### 1.1 Install Dependencies

```bash
cd depresso-backend
npm install
```

#### 1.2 Setup MongoDB

**Option A: Local MongoDB**
```bash
# Install MongoDB
brew install mongodb-community

# Start MongoDB
brew services start mongodb-community

# Your URI: mongodb://localhost:27017/depresso
```

**Option B: MongoDB Atlas (Cloud)**
1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Create free cluster
3. Get connection string
4. Use it in .env as MONGODB_URI

#### 1.3 Configure Environment Variables

Create `.env` file:
```bash
cp .env.example .env
```

Edit `.env` with your credentials:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Database
MONGODB_URI=mongodb://localhost:27017/depresso

# Huawei Cloud Configuration
HUAWEI_AUTH_TOKEN=your_token_here
HUAWEI_REGION=ap-southeast-1
HUAWEI_PROJECT_ID=your_project_id
QWEN_API_KEY=your_api_key
QWEN_ENDPOINT=https://qwen-max.ap-southeast-1.myhuaweicloud.com

# Security
JWT_SECRET=your_random_secret_here_change_in_production

# CORS (your computer's IP)
ALLOWED_ORIGINS=http://localhost:3000,http://192.168.1.100:3000
```

#### 1.4 Get Huawei Cloud Credentials

**Method 1: Automated Script**
```bash
node scripts/get-huawei-token.js
```

**Method 2: Manual (from browser)**
1. Go to [Huawei Cloud Console](https://console-intl.huaweicloud.com)
2. Login with your account
3. Open Browser DevTools (F12) → Network tab
4. Click any Huawei service
5. Find request → Headers → Copy `X-Auth-Token`
6. Paste in `.env` file

**Note**: Token expires in 24 hours. Renew when needed.

#### 1.5 Start the Server

```bash
# Development mode (auto-reload)
npm run dev

# Production mode
npm start
```

Verify it's running:
```bash
curl http://localhost:3000/health
# Should return: {"status":"ok","timestamp":"..."}
```

#### 1.6 Test API Endpoints

```bash
# Test Qwen AI
curl -X POST http://localhost:3000/api/ai-chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello","userId":"test123"}'

# Should return AI response
```

---

### Part 2: iOS App (10 minutes)

#### 2.1 Prerequisites

- macOS 13.0+ (Ventura or later)
- Xcode 15.0+
- iOS device or simulator (iOS 15.0+)
- Apple Developer account (free tier works)

#### 2.2 Open Project

```bash
cd /path/to/Depresso-IOS
open Depresso.xcodeproj
```

#### 2.3 Install Swift Packages

Xcode will automatically resolve Swift Package Manager dependencies:
- ComposableArchitecture
- Firebase SDK

If packages don't download:
1. File → Packages → Reset Package Caches
2. File → Packages → Resolve Package Versions

#### 2.4 Configure Backend URL

1. Open `Depresso/Clients/BackendClients.swift`
2. Find your Mac's IP address:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
3. Update the baseURL:
   ```swift
   private let baseURL = "http://YOUR_IP:3000/api"
   // Example: "http://192.168.1.100:3000/api"
   ```

#### 2.5 Add Firebase (Optional but recommended)

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project or use existing
3. Add iOS app with bundle ID: `com.depresso.app`
4. Download `GoogleService-Info.plist`
5. Drag it into Xcode project (add to Depresso target)

#### 2.6 Enable HealthKit

Already configured, but verify:
1. Select Depresso project
2. Select Depresso target
3. Signing & Capabilities tab
4. Check "HealthKit" capability is enabled

#### 2.7 Configure Signing

1. Select Depresso target
2. Signing & Capabilities tab
3. Team: Select your Apple Developer account
4. Bundle Identifier: Keep as is or change to unique ID

#### 2.8 Build and Run

1. Select target device (your iPhone or simulator)
2. Press ⌘R or click Run button
3. App should build and launch

#### 2.9 Grant Permissions

On first launch:
1. Allow HealthKit access
2. Complete PHQ-8 questionnaire
3. Explore the app!

---

### Part 3: Testing the Connection (5 minutes)

#### 3.1 Verify Backend is Accessible from iOS

From your Mac terminal:
```bash
# Get your IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Test backend is accessible
curl http://YOUR_IP:3000/health
```

#### 3.2 Test from iOS App

1. Open app on iPhone
2. Go to Journal tab
3. Send a test message: "Hello"
4. Should receive AI response within 2-3 seconds

If it fails:
- Check backend is running: `curl http://YOUR_IP:3000/health`
- Verify IP address matches in BackendClients.swift
- Check firewall allows port 3000
- Ensure iPhone and Mac are on same WiFi network

---

## Troubleshooting

### Backend Issues

**"Cannot connect to MongoDB"**
```bash
# Check MongoDB is running
brew services list | grep mongodb

# Restart MongoDB
brew services restart mongodb-community
```

**"Invalid Huawei token"**
- Token expired (lasts 24 hours)
- Run: `node scripts/get-huawei-token.js` to get new token

**"Port 3000 already in use"**
```bash
# Find process using port 3000
lsof -ti:3000

# Kill it
kill -9 $(lsof -ti:3000)

# Or change PORT in .env
```

### iOS Issues

**"Cannot connect to server"**
1. Verify backend is running
2. Check IP address is correct in BackendClients.swift
3. Ping server from Terminal:
   ```bash
   ping YOUR_IP
   ```
4. Test with curl:
   ```bash
   curl http://YOUR_IP:3000/health
   ```

**"No such module 'ComposableArchitecture'"**
1. File → Packages → Reset Package Caches
2. File → Packages → Resolve Package Versions
3. Clean build folder: Shift+⌘+K
4. Rebuild: ⌘+B

**"HealthKit not available"**
- HealthKit only works on physical devices
- Use simulator for non-HealthKit testing
- For full testing, use real iPhone

**"Failed to load PHQ-8 questions"**
- Backend might not be running
- Check network connectivity
- Verify API endpoint in BackendClients.swift

### Network Issues

**"App says offline but backend is running"**

Check firewall:
```bash
# macOS firewall might block connections
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /path/to/node
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /path/to/node
```

**"Can't connect from iPhone but curl works on Mac"**
- iPhone and Mac must be on same WiFi network
- Some routers block device-to-device communication
- Try mobile hotspot as alternative
- Check router settings for "AP Isolation" and disable it

---

## Environment-Specific Setup

### Development
- Use `npm run dev` for auto-reload
- Set `NODE_ENV=development` in .env
- Enable debug logging

### Production
- Use `npm start` for stable server
- Set `NODE_ENV=production` in .env
- Configure proper MongoDB instance
- Use environment variables for secrets
- Set up proper CORS origins
- Enable HTTPS

---

## Next Steps

After successful setup:

1. **Complete onboarding** in the app
2. **Take PHQ-8 assessment** to establish baseline
3. **Grant HealthKit permissions** for full functionality
4. **Explore features**:
   - Dashboard with health metrics
   - AI-powered journal
   - Community support
   - Goal tracking
5. **Monitor health data** syncing from Apple Health

---

## Getting Help

- **GitHub Issues**: [Report bugs or request features](https://github.com/ElAmir-Mansour/Depresso-IOS/issues)
- **Discussions**: Ask questions in GitHub Discussions
- **Documentation**: Check `/docs` folder for detailed guides

---

## Common Workflows

### Daily Development

```bash
# Terminal 1: Backend server
cd depresso-backend
npm run dev

# Terminal 2: Monitor logs
tail -f depresso-backend/server.log

# Xcode: Run iOS app
# Make changes, hot reload works on backend
```

### Updating Huawei Token

```bash
cd depresso-backend
node scripts/get-huawei-token.js
# Copy new token to .env
# Restart server
```

### Resetting Data

```bash
# Clear MongoDB
mongosh
use depresso
db.dropDatabase()

# Reset iOS app
# Delete app from iPhone and reinstall
```

---

**Setup complete! 🎉 You're ready to use Depresso.**
