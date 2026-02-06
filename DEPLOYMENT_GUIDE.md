# Deployment Guide

## Overview
This guide covers deploying the Depresso mental health research platform, including the iOS app, Node.js backend, PostgreSQL database, and research dashboard.

---

## Prerequisites

### Development Environment
- **macOS**: Ventura 13.0+ (for iOS development)
- **Xcode**: 15.0+
- **Node.js**: 18.0+
- **PostgreSQL**: 14.0+
- **Git**: 2.30+

### Required Accounts
- **Apple Developer Account** (for iOS deployment)
- **Google Cloud Account** (for Gemini API key)
- **GitHub Account** (for source code)

---

## Local Development Setup

### 1. Database Setup (PostgreSQL)

#### Install PostgreSQL
```bash
# macOS (Homebrew)
brew install postgresql@14
brew services start postgresql@14

# Verify installation
psql --version
```

#### Create Database
```bash
# Connect to PostgreSQL
psql postgres

# Create database
CREATE DATABASE depresso_db;

# Create user (optional)
CREATE USER depresso_admin WITH PASSWORD 'yourpassword';
GRANT ALL PRIVILEGES ON DATABASE depresso_db TO depresso_admin;

# Exit
\q
```

#### Run Migrations
```bash
cd depresso-backend

# Run all migrations in order
psql -U postgres -d depresso_db -f migrations/001_initial_schema.sql
psql -U postgres -d depresso_db -f migrations/002_add_journal_entries.sql
psql -U postgres -d depresso_db -f migrations/003_add_ai_chat_messages.sql
psql -U postgres -d depresso_db -f migrations/004_add_assessments.sql
psql -U postgres -d depresso_db -f migrations/005_add_community_posts.sql
psql -U postgres -d depresso_db -f migrations/006_add_community_comments_likes.sql
psql -U postgres -d depresso_db -f migrations/007_add_distortions.sql
psql -U postgres -d depresso_db -f migrations/008_add_sentiment.sql
psql -U postgres -d depresso_db -f migrations/009_add_research_entries.sql
psql -U postgres -d depresso_db -f migrations/010_fix_research_prompt_id.sql
```

#### Verify Database
```bash
psql -U postgres -d depresso_db

# List tables
\dt

# Should show:
# Users, JournalEntries, AIChatMessages, Assessments, 
# CommunityPosts, CommunityComments, CommunityLikes, ResearchEntries
```

---

### 2. Backend Setup (Node.js + Express)

#### Install Dependencies
```bash
cd depresso-backend
npm install
```

#### Configure Environment
```bash
# Copy example env file
cp .env.example .env

# Edit .env
nano .env
```

**Required .env Variables**:
```env
# Google Gemini AI
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-2.5-flash

# Database Configuration
DB_USER=postgres
DB_HOST=localhost
DB_DATABASE=depresso_db
DB_PASSWORD=postgres
DB_PORT=5432

# Server Configuration
PORT=3000
NODE_ENV=development

# Optional: AI System Prompt Override
AI_SYSTEM_PROMPT="You are a compassionate AI companion..."
```

#### Get Gemini API Key
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Click "Get API Key"
3. Copy API key to `.env` file

#### Start Backend Server
```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start

# Server should start on http://localhost:3000
```

#### Verify Backend
```bash
# Test health endpoint
curl http://localhost:3000/health

# Test stats endpoint
curl http://localhost:3000/api/v1/research/stats
```

---

### 3. Dashboard Setup

#### Start Dashboard Server
```bash
cd depresso-backend

# Start dashboard on port 3001
node dashboard-server.js

# Or run in background
node dashboard-server.js &
```

#### Access Dashboard
Open browser: `http://localhost:3001`

**Features**:
- 📊 Overview stats
- 😊 Sentiment analysis
- 🧠 CBT distortions
- 📋 PHQ-8 assessments
- 📝 Research entries
- 👥 Community stats
- 📥 CSV export

---

### 4. iOS App Setup

#### Open Project
```bash
cd /path/to/Depresso-IOS-main
open Depresso.xcodeproj
```

#### Configure API Base URL

##### For Simulator
**File**: `Features/Dashboard/APIClient.swift`
```swift
enum APIConfig {
    static let baseURL = "http://localhost:3000/api/v1"
}
```

##### For Physical Device
1. Get your Mac's IP address:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
# Example output: 192.168.1.2
```

2. Update `APIClient.swift`:
```swift
enum APIConfig {
    static let baseURL = "http://192.168.1.2:3000/api/v1"
}
```

#### Configure HealthKit
1. Select project in Xcode
2. Go to "Signing & Capabilities"
3. Enable "HealthKit"
4. Add required capabilities

#### Run App
1. Select target device (simulator or physical device)
2. Press `Cmd + R` to build and run
3. Accept HealthKit permissions when prompted

---

## Production Deployment

### Backend Deployment (Cloud)

#### Option 1: Google Cloud Run
```bash
# Install gcloud CLI
brew install google-cloud-sdk

# Login
gcloud auth login

# Build container
gcloud builds submit --tag gcr.io/YOUR_PROJECT/depresso-backend

# Deploy
gcloud run deploy depresso-backend \
  --image gcr.io/YOUR_PROJECT/depresso-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars GEMINI_API_KEY=your_key,DB_HOST=your_db_host
