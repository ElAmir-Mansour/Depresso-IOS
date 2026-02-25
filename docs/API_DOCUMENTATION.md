# API Documentation

## Base URL

```
http://localhost:3000/api/v1
```

For production, replace `localhost` with your server IP (e.g., `192.168.1.6` for local device testing) or domain.

---

## Authentication

**Current Implementation:** Anonymous/Device-based registration.
**Planned:** JWT Authentication.

### Register User
**Endpoint:** `POST /users/register`
**Response:**
```json
{
  "userId": "uuid-string",
  "message": "User registered successfully"
}
```

### Get Profile
**Endpoint:** `GET /users/profile/:userId`

### Update Profile
**Endpoint:** `PUT /users/profile/:userId`
**Body:**
```json
{
  "name": "John Doe",
  "avatar_url": "http://...",
  "bio": "..."
}
```

---

## Journal & AI

### Create Entry
**Endpoint:** `POST /journal/entries`
**Body:**
```json
{
  "userId": "uuid",
  "title": "Optional Title",
  "content": "Initial content"
}
```

### Chat with AI
**Endpoint:** `POST /journal/entries/:entryId/messages`
**Body:**
```json
{
  "userId": "uuid",
  "sender": "user",
  "content": "Hello Gemini, I'm feeling down."
}
```
**Response:** (Returns the AI's response message)

### Get History
**Endpoint:** `GET /journal/entries`
**Query:** `?userId=uuid`

### Get Message History
**Endpoint:** `GET /journal/entries/:entryId/messages`

---

## Metrics (HealthKit)

### Submit Metrics
**Endpoint:** `POST /metrics/submit`
**Body:**
```json
{
  "userId": "uuid",
  "dailyMetrics": { "steps": 5000, "activeEnergy": 300, "heartRate": 75 },
  "typingMetrics": { "wordsPerMinute": 40, "totalEditCount": 2 },
  "motionMetrics": { "avgAccelerationX": 0.1, ... }
}
```

---

## Assessments (PHQ-8)

### Submit Assessment
**Endpoint:** `POST /assessments`
**Body:**
```json
{
  "userId": "uuid",
  "assessmentType": "PHQ-8",
  "score": 12,
  "answers": [1, 2, 0, 1, ...]
}
```

### Get Streak
**Endpoint:** `GET /assessments/streak`
**Query:** `?userId=uuid`

---

## Community

### Get All Posts
**Endpoint:** `GET /community/posts`

### Create Post
**Endpoint:** `POST /community/posts`
**Body:**
```json
{
  "userId": "uuid",
  "title": "Optional Title",
  "content": "My story..."
}
```

### Like/Unlike
**Endpoint:** `POST /community/posts/:postId/like`
**Endpoint:** `DELETE /community/posts/:postId/like`

---

## Research (New)

### Submit Research Entry
**Endpoint:** `POST /research/entries`
**Body:**
```json
{
  "userId": "uuid",
  "promptId": "prompt_1",
  "content": "User response",
  "sentimentLabel": "Positive",
  "tags": ["happy", "morning"],
  "metadata": { ... }
}
```
