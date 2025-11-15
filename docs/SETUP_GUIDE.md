# Depresso Setup Guide

Complete step-by-step guide to set up the Depresso iOS app and backend server.

---

## 📋 Prerequisites

Before you begin, ensure you have:

- ✅ macOS 13.0+ (for iOS development)
- ✅ Xcode 15.0+
- ✅ iOS 16.0+ device or simulator
- ✅ Node.js 18+ and npm
- ✅ PostgreSQL 14+
- ✅ Huawei Cloud account
- ✅ Apple Developer account (for HealthKit)

---

## 🚀 Quick Start (5 Minutes)

### 1. Clone Repository
```bash
git clone https://github.com/ElAmir-Mansour/Depresso-IOS.git
cd Depresso-IOS
```

### 2. Backend Setup
```bash
cd depresso-backend
npm install
```

Create `.env` file:
```env
PORT=3000
DATABASE_URL=postgresql://postgres:password@localhost:5432/depresso_db
JWT_SECRET=your_secret_key_here
HUAWEI_AUTH_TOKEN=your_token_here
QWEN_API_ENDPOINT=https://qwen-plus.ap-southeast-1.myhuaweicloud.com
```

Setup database:
```bash
createdb depresso_db
psql depresso_db < schema.sql
npm start
```

### 3. iOS App Setup
```bash
cd ..
open Depresso.xcodeproj
```

- Update `BackendClients.swift` with your IP address
- Build and run (⌘R)

---

## 📦 Detailed Setup

### Part 1: Backend Server Setup

#### Step 1: Install Node.js Dependencies

```bash
cd depresso-backend
npm install
```

Expected output:
```
added 127 packages in 8s
```

#### Step 2: PostgreSQL Database Setup

**Install PostgreSQL** (if not installed):
```bash
brew install postgresql@14
brew services start postgresql@14
```

**Create Database:**
```bash
createdb depresso_db
```

**Verify database creation:**
```bash
psql -l | grep depresso
```

**Run migrations:**
```bash
psql depresso_db < schema.sql
psql depresso_db < seed.sql
```

**Verify tables:**
```bash
psql depresso_db
\dt
# Should show: users, assessments, journal_entries, health_metrics, community_posts, goals
\q
```

#### Step 3: Environment Configuration

Create `.env` file:
```bash
cp .env.example .env
nano .env
```

Fill in the values:
```env
# Server
PORT=3000
NODE_ENV=development

# Database
DATABASE_URL=postgresql://postgres:your_password@localhost:5432/depresso_db

# JWT (generate a secure random string)
JWT_SECRET=change_this_to_a_long_random_string_min_32_chars

# Huawei Cloud
HUAWEI_AUTH_TOKEN=your_x_auth_token
HUAWEI_REGION=ap-southeast-1
HUAWEI_PROJECT_ID=your_project_id
QWEN_API_ENDPOINT=https://qwen-plus.ap-southeast-1.myhuaweicloud.com
```

**Generate JWT Secret:**
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

#### Step 4: Get Huawei Cloud Token

**Option A: Using the script**
```bash
chmod +x update-token.sh
./update-token.sh
```

**Option B: Manual**
1. Visit https://console-intl.huaweicloud.com
2. Login with your credentials
3. Open DevTools (F12) → Network tab
4. Click any service
5. Find request in Network tab
6. Copy `X-Auth-Token` from headers
7. Paste into `.env` file

#### Step 5: Start the Server

```bash
npm start
```

Expected output:
```
Server running on port 3000
Database connected successfully
Huawei Cloud services initialized
```

**Test the server:**
```bash
curl http://localhost:3000/health
# Should return: {"status":"ok","timestamp":"..."}
```

---

### Part 2: iOS App Setup

#### Step 1: Open Xcode Project

```bash
cd /path/to/Depresso-IOS
open Depresso.xcodeproj
```

#### Step 2: Install Swift Package Dependencies

Xcode will automatically resolve packages. If not:

1. Go to **File** → **Swift Packages** → **Resolve Package Versions**
2. Wait for resolution to complete

Required packages:
- `swift-composable-architecture` (TCA)
- `firebase-ios-sdk` (optional for analytics)

#### Step 3: Configure Backend URL

Find your Mac's IP address:
```bash
ipconfig getifaddr en0
# Example output: 192.168.1.100
```

**Edit `BackendClients.swift`:**
```swift
private static let baseURL = "http://192.168.1.100:3000"
// Replace with YOUR IP address
```

#### Step 4: Configure HealthKit

**Enable HealthKit capability:**
1. Select project in Xcode
2. Select **Depresso** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **HealthKit**

**Verify Info.plist:**
Ensure these keys exist:
```xml
<key>NSHealthShareUsageDescription</key>
<string>Depresso needs access to your health data to provide personalized mental health insights</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Depresso would like to save your health data</string>
```

#### Step 5: Configure Signing

1. Select **Depresso** target
2. Go to **Signing & Capabilities**
3. Select your **Team**
4. Update **Bundle Identifier** if needed

#### Step 6: Build and Run

1. Select your device or simulator from the top toolbar
2. Press **⌘R** or click the **Play** button
3. Wait for build to complete
4. App should launch on device/simulator