```

#### Option 2: AWS EC2
```bash
# SSH into EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Clone repo
git clone https://github.com/ElAmir-Mansour/Depresso-IOS.git
cd Depresso-IOS/depresso-backend

# Install dependencies
npm install

# Setup environment
cp .env.example .env
nano .env  # Add production values

# Install PM2 for process management
sudo npm install -g pm2

# Start server
pm2 start src/app.js --name depresso-backend
pm2 startup
pm2 save

# Setup nginx reverse proxy
sudo apt-get install nginx
# Configure nginx to proxy port 80 to 3000
```

#### Option 3: Heroku
```bash
# Install Heroku CLI
brew tap heroku/brew && brew install heroku

# Login
heroku login

# Create app
heroku create depresso-backend

# Add PostgreSQL
heroku addons:create heroku-postgresql:mini

# Set environment variables
heroku config:set GEMINI_API_KEY=your_key
heroku config:set GEMINI_MODEL=gemini-2.5-flash

# Deploy
git push heroku main

# Run migrations
heroku run bash
psql $DATABASE_URL -f migrations/001_initial_schema.sql
```

---

### Database Deployment

#### Option 1: Google Cloud SQL
```bash
# Create instance
gcloud sql instances create depresso-db \
  --database-version=POSTGRES_14 \
  --tier=db-f1-micro \
  --region=us-central1

# Create database
gcloud sql databases create depresso_db --instance=depresso-db

# Get connection string
gcloud sql connections describe depresso-db
```

#### Option 2: AWS RDS
1. Go to AWS Console → RDS
2. Create PostgreSQL database
3. Choose version 14+
4. Configure security groups
5. Note connection endpoint
6. Update backend `.env` with RDS credentials

---

### Dashboard Deployment

#### Option 1: Static Hosting (Netlify)
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
cd depresso-backend
netlify deploy --dir=. --prod
```

#### Option 2: Same Server as Backend
Dashboard already configured to run on port 3001. Access via:
```
https://your-backend-url:3001
```

---

### iOS App Deployment

#### TestFlight (Beta Testing)
1. **Archive App**:
   - Xcode → Product → Archive
   - Wait for build to complete

2. **Upload to App Store Connect**:
   - Click "Distribute App"
   - Select "App Store Connect"
   - Upload

3. **Configure TestFlight**:
   - Go to App Store Connect
   - Select app → TestFlight
   - Add internal/external testers
   - Send invites

#### App Store Release
1. **Prepare App Store Listing**:
   - Screenshots (iOS 15+)
   - App description
   - Keywords
   - Privacy policy URL

2. **Submit for Review**:
   - App Store Connect → My Apps
   - Select version → Submit for Review
   - Answer questionnaire

3. **Release**:
   - Wait for approval (~24-48 hours)
   - Release manually or auto-release

---

## Environment-Specific Configuration

### Development
```env
NODE_ENV=development
PORT=3000
DB_HOST=localhost
```

### Staging
```env
NODE_ENV=staging
PORT=3000
DB_HOST=staging-db.example.com
GEMINI_API_KEY=staging_key
```

### Production
```env
NODE_ENV=production
PORT=3000
DB_HOST=prod-db.example.com
GEMINI_API_KEY=production_key
```

---

## Monitoring & Logging

### Backend Logging
```bash
# View logs
pm2 logs depresso-backend

# Or with tail
tail -f logs/app.log
```

### Database Monitoring
```bash
# Check active connections
psql -d depresso_db -c "SELECT count(*) FROM pg_stat_activity;"

# Check database size
psql -d depresso_db -c "SELECT pg_size_pretty(pg_database_size('depresso_db'));"
```

---

## Backup & Recovery

### Database Backups
```bash
# Manual backup
pg_dump depresso_db > backup_$(date +%Y%m%d).sql

# Restore
psql depresso_db < backup_20260206.sql

# Automated backups (cron)
0 2 * * * pg_dump depresso_db > /backups/depresso_$(date +\%Y\%m\%d).sql
```

---

## Security Checklist

- [ ] Use HTTPS in production
- [ ] Set strong database passwords
- [ ] Rotate Gemini API keys regularly
- [ ] Enable database encryption at rest
- [ ] Configure firewall rules
- [ ] Use environment variables (never hardcode secrets)
- [ ] Enable rate limiting
- [ ] Set up CORS properly
- [ ] Implement input validation
- [ ] Regular security updates

---

## Troubleshooting

### Backend won't start
```bash
# Check PostgreSQL is running
brew services list | grep postgresql

# Check port 3000 availability
lsof -i :3000

# Check logs
npm run dev
```

### iOS app "Network error"
1. Check backend is running: `curl http://localhost:3000/health`
2. Verify IP address in `APIClient.swift`
3. Check firewall settings
4. Ensure device and Mac on same network

### Dashboard not loading data
1. Check backend API: `curl http://localhost:3000/api/v1/research/stats`
2. Verify dashboard server running on port 3001
3. Check browser console for errors

---

## Performance Optimization

### Backend
- Enable gzip compression
- Add Redis caching layer
- Use connection pooling
- Optimize database queries
- Add database indices

### iOS App
- Implement pagination
- Cache API responses locally
- Lazy load images
- Background sync for HealthKit

---

## Support

For deployment issues:
1. Check [GitHub Issues](https://github.com/ElAmir-Mansour/Depresso-IOS/issues)
2. Review logs
3. Contact: [Your Email]
