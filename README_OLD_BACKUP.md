# 🌟 Depresso - AI-Powered Mental Health Companion

<div align="center">

**A comprehensive iOS mental health application leveraging AI, HealthKit integration, and real-time mood tracking**

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)](https://www.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Huawei Cloud](https://img.shields.io/badge/Powered%20by-Huawei%20Cloud-red.svg)](https://www.huaweicloud.com/)

[Features](#-features) • [Architecture](#-architecture) • [Installation](#-installation) • [Usage](#-usage) • [Huawei Cloud Integration](#-huawei-cloud-integration)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [Technology Stack](#-technology-stack)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Huawei Cloud Integration](#-huawei-cloud-integration)
- [API Documentation](#-api-documentation)
- [Project Structure](#-project-structure)
- [Screenshots](#-screenshots)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌈 Overview

**Depresso** is an innovative mental health companion app that combines the power of artificial intelligence with comprehensive health monitoring to provide users with personalized mental health support. Built for iOS and powered by Huawei Cloud services, Depresso offers real-time mood tracking, AI-driven journaling, community support, and evidence-based depression screening through PHQ-8 assessments.

### Why Depresso?

- **Privacy-First**: Your mental health data stays secure with end-to-end encryption
- **AI-Powered Insights**: Leverage advanced AI models from Huawei Cloud ModelArts
- **Holistic Approach**: Integrates physical health metrics from Apple HealthKit
- **Evidence-Based**: Uses clinically validated PHQ-8 depression screening
- **Community Support**: Connect with others on similar journeys (anonymous)

---

## ✨ Features

### 🧠 Core Features

#### 1. **AI Companion Journal**
- Real-time conversational AI powered by Huawei Qwen models
- Context-aware responses based on mood and health data
- Secure, encrypted journal entries
- Smart insights and pattern recognition

#### 2. **PHQ-8 Depression Assessment**
- Clinically validated screening tool
- Personalized risk analysis
- Progress tracking over time
- Actionable recommendations

#### 3. **Health Metrics Dashboard**
- **Activity Tracking**: Steps, active energy, exercise minutes
- **Sleep Monitoring**: Sleep duration, quality analysis
- **Heart Health**: Heart rate, HRV monitoring
- **Mood Correlation**: Connects physical health with mental wellness
- Real-time sync with Apple HealthKit

#### 4. **Smart Analytics**
- Weekly progress reports
- AI-generated insights
- Trend visualization
- Streak counter for motivation

#### 5. **Community Support**
- Anonymous community posts
- Share experiences and coping strategies
- Peer support system
- Moderated for safety

#### 6. **Personalized Goals**
- Custom goal setting
- Progress tracking
- Achievement system
- Motivational reminders

### 🎨 Design Features

- **Modern UI/UX**: Clean, accessible design following iOS Human Interface Guidelines
- **Dark Mode Support**: Full dark mode implementation
- **Animations**: Smooth, meaningful animations for better UX
- **Accessibility**: VoiceOver support, Dynamic Type, high contrast modes
- **Custom Tab Bar**: Intuitive navigation with haptic feedback

---

## 🏗 Architecture

Depresso follows a clean, modular architecture built on **The Composable Architecture (TCA)** for predictable state management and testability.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         iOS App Layer                        │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐   │
│  │   Dashboard   │  │    Journal    │  │   Community   │   │
│  │    Feature    │  │    Feature    │  │    Feature    │   │
│  └───────┬───────┘  └───────┬───────┘  └───────┬───────┘   │
│          │                   │                   │           │
│  ┌───────┴───────────────────┴───────────────────┴───────┐  │
│  │              TCA State Management Layer                │  │
│  │         (Composable Architecture + Effects)            │  │
│  └───────────────────────────┬─────────────────────────────┘  │
└────────────────────────────────┬──────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │   Backend API Layer     │
                    │   (Node.js + Express)   │
                    └────────────┬────────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
┌───────┴───────┐      ┌─────────┴────────┐   ┌──────────┴─────────┐
│ PostgreSQL DB │      │  Huawei Cloud    │   │   Apple HealthKit  │
│  - User Data  │      │  - Qwen AI Model │   │  - Health Metrics  │
│  - Journals   │      │  - ModelArts     │   │  - Activity Data   │
│  - PHQ-8      │      │  - Authentication│   │  - Sleep Data      │
└───────────────┘      └──────────────────┘   └────────────────────┘
```

### Key Architectural Patterns

- **TCA (The Composable Architecture)**: For state management and side effects
- **Repository Pattern**: For data access abstraction
- **Dependency Injection**: For testability and modularity
- **Clean Architecture**: Separation of concerns across layers

---

## 🛠 Technology Stack

### iOS (Frontend)

| Technology | Purpose |
|-----------|---------|
| **Swift 5.9** | Primary programming language |
| **SwiftUI** | Declarative UI framework |
| **TCA** | State management & architecture |
| **HealthKit** | Health data integration |
| **Combine** | Reactive programming |
| **URLSession** | Network requests |

### Backend

| Technology | Purpose |
|-----------|---------|
| **Node.js** | Runtime environment |
| **Express.js** | Web framework |
| **PostgreSQL** | Relational database |
| **JWT** | Authentication |
| **bcrypt** | Password hashing |

### Huawei Cloud Services

| Service | Purpose |
|---------|---------|
| **ModelArts** | AI model hosting & inference |
| **Qwen API** | Large language model for conversations |
| **IAM** | Identity & access management |

---

## 📦 Installation

### Prerequisites

- **Xcode 15.0+** with iOS 16.0+ SDK
- **Node.js 18+** and npm
- **PostgreSQL 14+**
- **Swift Package Manager**
- **Huawei Cloud Account** (for AI features)
- **Apple Developer Account** (for HealthKit)

### Backend Setup

1. **Clone the repository**
```bash
git clone https://github.com/ElAmir-Mansour/Depresso-IOS.git
cd Depresso-IOS/depresso-backend
```

2. **Install dependencies**
```bash
npm install
```

3. **Configure PostgreSQL**
```bash
# Create database
createdb depresso_db

# Run migrations
psql depresso_db < schema.sql
psql depresso_db < seed.sql
```

4. **Configure environment variables**
```bash
cp .env.example .env
# Edit .env with your configurations
```

Required environment variables:
```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/depresso_db

# JWT
JWT_SECRET=your_super_secret_jwt_key_change_this

# Huawei Cloud
HUAWEI_API_KEY=your_huawei_api_key
HUAWEI_API_SECRET=your_huawei_api_secret
HUAWEI_PROJECT_ID=your_project_id
HUAWEI_AUTH_TOKEN=your_x_auth_token
HUAWEI_REGION=ap-southeast-1
QWEN_API_ENDPOINT=https://qwen-plus.ap-southeast-1.myhuaweicloud.com
```

5. **Start the server**
```bash
npm start
# Server runs on http://localhost:3000
```

### iOS App Setup

1. **Open the project**
```bash
cd Depresso-IOS
open Depresso.xcodeproj
```

2. **Install Swift Package Dependencies**
   - Xcode will automatically resolve dependencies
   - Required packages:
     - The Composable Architecture
     - Firebase (Analytics, optional)

3. **Configure HealthKit**
   - Enable HealthKit capability in Xcode
   - Add required permissions to `Info.plist`:
```xml
<key>NSHealthShareUsageDescription</key>
<string>Depresso needs access to your health data to provide personalized insights</string>
<key>NSHealthUpdateUsageDescription</key>
<string>Depresso would like to update your health data</string>
```

4. **Configure API Endpoint**
   - Update `BackendClients.swift` with your server URL:
```swift
private static let baseURL = "http://YOUR_IP_ADDRESS:3000"
```

5. **Build and Run**
   - Select your device or simulator
   - Press `Cmd + R` to build and run

---

## ⚙️ Configuration

### Getting Your IP Address (for local testing)

**macOS:**
```bash
ipconfig getifaddr en0
# or for Wi-Fi
ipconfig getifaddr en1
```

**Update Backend URL in iOS app:**
```swift
// In BackendClients.swift
private static let baseURL = "http://192.168.1.XXX:3000"
```

### Huawei Cloud Setup

#### 1. Obtain X-Auth-Token

Run the token generation script:
```bash
cd depresso-backend
chmod +x update-token.sh
./update-token.sh
```

Or get it manually:
1. Go to [Huawei Cloud Console](https://console-intl.huaweicloud.com)
2. Open DevTools (F12) → Network tab
3. Make any API request
4. Copy `X-Auth-Token` from request headers

#### 2. Configure Qwen API

1. Go to ModelArts → Qwen Service
2. Enable API access
3. Copy endpoint URL and API key
4. Update `.env` file

---

## 🚀 Usage

### First Launch

1. **PHQ-8 Assessment**: Complete initial depression screening
2. **HealthKit Permission**: Grant access to health data
3. **Dashboard Setup**: View your personalized dashboard

### Daily Use

#### Journaling
- Tap "Journal" tab
- Start conversation with AI companion
- Share your thoughts, feelings, or ask questions
- AI provides supportive responses

#### Track Progress
- View health metrics on Dashboard
- Check streak counter
- Review weekly insights
- Monitor PHQ-8 score trends

#### Community
- Read anonymous stories
- Share your experiences
- Find support and encouragement

#### Goals
- Set personal wellness goals
- Track progress
- Celebrate achievements

---

## ☁️ Huawei Cloud Integration

### Overview

Depresso leverages Huawei Cloud's powerful AI and infrastructure services to deliver intelligent, scalable mental health support.

### Key Integrations

#### 1. **Qwen AI Model**
```javascript
// AI conversation endpoint
POST /api/chat/ai
{
  "message": "I'm feeling anxious today",
  "userId": "user_id"
}

// Response includes:
// - AI-generated supportive response
// - Contextual understanding
// - Mood analysis
```

**Model Details:**
- Model: Qwen-Plus / Qwen-Max
- Region: ap-southeast-1 (Singapore)
- Features: Context awareness, mental health specialization

#### 2. **ModelArts Integration**
- Future: Depression risk prediction models
- Health metric analysis
- Pattern recognition in mood data

### API Endpoints (Backend)

#### Authentication
```
POST /api/auth/register - Register new user
POST /api/auth/login    - User login
```

#### PHQ-8 Assessment
```
POST /api/assessment/submit     - Submit PHQ-8 answers
GET  /api/assessment/history    - Get assessment history
GET  /api/assessment/analysis   - Get AI analysis
```

#### Journal
```
POST /api/chat/ai              - Send message to AI
GET  /api/journal/entries      - Get journal entries
POST /api/journal/entry        - Create journal entry
```

#### Health Metrics
```
POST /api/health/sync          - Sync HealthKit data
GET  /api/health/metrics       - Get health metrics
GET  /api/health/summary       - Get weekly summary
```

#### Community
```
GET  /api/community/posts      - Get community posts
POST /api/community/post       - Create new post
POST /api/community/react      - React to post
```

---

## 📁 Project Structure

```
Depresso-IOS/
├── App/
│   ├── DepressoApp.swift          # App entry point
│   ├── AppFeature.swift           # Root TCA feature
│   └── ContentView.swift          # Main content view
│
├── Features/
│   ├── Dashboard/
│   │   ├── DashboardFeature.swift
│   │   ├── DashboardView.swift
│   │   ├── HealthMetric.swift
│   │   ├── StreakCounter.swift
│   │   └── Core/Design System/
│   │
│   ├── Journal/
│   │   ├── AICompanionJournalFeature.swift
│   │   ├── JournalView.swift
│   │   └── Components/
│   │
│   ├── Community/
│   ├── Assessment/
│   ├── Goals/
│   └── SplashScreen/
│
├── Resources/
├── BackendClients.swift
│
└── depresso-backend/
    ├── src/
    │   ├── routes/
    │   ├── middleware/
    │   └── config/
    ├── migrations/
    └── package.json
```

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Areas for Contribution

- 🐛 Bug fixes
- ✨ New features
- 📝 Documentation improvements
- 🎨 UI/UX enhancements
- 🌐 Internationalization
- ♿️ Accessibility improvements

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Huawei Cloud** for providing powerful AI and cloud infrastructure
- **The Composable Architecture** community for the amazing framework
- **Apple HealthKit** for health data integration
- Mental health professionals who provided guidance on features
- Open source community for various libraries and tools

---

## 📞 Contact & Support

- **Developer**: Amir Mansour
- **GitHub**: [@ElAmir-Mansour](https://github.com/ElAmir-Mansour)
- **Project Link**: [https://github.com/ElAmir-Mansour/Depresso-IOS](https://github.com/ElAmir-Mansour/Depresso-IOS)

### Need Help?

- 🐛 Report bugs via [Issues](https://github.com/ElAmir-Mansour/Depresso-IOS/issues)
- 💬 Join discussions in [Discussions](https://github.com/ElAmir-Mansour/Depresso-IOS/discussions)

---

## ⚠️ Disclaimer

Depresso is designed to support mental wellness and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition. If you are in crisis, please contact emergency services or a crisis helpline immediately.

---

<div align="center">

**Made with ❤️ for mental health awareness**

**Powered by Huawei Cloud**

⭐ Star this repo if you find it helpful! ⭐

</div>
