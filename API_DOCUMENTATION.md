# API Documentation

## Base URL
```
http://localhost:3000/api/v1
```

## Authentication

### Register User
```http
POST /auth/register
Content-Type: application/json

{
  "username": "user@example.com",
  "password": "securepassword123"
}
```

**Response** (201 Created):
```json
{
  "id": "uuid-string",
  "username": "user@example.com",
  "created_at": "2026-02-06T12:00:00.000Z"
}
```

---

## Journal Endpoints

### Create Journal Entry
```http
POST /journal/entries
Content-Type: application/json

{
  "userId": "user-uuid",
  "title": "Today's Thoughts",
  "content": "I feel grateful today..."
}
```

**Response** (201 Created):
```json
{
  "id": 123,
  "user_id": "user-uuid",
  "title": "Today's Thoughts",
  "content": "I feel grateful today...",
  "created_at": "2026-02-06T12:00:00.000Z"
}
```

### Send Message to AI
```http
POST /journal/entries/:entryId/messages
Content-Type: application/json

{
  "userId": "user-uuid",
  "sender": "user",
  "content": "I'm feeling stressed today"
}
```

**Response** (201 Created):
```json
{
  "id": 234,
  "entry_id": 123,
  "user_id": "user-uuid",
  "sender": "assistant",
  "content": "I'm so sorry to hear you're feeling stressed...",
  "created_at": "2026-02-06T12:05:00.000Z"
}
```

### Get Messages
```http
GET /journal/entries/:entryId/messages
```

**Response** (200 OK):
```json
[
  {
    "id": 233,
    "entry_id": 123,
    "sender": "user",
    "content": "I'm feeling stressed today",
    "created_at": "2026-02-06T12:00:00.000Z"
  },
  {
    "id": 234,
    "entry_id": 123,
    "sender": "assistant",
    "content": "I'm so sorry to hear...",
    "created_at": "2026-02-06T12:05:00.000Z"
  }
]
```

---

## Research Endpoints

### Submit Research Entry
```http
POST /research/entries
Content-Type: application/json

{
  "userId": "user-uuid",
  "promptId": "prompt-uuid",
  "content": "Today I feel optimistic about the future",
  "sentimentLabel": "0.85",
  "tags": ["gratitude", "hope"],
  "metadata": {
    "prompt_text": "What are you grateful for today?",
    "activity_level": 7,
    "social_interaction": 5,
    "sleep_hours": 8
  }
}
```

**Response** (201 Created):
```json
{
  "id": 456,
  "user_id": "user-uuid",
  "prompt_id": "prompt-uuid",
  "content": "Today I feel optimistic...",
  "sentiment_label": "0.85",
  "created_at": "2026-02-06T12:00:00.000Z"
}
```

### Get Research Stats
```http
GET /research/stats
```

**Response** (200 OK):
```json
{
  "total_users": "38",
  "total_entries": "46",
  "total_assessments": "23",
  "total_messages": "223",
  "avg_sentiment": 0.075,
  "risk_flags": "0"
}
```

### Get CBT Distortions
```http
GET /research/distortions
```

**Response** (200 OK):
```json
{
  "frequency": [
    {
      "distortion": "overgeneralization",
      "count": "4"
    },
    {
      "distortion": "labeling",
      "count": "2"
    }
  ],
  "timeSeries": [
    {
      "date": "2026-01-20T22:00:00.000Z",
      "entries_with_distortions": "2",
      "total_distortions": "5"
    }
  ]
}
```

### Get Sentiment Analysis
```http
GET /research/sentiment?days=30
```

**Response** (200 OK):
```json
{
  "distribution": [
    {
      "category": "Positive",
      "count": "15"
    },
    {
      "category": "Neutral",
      "count": "20"
    },
    {
      "category": "Negative",
      "count": "11"
    }
  ],
  "timeSeries": [
    {
      "date": "2026-01-20T22:00:00.000Z",
      "avg_sentiment": 0.12,
      "entry_count": "3"
    }
  ]
}
```

### Get PHQ-8 Assessments
```http
GET /research/assessments
```

**Response** (200 OK):
```json
{
  "distribution": [
    {
      "severity": "None (0-4)",
      "count": "10",
      "avg_score": "2.5"
    },
    {
      "severity": "Mild (5-9)",
      "count": "6",
      "avg_score": "7.2"
    }
  ],
  "timeSeries": [
    {
      "date": "2025-11-06T22:00:00.000Z",
      "avg_score": "6.0",
      "assessment_count": "4"
    }
  ]
}
```

### Export Data
```http
GET /research/export?table=journalentries
```

**Query Parameters**:
- `table`: `journalentries`, `assessments`, or `users`

**Response** (200 OK):
```csv
id,user_id,content,created_at
1,uuid-1,"Today was great",2026-01-20T12:00:00.000Z
2,uuid-2,"Felt stressed",2026-01-21T14:30:00.000Z
```

---

## Community Endpoints

### Get All Posts
```http
GET /community/posts
```

**Response** (200 OK):
```json
[
  {
    "id": 789,
    "user_id": "user-uuid",
    "content": "Anyone else struggling with sleep?",
    "likes_count": 12,
    "comments_count": 5,
    "created_at": "2026-02-05T18:00:00.000Z"
  }
]
```

### Create Post
```http
POST /community/posts
Content-Type: application/json

{
  "userId": "user-uuid",
  "content": "Found a great coping strategy today",
  "isAnonymous": true
}
```

**Response** (201 Created):
```json
{
  "id": 790,
  "user_id": "anonymous",
  "content": "Found a great coping strategy today",
  "created_at": "2026-02-06T12:00:00.000Z"
}
```

### Like Post
```http
POST /community/posts/:postId/like
Content-Type: application/json

{
  "userId": "user-uuid"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "likes_count": 13
}
```

### Get Community Stats
```http
GET /research/community/stats
```

**Response** (200 OK):
```json
{
  "overview": {
    "total_posts": "45",
    "total_comments": "123",
    "total_likes": "567",
    "pending_reports": "0"
  },
  "timeSeries": [
    {
      "date": "2026-01-20T22:00:00.000Z",
      "posts": "5",
      "views": "120"
    }
  ]
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "Validation error",
  "details": "userId is required"
}
```

### 404 Not Found
```json
{
  "error": "Resource not found",
  "details": "Entry with id 999 not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Server error",
  "details": "Please try again",
  "code": "INTERNAL_ERROR"
}
```

---

## Rate Limiting
- **Limit**: 100 requests per minute per IP
- **Headers**:
  - `X-RateLimit-Limit`: Total allowed requests
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Reset time (Unix timestamp)

---

## Gemini AI Integration

The `/journal/entries/:id/messages` endpoint uses Google Gemini AI (`gemini-2.5-flash`) for generating empathetic responses.

**Configuration**:
- **Model**: gemini-2.5-flash
- **Temperature**: 0.7
- **Max Tokens**: 1024
- **Timeout**: 30 seconds

**System Prompt**:
> "You are a compassionate AI companion for a mental wellness app. You provide supportive, empathetic responses to users sharing their thoughts and feelings. This is a safe, therapeutic context for discussing mental health, emotions, and personal challenges. Respond with care, validation, and encouragement."

---

## WebSocket Support (Future)
WebSocket support for real-time updates is planned for future releases.

---

## Changelog
- **v2.0** (2026-02-06): Migrated from Qwen to Gemini AI
- **v2.1** (2026-02-06): Added dark-themed research dashboard
- **v2.2** (2026-02-06): Added CSV export functionality
