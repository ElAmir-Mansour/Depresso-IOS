# Depresso Development Plan

## 1. Project Status
- **Current Version:** Functional MVP (iOS + Node.js Backend).
- **AI Engine:** Google Gemini Cloud (v1.5 Flash).
- **Database:** PostgreSQL.
- **Hosting:** Local/Hybrid (ready for Cloud deployment).

## 2. Architecture Overview
### Client (iOS)
- **Framework:** SwiftUI.
- **Architecture:** The Composable Architecture (TCA).
- **Data Flow:** Unidirectional.
- **Networking:** Custom `APIClient` with `URLSession` (120s timeout for AI).
- **Local Storage:** SwiftData (Caching) + UserDefaults (Settings).

### Backend (Node.js)
- **Framework:** Express.js.
- **Database:** PostgreSQL (Relational data for users, journals, metrics).
- **AI Service:** Google Gemini API (via `aiService.js`).
- **Security:** JWT Authentication (Planned/Partial), Input Validation.

## 3. Data Models (PostgreSQL)
Based on `schema.sql`:
1.  **Users**: `id` (UUID), `created_at`.
2.  **Assessments**: PHQ-8 scores and answers.
3.  **Metrics**: `DailyMetrics` (Steps, Energy, HR), `TypingMetrics`, `MotionMetrics`.
4.  **JournalEntries**: User's journal sessions.
5.  **AIChatMessages**: Conversation history (`user` vs `assistant`).
6.  **CommunityPosts**: Anonymous posts.
7.  **WellnessTasks**: Todo items for mental health.

## 4. API Endpoints
Base URL: `/api/v1`

### Authentication
- `POST /users/register` - Create anonymous account.
- `GET /users/profile/:userId` - Get profile.
- `PUT /users/profile/:userId` - Update profile.

### Journal & AI
- `POST /journal/entries` - Start new entry.
- `POST /journal/entries/:id/messages` - Chat with Gemini (Long polling).
- `GET /journal/entries` - List history.

### Metrics
- `POST /metrics/submit` - Batch upload HealthKit data.

### Community
- `GET /community/posts` - Feed.
- `POST /community/posts` - New post.
- `POST /community/posts/:id/like` - Interaction.

### Research
- `POST /research/entries` - Submit structured research data.

## 5. Scalability & Maintainability Roadmap

### Scalability
- **Database**:
    - [ ] Implement connection pooling (already using `pg` pool).
    - [ ] Add indexing on `user_id` and `created_at` for faster history queries (Done).
    - [ ] Future: Read replicas for analytics dashboard.
- **Backend**:
    - [ ] Stateless design allows horizontal scaling (e.g., Kubernetes/Docker).
    - [ ] Redis caching for session management and rate limiting (Planned).
- **AI**:
    - [ ] Queue system (Bull/Redis) for AI requests if latency increases.
    - [ ] Streaming API support for real-time chat effect.

### Maintainability
- **Codebase**:
    - [ ] Modularize `APIClient` into separate services (Auth, Journal, Metrics).
    - [ ] Enforce strict linting (SwiftLint, ESLint).
    - [ ] Unit Tests: Increase coverage for `JournalFeature` (TCA) and Backend Controllers.
- **Deployment**:
    - [ ] CI/CD Pipeline (GitHub Actions) for auto-testing and deployment.
    - [ ] Dockerize backend for consistent environments (Dockerfile exists).

## 6. Next Steps (Current)
1.  [x] **Authentication**: Backend plumbing + iOS AuthenticationClient implemented.
2.  [x] **Data Deletion**: Implemented in Settings and Backend.
3.  [x] **Offline Support**: SwiftData sync queue and visual indicators added.
4.  [ ] **Phase 2: Content Expansion**:
    - [x] **Breathing Exercise**: Box breathing tool added to Dashboard.
    - [ ] **Structured CBT Templates**: Add "Guided Journaling" for Gratitude and Thought records.
    - [ ] **Analytics Insights**: Deepen the correlation between Health data and Mood scores on the backend.
    - [ ] **Push Notifications**: Daily reminders for check-ins.

