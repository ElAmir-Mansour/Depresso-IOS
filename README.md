# Depresso - AI-Powered Mental Health Companion 🧠💙

<div align="center">

![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Huawei Cloud](https://img.shields.io/badge/Powered%20by-Huawei%20Cloud-red.svg)

**An intelligent iOS application for depression detection, monitoring, and support using HealthKit integration and Huawei Cloud AI services.**

[Features](#-features) • [Architecture](#️-architecture) • [Installation](#-installation) • [Demo](#-demo) • [Contributing](#-contributing)

</div>

---

## 📱 Overview

**Depresso** is a comprehensive mental health companion app built for the Huawei Cloud Developer Competition. It leverages Apple HealthKit data and Huawei Cloud AI services (Qwen) to provide personalized mental health insights, support, and tracking.

### 🎯 Key Highlights
- ✅ **Validated Assessment**: PHQ-8 questionnaire for depression screening
- ✅ **10+ Health Metrics**: Real-time tracking via HealthKit
- ✅ **Huawei Qwen AI**: Advanced conversational AI for journaling
- ✅ **Community Support**: Safe, anonymous sharing platform
- ✅ **Progress Tracking**: Streaks, insights, and goal management
- ✅ **Beautiful UI**: Modern SwiftUI design with custom animations

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

### 🤖 AI-Powered Insights (Huawei Cloud)
**Qwen AI Integration:**
- 💬 Intelligent journal responses with emotional awareness
- 🎭 Mood pattern analysis and visualization
- 📝 Personalized mental health recommendations
- 🚨 Crisis detection with immediate support resources
- 🧠 Context-aware conversations leveraging health data

**Depression Risk Analysis:**
- Combines PHQ-8 scores with health metrics
- ML-based risk assessment (Huawei ModelArts ready)
- Weekly trend analysis and predictions

### 📊 Dashboard & Analytics
**Beautiful Visualizations:**
- 📈 Interactive charts for health trends
- 🔥 Streak tracking with milestone rewards
- 📅 Weekly progress summaries
- ⚡ Quick stats widgets
- 🎯 Goal progress indicators
- 💡 AI-generated weekly insights

### 💬 Journal & Community
**AI Chat Journal:**
- Private conversations with Qwen AI
- Mood tracking and pattern recognition
- Secure, encrypted storage
- Export capabilities

**Community Features:**
- Anonymous posting system
- Upvote/comment functionality
- Content moderation
- Supportive environment guidelines

### 🎯 Goals & Support
**Goal Management:**
- Customizable wellness goals
- Progress tracking and reminders
- Achievement system
- Personalized suggestions

**Support Resources:**
- Crisis hotlines (international)
- Professional help finder
- Educational content
- Self-care tips

---

## 🏗️ Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        iOS App (Swift)                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │Dashboard │  │ Journal  │  │Community │  │   PHQ8   │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │             │              │             │          │
│  ┌────┴─────────────┴──────────────┴─────────────┴─────┐   │
│  │           Backend API Client (HTTP)                  │   │
│  └──────────────────────────┬───────────────────────────┘   │
│  ┌──────────────────────────┴───────────────────────────┐   │
│  │              HealthKit Manager                       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                               │
                               │ HTTPS/REST
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 Backend (Node.js + Express)                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   Auth   │  │ Journal  │  │Community │  │  PHQ8    │   │
│  │  Routes  │  │  Routes  │  │  Routes  │  │  Routes  │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │             │              │             │          │
│  ┌────┴─────────────┴──────────────┴─────────────┴─────┐   │
│  │            PostgreSQL Database (Cloud)               │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Huawei AI Service Integration                │   │
│  └────────────────────────┬─────────────────────────────┘   │
└────────────────────────────┼─────────────────────────────────┘
                             │ API Call
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    Huawei Cloud Services                     │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Qwen AI (ModelArts) - Conversational Intelligence  │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Agent App Dev - ML Model Integration (Future)      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### iOS App Structure
```
Depresso-iOS/
├── App/
│   ├── DepressoApp.swift          # Main app entry point
│   └── AppState.swift              # Global state management
├── Features/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   ├── DashboardFeature.swift
│   │   ├── HealthMetric.swift
│   │   ├── StreakCounter.swift
│   │   └── Core/                   # Design system components
│   ├── Journal/
│   │   ├── JournalView.swift
│   │   ├── JournalFeature.swift
│   │   └── MessageView.swift
│   ├── Community/
│   │   ├── CommunityView.swift
│   │   └── CommunityFeature.swift
│   ├── Goals/
│   │   ├── GoalsView.swift
│   │   └── GoalsFeature.swift
│   ├── PHQ8/
│   │   ├── PHQ8View.swift
│   │   └── PHQ8Feature.swift
│   └── Support/
│       └── SupportView.swift
├── Depresso/
│   ├── Services/
│   │   ├── HealthKitManager.swift
│   │   └── BackendClient.swift
│   ├── Models/
│   │   ├── HealthData.swift
│   │   ├── JournalEntry.swift
│   │   └── CommunityPost.swift
│   └── Clients/
│       └── APIClient.swift
└── Resources/
    ├── Assets.xcassets
    └── GoogleService-Info.plist
```

### Backend Structure
```
depresso-backend/
├── routes/
│   ├── auth.js                    # User authentication
│   ├── journal.js                 # Journal CRUD operations
│   ├── community.js               # Community posts management
│   ├── phq8.js                   # PHQ-8 assessment
│   └── aiChat.js                 # Huawei Qwen AI integration
├── services/
│   ├── huaweiAI.js               # Huawei Cloud API wrapper
│   └── depressionAnalysis.js     # ML model integration (future)
├── models/
│   ├── User.js
│   ├── JournalEntry.js
│   └── CommunityPost.js
├── middleware/
│   └── auth.js
├── .env                           # Environment configuration
├── package.json
└── server.js                      # Main server file
```

### Technology Stack

**iOS App:**
- Swift 5.9 / SwiftUI
- ComposableArchitecture (TCA) for state management
- HealthKit for health data
- Firebase Analytics
- Combine framework

**Backend:**
- Node.js 18+ / Express.js
- PostgreSQL (Cloud or Local)
- Huawei Cloud Qwen API
- JWT authentication
- CORS enabled

**Huawei Cloud Services:**
- Qwen AI (ModelArts) - Conversational AI
- Agent App Dev - ML model deployment (ready for integration)
- Cloud hosting capabilities

---

## 🚀 Installation

### Prerequisites
- macOS Monterey or later
- Xcode 15.0+
- iOS 15.0+ device or simulator
- Node.js 18+ and npm
- PostgreSQL database
- Huawei Cloud account with Qwen API access

### 1️⃣ Clone Repository
```bash
git clone https://github.com/ElAmir-Mansour/Depresso-IOS.git
cd Depresso-IOS
```

### 2️⃣ Backend Setup

#### Install Dependencies
```bash
cd depresso-backend
npm install
```

#### Configure Environment
Create `.env` file:
```env
PORT=3000
DB_USER=your_db_user
DB_HOST=your_db_host
DB_DATABASE=your_db_name
DB_PASSWORD=your_db_password
DB_PORT=5432

# Huawei Cloud Configuration
HUAWEI_API_KEY=your_qwen_api_key
HUAWEI_API_SECRET=your_api_secret
HUAWEI_REGION=ap-southeast-1
HUAWEI_PROJECT_ID=your_project_id

# Optional: ModelArts Integration
MODELARTS_API_ENDPOINT=your_endpoint
HUAWEI_AUTH_TOKEN=your_auth_token

# Server Configuration
NODE_ENV=development
```

#### Start Server
```bash
npm start
# Server runs on http://localhost:3000
```

### 3️⃣ iOS App Setup

#### Install Dependencies
Open Xcode and resolve Swift Package Manager dependencies:
- File → Packages → Resolve Package Versions

**Required Packages:**
- ComposableArchitecture
- Firebase SDK

#### Configure Backend URL
Update `BackendClient.swift`:
```swift
// For simulator (local development)
private let baseURL = "http://localhost:3000"

// For physical device (replace with your Mac's IP)
private let baseURL = "http://192.168.1.XXX:3000"
```

To find your Mac's IP:
```bash
ipconfig getifaddr en0
```

#### Configure Firebase (Optional)
Add your `GoogleService-Info.plist` to the project root.

#### Build and Run
1. Open `Depresso.xcodeproj` in Xcode
2. Select your target device
3. Press `Cmd + R` to build and run

### 4️⃣ Add Files to Xcode (If Needed)
If you see missing file errors:
1. Right-click on project folder → "Add Files to Depresso"
2. Select missing files from `Features/` directory
3. Ensure "Copy items if needed" is checked
4. Add to Depresso target

---

## 🎮 Usage

### First Launch
1. **PHQ-8 Assessment**: Complete the initial depression screening
2. **HealthKit Permissions**: Grant access to health data
3. **Dashboard**: View your health metrics and insights
4. **Journal**: Start conversing with AI for emotional support

### Daily Use
- **Morning**: Check your streak and daily goals
- **Throughout Day**: Log mood and activities
- **Evening**: Review progress and journal reflections
- **Weekly**: View AI-generated insights and trends

### Features Guide

**Dashboard:**
- View real-time health metrics
- Track daily streaks
- See weekly progress summaries
- Access quick actions

**Journal:**
- Chat with Qwen AI about your feelings
- AI analyzes patterns and provides support
- Review past entries
- Export journal data

**Community:**
- Share experiences anonymously
- Support others through comments
- Upvote helpful posts
- Report inappropriate content

**Goals:**
- Set personalized wellness targets
- Track progress with visual indicators
- Receive AI-powered recommendations
- Celebrate achievements

**Support:**
- Access crisis hotlines
- Find professional help
- Learn about mental health
- Get self-care tips

---

## 📊 PHQ-8 Assessment

The Patient Health Questionnaire-8 (PHQ-8) is a validated tool for depression screening:

**Scoring:**
- 0-4: Minimal depression
- 5-9: Mild depression
- 10-14: Moderate depression
- 15-19: Moderately severe depression
- 20-24: Severe depression

**Note**: This is a screening tool, not a diagnostic instrument. Always consult healthcare professionals.

---

## 🔐 Privacy & Security

- **End-to-End Encryption**: All health data is encrypted
- **Local Storage**: Sensitive data stored locally with Keychain
- **Anonymous Community**: No personal identifiers in posts
- **HIPAA Compliant**: Following healthcare privacy standards
- **Data Ownership**: Users control their data export/deletion

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Workflow
1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

### Code Standards
- Follow Swift style guide
- Write unit tests for new features
- Update documentation
- Run linters before committing

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

---

## 🏆 Huawei Cloud Integration

This project is built for the **Huawei Cloud Developer Competition** and showcases:

### Current Integrations
✅ **Qwen AI (ModelArts)**: Advanced conversational AI for mental health support
✅ **Cloud Infrastructure**: Scalable backend deployment
✅ **API Gateway**: Secure service communication

### Future Enhancements
🔜 **Agent App Dev**: Custom ML agents for depression prediction
🔜 **ModelArts**: Train custom models on health + mood data
🔜 **Function Graph**: Serverless background processing
🔜 **OBS**: Secure data storage and backup

### Technical Benefits
- **Low Latency**: AP-Southeast region deployment
- **High Availability**: 99.9% uptime SLA
- **Cost Efficient**: Pay-as-you-go model
- **Scalable**: Auto-scaling capabilities

---

## 📞 Support & Contact

- **Issues**: [GitHub Issues](https://github.com/ElAmir-Mansour/Depresso-IOS/issues)
- **Email**: support@depresso-app.com
- **Documentation**: [Wiki](https://github.com/ElAmir-Mansour/Depresso-IOS/wiki)

---

## 🙏 Acknowledgments

- **Huawei Cloud**: For providing AI services and infrastructure
- **Apple HealthKit**: For comprehensive health data access
- **PHQ-8**: Developed by Pfizer Inc.
- **Open Source Community**: For amazing tools and libraries

---

## 📸 Screenshots

<div align="center">

| Dashboard | Journal | Community | PHQ-8 |
|-----------|---------|-----------|-------|
| ![Dashboard](docs/screenshots/dashboard.png) | ![Journal](docs/screenshots/journal.png) | ![Community](docs/screenshots/community.png) | ![PHQ8](docs/screenshots/phq8.png) |

</div>

---

## 🔄 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

<div align="center">

**Built with ❤️ for mental health awareness**

[⭐ Star this repo](https://github.com/ElAmir-Mansour/Depresso-IOS) • [🐛 Report Bug](https://github.com/ElAmir-Mansour/Depresso-IOS/issues) • [✨ Request Feature](https://github.com/ElAmir-Mansour/Depresso-IOS/issues)

</div>
