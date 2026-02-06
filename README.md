# Depresso - AI-Powered Mental Health Companion 🧠💙

<div align="center">

![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**An intelligent iOS application for mental health research, depression monitoring, and AI-powered support using Google Gemini AI and comprehensive data analytics.**

[Features](#-features) • [Architecture](#️-architecture) • [Installation](#-installation) • [API Docs](API_DOCUMENTATION.md) • [Deployment](DEPLOYMENT_GUIDE.md)

</div>

---

## 📱 Overview

**Depresso** is a comprehensive mental health research platform combining an iOS app with a powerful backend and analytics dashboard. It uses **Google Gemini AI** for intelligent journal responses, HealthKit integration for holistic health tracking, and provides researchers with real-time analytics through a beautiful dark-themed dashboard.

### 🎯 Key Highlights
- ✅ **Gemini AI Integration**: Advanced conversational AI with RAG for empathetic journal responses
- ✅ **Research Dashboard**: Dark-themed analytics platform with real-time data visualization
- ✅ **PHQ-8 Assessment**: Validated depression screening questionnaire
- ✅ **10+ Health Metrics**: Real-time tracking via Apple HealthKit
- ✅ **Research Lab**: Mood tracking with cognitive distortion analysis
- ✅ **Community Support**: Anonymous sharing platform with moderation
- ✅ **Modern Architecture**: SwiftUI + TCA (iOS), Node.js/Express + PostgreSQL (Backend)

---

## ✨ Features

### 🏥 Health Integration
**Comprehensive HealthKit Tracking:**
- 🚶 Daily steps and distance
- ❤️ Heart rate and HRV
- 😴 Sleep duration and quality
- 🔥 Active energy burned
- 🏃 Exercise minutes
- 🧘 Mindfulness sessions
- 📊 Stand hours
- 💧 Water intake
- 🍎 Nutrition data
- 🎧 Headphone audio levels

**Real-time Sync**: Automatic background updates with privacy-first approach

### 🤖 AI-Powered Journal (Google Gemini)
**Intelligent Conversational Companion:**
- 💬 Natural conversations powered by **Gemini 2.5 Flash**
- 🧠 Contextual understanding with conversation history
- ❤️ Empathetic, therapeutic responses
- 🔒 Privacy-focused: All data encrypted
- ⚡ Real-time responses with 30s timeout
- 📝 CBT distortion detection and analysis

### 🔬 Research Lab
**Evidence-Based Mood Tracking:**
- 📋 Daily research prompts
- 😊 Sentiment analysis (Positive/Neutral/Negative)
- 🏷️ Custom tagging system
- 🧠 CBT cognitive distortion tracking
- 📈 Longitudinal data collection
- 🌈 Rich text input with emoji support

### 📊 Research Analytics Dashboard
**Real-Time Data Visualization:**
- 🌙 **Dark cyberpunk theme** with glassmorphism
- 📈 Interactive Chart.js visualizations
- 👥 User demographics and engagement metrics
- 😊 Sentiment analysis over time
- 🧠 CBT distortion frequency and trends
- 📋 PHQ-8 assessment distribution
- 📥 CSV data export functionality
- 🔄 Auto-refresh every 30 seconds

**Access Dashboard**: `http://localhost:3001`

### 📋 PHQ-8 Depression Assessment
**Clinically Validated Screening:**
- ✅ 8 scientifically validated questions
- 📊 Severity scoring (None/Mild/Moderate/Severe)
- 📈 Historical score tracking
- 🎯 Personalized insights based on results
- 🔔 Anonymous data for research purposes

### 👥 Community Support
**Safe Anonymous Sharing:**
- 💭 Share experiences anonymously
- 👍 Like and comment on posts
- 🚫 Report inappropriate content
- 👮 Moderator review system
- 🔒 Privacy-preserving architecture

### 📈 Progress Tracking
**Holistic Wellness Monitoring:**
- 🔥 Daily streaks and achievements
- 📊 Mood trends visualization
- 🎯 Personalized goal setting
- 🏆 Milestone celebrations
- 📅 Activity calendar

---

## 🏗️ Architecture

### System Overview
```
┌─────────────────┐
│   iOS App       │
│   (SwiftUI)     │
│                 │
│  - TCA State    │
│  - HealthKit    │
│  - Core Data    │
└────────┬────────┘
         │ HTTP/REST
         ↓
┌─────────────────┐      ┌──────────────┐
│  Node.js API    │─────→│  PostgreSQL  │
│  (Express)      │      │   Database   │
│                 │      └──────────────┘
│  - Auth         │
│  - Research     │      ┌──────────────┐
│  - Journal      │─────→│  Gemini API  │
│  - Community    │      │  (AI/RAG)    │
└────────┬────────┘      └──────────────┘
         │
         ↓
┌─────────────────┐
│   Dashboard     │
│   (HTML/JS)     │
│                 │
│  - Chart.js     │
│  - Real-time    │
│  - Dark Theme   │
└─────────────────┘
```

### Tech Stack

**iOS Application**
- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Architecture**: The Composable Architecture (TCA)
- **Persistence**: Core Data
- **Health Data**: HealthKit
- **Networking**: URLSession with custom APIClient

**Backend Server**
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: PostgreSQL 14+
- **AI Service**: Google Gemini API (gemini-2.5-flash)
- **Security**: bcrypt, input validation

**Research Dashboard**
- **Frontend**: Vanilla HTML/CSS/JavaScript
- **Charts**: Chart.js 4.4
- **Server**: Express (port 3001)
- **Design**: Dark theme with glassmorphism

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed system design.

---

## 📥 Installation

### Prerequisites
- **iOS Development**:
  - Xcode 15.0+
  - iOS 15.0+ device/simulator
  - Apple Developer account
  
- **Backend**:
  - Node.js 18+
  - PostgreSQL 14+
  - Google Gemini API key

### Quick Start

#### 1. Clone Repository
```bash
git clone https://github.com/ElAmir-Mansour/Depresso-IOS.git
cd Depresso-IOS
```

#### 2. Backend Setup
```bash
cd depresso-backend

# Install dependencies
npm install

# Setup environment variables
cp .env.example .env
# Edit .env and add:
# - GEMINI_API_KEY=your_gemini_api_key
# - DB_* credentials

# Run database migrations
psql -U postgres -d depresso_db -f migrations/001_initial_schema.sql
# ... run all migrations in order

# Start backend server
npm run dev
# Server runs on http://localhost:3000
```

#### 3. Dashboard Setup
```bash
# In depresso-backend directory
node dashboard-server.js
# Dashboard runs on http://localhost:3001
```

#### 4. iOS App Setup
```bash
# Open Xcode project
open Depresso.xcodeproj

# Update APIClient.swift with your Mac's IP
# File: Features/Dashboard/APIClient.swift
# Line 10: static let baseURL = "http://YOUR_MAC_IP:3000/api/v1"

# Run on device/simulator
# Cmd + R
```

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed instructions.

---

## 🔑 Environment Variables

Create `depresso-backend/.env`:
```env
# Google Gemini AI
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-2.5-flash

# Database
DB_USER=postgres
DB_HOST=localhost
DB_DATABASE=depresso_db
DB_PASSWORD=your_password
DB_PORT=5432

# Server
PORT=3000
```

---

## 📸 Screenshots

### iOS App
- **Journal AI**: Chat with empathetic Gemini AI
- **Research Lab**: Daily mood tracking with rich prompts
- **Dashboard**: Health metrics from HealthKit
- **PHQ-8**: Depression screening assessment
- **Community**: Share and connect anonymously

### Research Dashboard
- **Dark Theme**: Modern cyberpunk aesthetic
- **Overview**: Real-time stats (users, entries, assessments)
- **CBT Analysis**: Cognitive distortion tracking
- **Sentiment**: Mood trends over time
- **Export**: Download CSV data

---

## 🔌 API Documentation

### Base URL
```
http://localhost:3000/api/v1
```

### Key Endpoints

**Authentication**
- `POST /auth/register` - Register new user
- `POST /auth/login` - User login

**Journal**
- `POST /journal/entries` - Create journal entry
- `POST /journal/entries/:id/messages` - Send message to AI
- `GET /journal/entries/:id/messages` - Get conversation history

**Research**
- `POST /research/entries` - Submit research entry
- `GET /research/stats` - Get research statistics
- `GET /research/distortions` - Get CBT distortion data
- `GET /research/sentiment` - Get sentiment analysis

**Community**
- `GET /community/posts` - Get all posts
- `POST /community/posts` - Create post
- `POST /community/posts/:id/like` - Like post

See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for complete API reference.

---

## 🧪 Testing

### Backend Tests
```bash
cd depresso-backend
npm test
```

### iOS Tests
```bash
# In Xcode
Cmd + U
```

---

## 🚀 Deployment

### Production Deployment
1. **Database**: PostgreSQL on cloud (AWS RDS, Google Cloud SQL)
2. **Backend**: Node.js on VPS or serverless (AWS Lambda, Google Cloud Run)
3. **Dashboard**: Static hosting (Netlify, Vercel) or same server as backend
4. **iOS App**: TestFlight → App Store

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for production deployment.

---

## 🔒 Privacy & Security

- ✅ **End-to-end encryption** for sensitive data
- ✅ **Anonymous research data** collection
- ✅ **HIPAA-compliant** data handling
- ✅ **User consent** required for all data collection
- ✅ **Local-first** architecture with optional sync
- ✅ **No third-party trackers**

---

## 🤝 Contributing

Contributions welcome! Please follow these steps:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and recent updates.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**El Amir Mansour**
- GitHub: [@ElAmir-Mansour](https://github.com/ElAmir-Mansour)

---

## 🙏 Acknowledgments

- **Google Gemini AI** for powerful conversational AI
- **Apple HealthKit** for comprehensive health data
- **Chart.js** for beautiful data visualization
- **The Composable Architecture** for robust state management
- Mental health research community for inspiration

---

<div align="center">

**Made with ❤️ for mental health awareness**

</div>
