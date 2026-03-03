# Comprehensive Data Flow & Architecture Analysis

## 1. Overview
This document provides a deep, granular analysis of every major component and data connection within the **Depresso** ecosystem. It traces how data originates (user input or HealthKit), flows through the iOS frontend, is processed by the Node.js backend, analyzed by the Google Gemini AI, and finally persisted in the PostgreSQL database.

## 2. Frontend Architecture (iOS / Swift)
The iOS app is built using **SwiftUI** and **The Composable Architecture (TCA)**. 

### Core App State (`AppFeature.swift`)
The entire application state is governed by `AppFeature`, which orchestrates sub-features:
- `journalState` (`AICompanionJournalFeature`)
- `dashboardState` (`DashboardFeature`)
- `communityState` (`CommunityFeature`)
- `insightsState` (`InsightsFeature`)
- `supportState` (`SupportFeature`)
- `breathingState` (`BreathingFeature`)
- `authState` & `onboardingState`

### Data Origin Points
1. **User Input:** Direct interaction through views (Journal entries, Community posts, PHQ-8 Assessment).
2. **HealthKit Integration:** Background and foreground collection of biometric data (Steps, Heart Rate, Sleep, Active Energy).
3. **Motion & Typing Metrics:** CoreMotion for accelerometer data and custom tracking for typing speed/patterns.

### Network Layer
- **`APIClient.swift`:** The unified bridge between the iOS app and the Node.js backend. All features delegate their network requests to this client, ensuring consistent error handling and authentication header injection.
- **`UserManager.swift`:** Acts as the single source of truth for user identity, storing the `sessionToken` and `userId`, and ensuring synchronization across app launches.

## 3. Backend Architecture (Node.js / Express)
The backend is a RESTful API built on **Express.js**, serving as the central hub connecting the mobile app, the PostgreSQL database, and external AI services.

### Core Services
- **`server.js` / `app.js`:** App initialization, middleware configuration (CORS, Rate Limiting, JSON parsing), and route registration.
- **`aiService.js`:** Manages the integration with the Google Gemini API (specifically `gemini-2.5-flash`). It constructs the contextual prompts, handles the HTTP conversation, and parses the structured JSON response for the frontend.

### API Routes & Endpoints
- `/api/v1/auth`: Handles user registration and login.
- `/api/v1/journal`: Manages journal entries and coordinates the AI chat responses.
- `/api/v1/research`: Collects NLP research data, tags, sentiment analysis, and serves data to the web dashboard.
- `/api/v1/community`: Manages anonymous community posts and interactions (likes, comments).
- `/api/v1/ml-analysis`: Endpoints dedicated to processing multi-modal health data for depression risk scoring.

## 4. Database Schema (PostgreSQL)
The database structure is deeply relational, centered around the `Users` table using UUIDs.

- **Identity & Assessments:**
  - `Users (id: UUID)`
  - `Assessments` (Links to Users, stores PHQ-8 scores and raw JSON answers).
- **Health & Biometrics:**
  - `DailyMetrics` (Steps, energy, heart rate).
  - `TypingMetrics` (WPM, edit counts).
  - `MotionMetrics` (Accelerometer XYZ averages).
- **Journaling & AI:**
  - `JournalEntries` (Text content and metadata).
  - `AIChatMessages` (Foreign key to `JournalEntries`, distinguishes 'user' vs 'ai' sender).
- **Social & Community:**
  - `CommunityPosts` (Content, like counts).
  - `PostLikes` (Join table for User <-> Post relations).
- **Analysis & Research:**
  - `MLAnalysisResults` (Stores the final risk score, severity, and Gemini JSON recommendations).
  - `ResearchEntries` (NLP analysis, sentiment labels, and CBT distortion tags).

## 5. End-to-End Data Connections

### Flow 1: AI-Powered Journaling
1. **User Action:** User types a message in `JournalView.swift`.
2. **TCA Action:** `AICompanionJournalFeature` dispatches a send action.
3. **API Call:** `APIClient` sends a `POST /journal/entries/:id/messages` request.
4. **Backend Processing:** Node.js receives the message, stores it in `AIChatMessages`.
5. **AI Integration:** `aiService.js` bundles the conversation history and sends it to the **Google Gemini API** with a therapeutic system prompt.
6. **Persistence:** The Gemini response is parsed, saved in `AIChatMessages` as 'ai', and returned via HTTP.
7. **UI Update:** TCA state is updated, appending the new message bubble to the chat interface.

### Flow 2: Multi-modal Health Analysis
1. **Data Collection:** The iOS app collects `DailyMetrics` via HealthKit, `TypingMetrics` via keyboard observers, and `Assessments` (PHQ-8).
2. **API Call:** A unified payload is sent to `POST /api/v1/ml-analysis/analyze`.
3. **AI Processing:** The backend aggregates this data and prompts Gemini to evaluate depression risk based on behavioral and biometric markers.
4. **Result Storage:** The risk score, severity string, and actionable recommendations are saved to `MLAnalysisResults`.
5. **Dashboard Reflection:** This data immediately becomes available to the Research Dashboard (`http://localhost:3001`), powering the Chart.js visualizations.

### Flow 3: Research Dashboard Synchronization
1. **Data Generation:** As users interact (completing assessments, journaling, posting in the community), tables like `ResearchEntries` and `Assessments` are populated.
2. **Web Dashboard Request:** The standalone dashboard server polls `/research/stats`, `/research/sentiment`, and `/research/distortions`.
3. **Aggregation:** PostgreSQL executes aggregation queries (e.g., `COUNT`, `AVG` over time series) to return sanitized JSON to the frontend dashboard.

## 6. Conclusion
The architecture is strictly separated yet seamlessly integrated. The iOS frontend is isolated from direct database access, relying entirely on the Node.js intermediary. The backend abstracts the complexity of the Gemini AI and PostgreSQL transactions, providing a clean, RESTful surface for both the mobile app and the research dashboard.