---

## 🧪 Testing the Setup

### Test 1: Health Check
```bash
curl http://localhost:3000/health
```
Expected: `{"status":"ok"}`

### Test 2: Register User
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123!",
    "name": "Test User"
  }'
```

### Test 3: AI Chat (requires auth token)
```bash
# First login to get token
TOKEN=$(curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TestPass123!"}' \
  | jq -r '.token')

# Then test AI chat
curl -X POST http://localhost:3000/api/chat/ai \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"message":"Hello, I need support"}'
```

### Test 4: iOS App
1. Launch app on device/simulator
2. Complete PHQ-8 assessment
3. Try sending a message in Journal tab
4. Check Dashboard for health metrics
5. Visit Community tab

---

## 🔧 Troubleshooting

### Issue 1: "Cannot connect to server"

**Symptoms:** iOS app shows "offline" or connection error

**Solutions:**
1. Verify server is running: `curl http://localhost:3000/health`
2. Check IP address is correct in `BackendClients.swift`
3. Ensure iPhone and Mac are on same Wi-Fi network
4. Check firewall settings (allow port 3000)

```bash
# On Mac, allow port
sudo pfctl -d  # Disable firewall temporarily for testing
```

### Issue 2: "Database connection failed"

**Symptoms:** Server crashes with database error

**Solutions:**
1. Verify PostgreSQL is running:
   ```bash
   brew services list | grep postgresql
   ```
2. Check database exists:
   ```bash
   psql -l | grep depresso
   ```
3. Verify DATABASE_URL in `.env`
4. Test connection:
   ```bash
   psql $DATABASE_URL
   ```

### Issue 3: "Huawei Cloud API error"

**Symptoms:** AI chat returns error

**Solutions:**
1. Check token expiration (tokens last 24 hours)
2. Refresh token: `./update-token.sh`
3. Verify endpoint URL in `.env`
4. Check Huawei Cloud service status

### Issue 4: "HealthKit permission denied"

**Symptoms:** No health data on Dashboard

**Solutions:**
1. Go to iPhone **Settings** → **Privacy** → **Health**
2. Find **Depresso** app
3. Enable all requested permissions
4. Restart app

### Issue 5: Swift Package resolution failed

**Symptoms:** Xcode can't resolve packages

**Solutions:**
1. **File** → **Swift Packages** → **Reset Package Cache**
2. **File** → **Swift Packages** → **Resolve Package Versions**
3. Restart Xcode
4. Delete `~/Library/Developer/Xcode/DerivedData`

### Issue 6: Build errors

**Common errors and fixes:**

**"Cannot find 'ComposableArchitecture' in scope"**
- Ensure TCA package is added
- Clean build folder (⇧⌘K)
- Rebuild

**"Missing package product"**
- Check Package Dependencies in project settings
- Verify package versions

**"Code signing error"**
- Select your development team
- Update Bundle Identifier
- Trust your developer certificate on device

---

## 📱 First Run Checklist

After successful setup, verify:

- [ ] Server running on `http://localhost:3000`
- [ ] Database accessible with test data
- [ ] Huawei Cloud token valid
- [ ] iOS app builds without errors
- [ ] Can complete PHQ-8 assessment
- [ ] AI chat responds to messages
- [ ] HealthKit data syncing
- [ ] Dashboard showing metrics
- [ ] Community posts loading

---

## 🔄 Daily Development Workflow

### Starting Work
```bash
# Terminal 1: Start backend
cd depresso-backend
npm start

# Terminal 2: Monitor logs
tail -f depresso-backend/logs/app.log
```

### Xcode
1. Open `Depresso.xcodeproj`
2. Select device/simulator
3. Build and run (⌘R)

### Stopping
```bash
# Backend: Ctrl+C in terminal
# Xcode: Stop button or ⌘.
```

---

## 🔐 Security Notes

### Before Deploying to Production:

1. **Change all default secrets:**
   - Generate new JWT_SECRET
   - Use strong database passwords
   - Rotate Huawei Cloud tokens

2. **Enable HTTPS:**
   - Get SSL certificate
   - Configure reverse proxy (nginx/Apache)
   - Update iOS app URL to `https://`

3. **Database security:**
   - Use connection pooling
   - Enable SSL for database connections
   - Implement rate limiting

4. **API security:**
   - Add rate limiting
   - Implement request validation
   - Enable CORS properly

---

## 📚 Next Steps

After setup complete:

1. Read [API Documentation](API_DOCUMENTATION.md)
2. Review [Huawei Cloud Integration](../HUAWEI_CLOUD_INTEGRATION.md)
3. Explore [Architecture Documentation](../ARCHITECTURE.md)
4. Check [Contributing Guidelines](../CONTRIBUTING.md)

---

## 💬 Need Help?

- 📖 Check [Troubleshooting Guide](#-troubleshooting)
- 🐛 [Report an Issue](https://github.com/ElAmir-Mansour/Depresso-IOS/issues)
- 💬 [Start a Discussion](https://github.com/ElAmir-Mansour/Depresso-IOS/discussions)

---

**Setup successful? Star the repo! ⭐**
