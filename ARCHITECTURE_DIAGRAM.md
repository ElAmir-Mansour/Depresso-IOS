# Depresso - Architecture Diagram

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DEPRESSO iOS APPLICATION                           │
│                          (SwiftUI + TCA Architecture)                        │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        │                             │                             │
        ▼                             ▼                             ▼
┌───────────────┐            ┌────────────────┐           ┌──────────────────┐
│   HEALTHKIT   │            │  USER INPUTS   │           │   LOCAL STORAGE  │
│   FRAMEWORK   │            │                │           │                  │
├───────────────┤            ├────────────────┤           ├──────────────────┤
│ • Steps       │            │ • PHQ-8 Score  │           │ • UserDefaults   │
│ • Heart Rate  │            │ • Journal      │           │ • Core Data      │
│ • Sleep Hours │            │ • Mood Logs    │           │ • Keychain       │
│ • Active Cal  │            │ • Goals        │           │ • Cached Data    │
│ • Workouts    │            │ • Community    │           │                  │
└───────────────┘            └────────────────┘           └──────────────────┘
        │                             │                             │
        └─────────────────────────────┼─────────────────────────────┘
                                      │
                                      │ HTTPS (192.168.1.100:3000)
                                      ▼
        ┌─────────────────────────────────────────────────────────────┐
        │              NODE.JS BACKEND SERVER (Express)                │
        │                    (Local Network Server)                    │
        └─────────────────────────────────────────────────────────────┘
                                      │
                 ┌────────────────────┼────────────────────┐
                 │                    │                    │
                 ▼                    ▼                    ▼
        ┌────────────────┐   ┌───────────────┐   ┌──────────────────┐
        │  POSTGRESQL DB │   │  JWT AUTH     │   │  API ENDPOINTS   │
        │                │   │  MIDDLEWARE   │   │                  │
        ├────────────────┤   ├───────────────┤   ├──────────────────┤
        │ • Users        │   │ • Token Gen   │   │ • /api/auth/*    │
        │ • Journal      │   │ • Token       │   │ • /api/journal/* │
        │ • Entries      │   │   Validation  │   │ • /api/health/*  │
        │ • Health Data  │   │ • Refresh     │   │ • /api/ai/*      │
        │ • Community    │   │   Tokens      │   │ • /api/goals/*   │
        │ • Posts        │   │               │   │ • /api/community*│
        └────────────────┘   └───────────────┘   └──────────────────┘
                                      │
                                      │
                 ┌────────────────────┴────────────────────┐
                 │                                         │
                 ▼                                         ▼
        ┌─────────────────────────┐          ┌──────────────────────────┐
        │   HUAWEI CLOUD QWEN     │          │  FIREBASE (Optional)     │
        │   AI MODEL (14B)        │          │                          │
        ├─────────────────────────┤          ├──────────────────────────┤
        │ Endpoint:               │          │ • Analytics              │
        │ qwen-plus-14b.          │          │ • Crash Reporting        │
        │ ap-southeast-1.         │          │ • Remote Config          │
        │ ai.cloud-servicestage   │          │                          │
        │                         │          │                          │
        │ Features:               │          │                          │
        │ • AI Chat Support       │          │                          │
        │ • Journal Analysis      │          │                          │
        │ • Mental Health         │          │                          │
        │   Insights              │          │                          │
        │ • Personalized          │          │                          │
        │   Recommendations       │          │                          │
        │ • Depression Risk       │          │                          │
        │   Assessment            │          │                          │
        └─────────────────────────┘          └──────────────────────────┘
```

---

## Detailed Component Breakdown

### 1. iOS Application Layer (Frontend)

#### Features:
- **Dashboard**: Real-time health metrics, AI insights, streak tracking, progress rings
- **Journal**: AI-powered journaling with mood tracking
- **Goals**: Personalized goal setting and tracking
- **Community**: Peer support and shared experiences
- **Support**: AI chatbot for immediate help
- **Profile**: User management and settings

#### Technologies:
- **SwiftUI**: Declarative UI framework
- **The Composable Architecture (TCA)**: State management
- **HealthKit**: iOS health data integration
- **URLSession**: Network requests
- **Combine**: Reactive programming

---

### 2. Backend Server Layer

#### Core Services:
```
src/
├── api/
│   ├── auth.js          # Authentication endpoints
│   ├── journal.js       # Journal CRUD operations
│   ├── health.js        # Health data processing
│   ├── goals.js         # Goal management
│   ├── community.js     # Community posts
│   └── ai.js            # AI chat integration
├── config/
│   ├── database.js      # PostgreSQL config
│   └── auth.js          # JWT configuration
└── services/
    └── (custom services)
```

#### Technologies:
- **Node.js + Express**: Backend framework
- **PostgreSQL**: Primary database
- **JWT**: Authentication tokens
- **bcrypt**: Password hashing
- **cors**: Cross-origin resource sharing

---

### 3. Huawei Cloud Integration

#### Qwen AI Model (14B Parameters)

**Integration Points:**

1. **AI Chat Support** (Support Tab)
   - Real-time conversational AI
   - Mental health guidance
   - Crisis support responses
   - Endpoint: `/api/ai/chat`

2. **Journal Analysis**
   - Sentiment analysis on entries
   - Mood pattern detection
   - Depression risk indicators
   - Personalized insights

3. **Dashboard AI Insights**
   - Weekly mental health summaries
   - Behavioral pattern analysis
   - Predictive recommendations
   - Correlation analysis (sleep, activity, mood)

**API Configuration:**
```
Endpoint: https://qwen-plus-14b.ap-southeast-1.ai.cloud-servicestage.com/v1/chat/completions
API Key: d066a07f7e5a7e71fe3f5c7d86e9a00d
Model: qwen-plus-14b
Region: ap-southeast-1 (Singapore)
```

**Impact Areas:**
- ✅ Enhanced user engagement through intelligent conversations
- ✅ Personalized mental health insights
- ✅ Real-time support availability 24/7
- ✅ Pattern recognition in health data
- ✅ Early warning system for depression risk

---

### 4. Data Flow Architecture

#### Health Data Flow:
```
HealthKit → iOS App → Backend → PostgreSQL
                            ↓
                    Huawei Qwen AI
                            ↓
                    AI Insights → Dashboard
```

#### Journal Entry Flow:
```
User Input → iOS App → Backend → PostgreSQL
                            ↓
                    Huawei Qwen AI
                            ↓
            Sentiment Analysis + Recommendations
                            ↓
                    iOS App (Display)
```

#### AI Chat Flow:
```
User Message → iOS App → Backend → Huawei Qwen API
                                         ↓
                            AI Response Processing
                                         ↓
                            iOS App (Display)
```

---

### 5. Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     SECURITY LAYERS                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Transport Layer Security (TLS/HTTPS)                    │
│     • All network communication encrypted                   │
│                                                              │
│  2. Authentication Layer (JWT)                              │
│     • Token-based authentication                            │
│     • Refresh token mechanism                               │
│     • 24-hour token expiration                              │
│                                                              │
│  3. Authorization Layer                                     │
│     • User-specific data access                             │
│     • API endpoint protection                               │
│                                                              │
│  4. Data Protection                                         │
│     • Passwords hashed with bcrypt                          │
│     • Sensitive data in iOS Keychain                        │
│     • Environment variables for secrets                     │
│                                                              │
│  5. Huawei Cloud Security                                   │
│     • API key authentication                                │
│     • Regional endpoint isolation                           │
│     • Rate limiting                                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

### 6. HealthKit Metrics Integration

#### Collected Metrics:
1. **Activity Metrics**
   - Daily Steps
   - Active Energy (Calories)
   - Exercise Minutes
   - Stand Hours
   - Distance Walked

2. **Vital Signs**
   - Heart Rate (Resting, Active)
   - Heart Rate Variability (HRV)
   - Respiratory Rate
   - Blood Oxygen (SpO2)

3. **Sleep Metrics**
   - Sleep Duration
   - Sleep Quality
   - Time in Bed
   - Sleep Stages (Deep, REM, Core)

4. **Mental Wellness Indicators**
   - Mindful Minutes
   - Time in Daylight

#### Impact on Depression Detection:
- Sleep patterns correlation with mood
- Activity levels as depression indicators
- Heart rate variability for stress detection
- AI-powered pattern recognition via Huawei Qwen

---

### 7. Huawei Cloud Competitive Advantage

#### Why Huawei Qwen AI?

1. **Model Superiority**
   - 14B parameters (large language model)
   - Multilingual support
   - Context-aware responses
   - Mental health domain knowledge

2. **Regional Performance**
   - ap-southeast-1 (Singapore) - Low latency
   - High availability SLA
   - Data residency compliance

3. **Cost Efficiency**
   - Competitive pricing vs OpenAI/Anthropic
   - Pay-per-use model
   - No minimum commitment

4. **Integration Benefits**
   - RESTful API (easy integration)
   - JSON response format
   - Streaming support for real-time chat
   - Rate limiting for cost control

5. **Competition Alignment**
   - Showcases Huawei Cloud AI capabilities
   - Demonstrates real-world AI application
   - Mental health + AI innovation
   - Cloud-native architecture

---

### 8. Scalability Architecture

```
Current State:
┌─────────────┐      ┌──────────────┐      ┌────────────────┐
│  iOS App    │ ───→ │  Local Node  │ ───→ │  Huawei Qwen   │
│  (Client)   │      │  Server      │      │  AI (Cloud)    │
└─────────────┘      └──────────────┘      └────────────────┘

Future State (Production):
┌─────────────┐      ┌──────────────────┐      ┌────────────────┐
│  iOS App    │ ───→ │  Huawei Cloud    │ ───→ │  Huawei Qwen   │
│  (Client)   │      │  ECS (Backend)   │      │  AI Service    │
└─────────────┘      └──────────────────┘      └────────────────┘
                             │
                             ├──→ PostgreSQL (RDS)
                             ├──→ Redis (Cache)
                             ├──→ OBS (Object Storage)
                             └──→ Load Balancer
```

---

### 9. Monitoring & Analytics

#### Tracked Metrics:
1. **User Engagement**
   - Daily active users
   - Feature usage patterns
   - Session duration
   - Retention rate

2. **AI Performance**
   - Qwen API response times
   - Token usage
   - Chat success rate
   - Sentiment analysis accuracy

3. **Health Outcomes**
   - PHQ-8 score trends
   - Streak maintenance
   - Goal completion rates
   - Community engagement

4. **Technical Metrics**
   - API latency
   - Error rates
   - Database performance
   - Network reliability

---

### 10. Future Enhancements

#### Planned Integrations:

1. **Huawei ModelArts**
   - Custom depression detection model
   - Train on user data (anonymized)
   - Real-time risk prediction
   - Personalized intervention timing

2. **Huawei Agent Service**
   - Multi-agent workflow
   - Specialized mental health agents
   - Automated care coordination
   - Crisis detection and response

3. **Additional Huawei Services**
   - OBS for media storage
   - FunctionGraph for serverless
   - DMS for async messaging
   - CloudEye for monitoring

---

## Technology Stack Summary

### Frontend (iOS)
- Swift 5.9+
- SwiftUI
- The Composable Architecture (TCA)
- HealthKit
- Combine

### Backend (Server)
- Node.js 18+
- Express.js
- PostgreSQL 14+
- JWT Authentication

### Cloud Services (Huawei)
- Qwen AI (14B Model)
- Region: ap-southeast-1
- Future: ModelArts, Agent Service, ECS, RDS

### Additional Services
- Firebase (Analytics, optional)
- Git (Version Control)

---

## Deployment Architecture

### Development Environment:
```
Local Machine (macOS)
├── Xcode (iOS Development)
├── Node.js Server (localhost:3000)
├── PostgreSQL (localhost:5432)
└── iPhone Device (Testing)
```

### Production Environment (Future):
```
Huawei Cloud (ap-southeast-1)
├── ECS Instance (Backend Server)
├── RDS for PostgreSQL (Database)
├── Qwen AI Service (AI Processing)
├── OBS (Media Storage)
├── ELB (Load Balancer)
└── CloudEye (Monitoring)
```

---

## Competition Highlights

### Huawei Cloud Integration Showcase:

1. ✅ **Qwen AI Integration** - Real-time mental health support
2. ✅ **Cloud-Native Architecture** - Scalable design
3. 🔄 **Agent Service Ready** - Extensible for multi-agent workflows
4. 🔄 **ModelArts Ready** - Custom ML model training
5. ✅ **Regional Deployment** - ap-southeast-1 optimized

### Innovation Points:

1. **AI-Powered Mental Health** - Not just tracking, but intelligent insights
2. **Holistic Approach** - Combines physical health (HealthKit) + mental wellness
3. **Proactive Intervention** - Early depression risk detection
4. **Community Support** - Peer-to-peer engagement
5. **Privacy-First** - Local data processing + secure cloud AI

---

## Key Differentiators

### vs Traditional Mental Health Apps:
- ✅ AI-powered personalized insights (Huawei Qwen)
- ✅ Real-time health data integration (HealthKit)
- ✅ Predictive analytics for depression risk
- ✅ 24/7 AI support availability
- ✅ Community-driven peer support

### vs Other AI Apps:
- ✅ Specialized for mental health (not general chatbot)
- ✅ Integrated health metrics correlation
- ✅ Evidence-based approach (PHQ-8 assessment)
- ✅ Huawei Cloud infrastructure (competition focus)
- ✅ Scalable architecture for production

---

## Conclusion

The Depresso app demonstrates effective integration of Huawei Cloud services (specifically Qwen AI) to solve real-world mental health challenges. The architecture is designed for scalability, security, and intelligent data processing, making it a strong candidate for the Huawei Innovation Competition.

**Key Impact of Huawei Cloud:**
- 🚀 Enhanced user experience through AI conversations
- 📊 Intelligent pattern recognition in health data
- 🎯 Personalized mental health recommendations
- ⚡ Low-latency responses (Singapore region)
- 🔐 Secure and compliant data handling

---

**Last Updated:** November 14, 2025  
**Project:** Depresso - AI Mental Health Companion  
**Competition:** Huawei Innovation Services Competition
