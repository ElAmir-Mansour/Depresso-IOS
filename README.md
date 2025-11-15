# Depresso - AI-Powered Mental Health Companion 🧠💙

<div align="center">

![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Huawei Cloud](https://img.shields.io/badge/Powered%20by-Huawei%20Cloud-red.svg)

**An intelligent iOS application for depression detection, monitoring, and support using HealthKit integration and AI-powered insights.**

[Features](#features) • [Architecture](#architecture) • [Installation](#installation) • [Usage](#usage) • [Contributing](#contributing)

</div>

---

## 📱 Overview

**Depresso** is a comprehensive mental health companion app that leverages Apple HealthKit data and Huawei Cloud AI services to provide:

- 🧠 **Depression Risk Assessment** via validated PHQ-8 questionnaire
- 📊 **Real-time Health Monitoring** tracking sleep, activity, heart rate, and more
- 💬 **AI-Powered Journaling** with intelligent mood analysis
- 👥 **Community Support** for sharing experiences safely
- 📈 **Progress Tracking** with streaks, insights, and personalized recommendations
- 🎯 **Goal Setting** for mental wellness improvement

---

## ✨ Features

### 🏥 Health Integration
- **HealthKit Integration**: Tracks 10+ health metrics including:
  - Daily steps and active energy
  - Sleep duration and quality
  - Heart rate and HRV
  - Exercise minutes
  - Mindfulness sessions
  - Stand hours
- **Real-time Sync**: Automatic data updates from Apple Health

### 🤖 AI-Powered Insights
- **Huawei Qwen AI**: Advanced natural language processing for:
  - Intelligent journal responses
  - Mood pattern analysis
  - Personalized recommendations
  - Crisis detection and support
- **Depression Risk Analysis**: ML-based assessment combining PHQ-8 scores with health metrics

### 📊 Dashboard & Analytics
- **Beautiful Visualizations**: Charts and graphs for health trends
- **Streak Tracking**: Daily engagement rewards
- **Weekly Progress**: Comprehensive insights into wellness journey
- **Quick Stats**: At-a-glance health overview

### 💬 Journal & Community
- **AI Chat Journal**: Private, intelligent conversation partner
- **Mood Tracking**: Log and visualize emotional patterns
- **Community Posts**: Share experiences anonymously
- **Supportive Environment**: Safe space for mental health discussions

---

## 🏗️ Architecture

### iOS App (Swift + SwiftUI)
```
Depresso-iOS/
├── App/                    # Main app entry point
├── Features/
│   ├── Dashboard/          # Main dashboard with health metrics
│   ├── Journal/            # AI-powered journaling
│   ├── Community/          # Community support features
│   ├── Goals/              # Goal setting and tracking
│   ├── PHQ8/              # Depression assessment
│   └── Support/            # Help and resources
├── Depresso/
│   ├── Services/           # API clients and health services
│   ├── Models/             # Data models
│   └── Clients/            # Backend communication
└── Resources/              # Assets and configuration
```

### Backend (Node.js + Express)
```
depresso-backend/
├── routes/
│   ├── auth.js             # Authentication
│   ├── journal.js          # Journal entries
│   ├── community.js        # Community posts
│   ├── phq8.js            # PHQ-8 assessment
│   └── aiChat.js          # AI chat integration
├── services/
│   └── huaweiAI.js        # Huawei Cloud AI integration
└── server.js               # Main server
```

### Technology Stack

**iOS Frontend:**
- SwiftUI for modern, declarative UI
- Composable Architecture (TCA) for state management
- HealthKit for health data integration
- Firebase for analytics

**Backend:**
- Node.js + Express REST API
- MongoDB for data persistence
- Huawei Cloud ModelArts for AI
- Qwen LLM for natural language processing

**Cloud Services:**
- Huawei Cloud (AP-Southeast-1 region)
- Qwen-max LLM for chat responses
- ModelArts for depression analysis (planned)

---

## 🚀 Installation

### Prerequisites

- **iOS Development:**
  - macOS with Xcode 15+
  - iOS device or simulator (iOS 15.0+)
  - Apple Developer account (for HealthKit)
  - CocoaPods or Swift Package Manager

- **Backend:**
  - Node.js 16+ and npm
  - MongoDB instance
  - Huawei Cloud account

### iOS App Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ElAmir-Mansour/Depresso-IOS.git
   cd Depresso-IOS
   ```

2. **Install dependencies:**
   ```bash
   # Swift Package Manager dependencies are auto-resolved by Xcode
   open Depresso.xcodeproj
   ```

3. **Configure Firebase:**
   - Add your `GoogleService-Info.plist` to the project
   - Enable Analytics in Firebase Console

4. **Configure HealthKit:**
   - Enable HealthKit capability in Xcode
   - Add privacy descriptions in Info.plist (already configured)

5. **Update Backend URL:**
   - Open `Depresso/Clients/BackendClients.swift`
   - Update `baseURL` with your backend server address:
     ```swift
     private let baseURL = "http://YOUR_IP:3000/api"
     ```

6. **Build and Run:**
   - Select your target device
   - Build and run (⌘R)

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd depresso-backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Configure environment variables:**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` with your credentials:
   ```env
   PORT=3000
   MONGODB_URI=mongodb://localhost:27017/depresso
   
   # Huawei Cloud Configuration
   HUAWEI_AUTH_TOKEN=your_x_auth_token_here
   HUAWEI_REGION=ap-southeast-1
   HUAWEI_PROJECT_ID=your_project_id
   QWEN_API_KEY=your_qwen_api_key
   QWEN_ENDPOINT=https://qwen-max.ap-southeast-1.myhuaweicloud.com
   
   # JWT Secret
   JWT_SECRET=your_secure_random_secret
   ```

4. **Get Huawei Cloud Credentials:**
   ```bash
   # Run the token generator script
   node scripts/get-huawei-token.js
   ```

5. **Start the server:**
   ```bash
   npm start
   # Or for development with auto-reload:
   npm run dev
   ```

6. **Verify server is running:**
   ```bash
   curl http://localhost:3000/health
   # Should return: {"status":"ok","timestamp":"..."}
   ```

---

## 📖 Usage

### First Launch

1. **Onboarding**: Complete the welcome screens
2. **HealthKit Permissions**: Grant access to health data
3. **PHQ-8 Assessment**: Complete initial depression screening
4. **Dashboard**: View your health metrics and insights

### Daily Use

**Dashboard:**
- View health metrics and trends
- Check your daily streak
- Read AI-generated insights
- Monitor progress towards goals

**Journal:**
- Write private journal entries
- Chat with AI for support and guidance
- Track mood patterns over time

**Community:**
- Read supportive posts from others
- Share your experiences anonymously
- Engage with community members

**Goals:**
- Set wellness goals
- Track progress
- Receive motivational insights

**Support:**
- Access crisis resources
- Find professional help
- Read mental health articles

---

## 🔒 Privacy & Security

- **Local Storage**: Sensitive data encrypted on-device
- **Anonymous Community**: Posts don't include personal information
- **HIPAA Considerations**: Health data handled according to best practices
- **Secure Communication**: HTTPS for all API calls
- **Data Ownership**: Users control their data

---

## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. **Fork the repository**
2. **Create a feature branch:**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit your changes:**
   ```bash
   git commit -m 'Add some amazing feature'
   ```
4. **Push to the branch:**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open a Pull Request**

### Development Guidelines

- Follow Swift style guide
- Write unit tests for new features
- Update documentation
- Ensure code builds without warnings
- Test on physical iOS devices

---

## 🐛 Known Issues

- [ ] PHQ-8 analysis occasionally fails on first app launch (investigating)
- [ ] Weekly insights may not load if no data for the week
- [ ] Community posts pagination needs optimization

See [Issues](https://github.com/ElAmir-Mansour/Depresso-IOS/issues) for full list.

---

## 🗺️ Roadmap

- [ ] **Enhanced ML Models**: Deploy custom depression detection models on Huawei ModelArts
- [ ] **Apple Watch App**: Extend monitoring to watchOS
- [ ] **Medication Reminders**: Track and remind medication schedules
- [ ] **Therapist Integration**: Connect with mental health professionals
- [ ] **Export Reports**: Generate PDF reports for healthcare providers
- [ ] **Multi-language Support**: Internationalization
- [ ] **Dark Mode Enhancements**: Improved dark theme
- [ ] **Offline Mode**: Full functionality without internet

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👏 Acknowledgments

- **Huawei Cloud**: For providing AI infrastructure and developer competition support
- **PHQ-8**: Validated depression screening tool
- **Open Source Community**: For amazing libraries and tools
- **Mental Health Advocates**: For guidance on sensitive topics

---

## 📞 Contact & Support

- **Developer**: ElAmir Mansour
- **GitHub**: [@ElAmir-Mansour](https://github.com/ElAmir-Mansour)
- **Issues**: [GitHub Issues](https://github.com/ElAmir-Mansour/Depresso-IOS/issues)

### Crisis Resources

If you're in crisis, please reach out:
- **National Suicide Prevention Lifeline**: 988 (US)
- **Crisis Text Line**: Text HOME to 741741
- **International**: [Find help in your country](https://findahelpline.com)

---

## ⚠️ Disclaimer

**Depresso is not a substitute for professional medical advice, diagnosis, or treatment.** Always seek the advice of qualified health providers with questions regarding medical conditions. If you're experiencing a mental health crisis, contact emergency services or crisis helplines immediately.

---

<div align="center">

**Made with ❤️ for mental health awareness**

⭐ Star this repo if you find it helpful!

</div>
