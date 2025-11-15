# API Documentation

## Base URL

```
http://localhost:3000/api
```

For production, replace with your deployed backend URL.

---

## Authentication

All protected endpoints require a JWT token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

### Get Authentication Token

**Endpoint:** `POST /api/auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

---

## Endpoints Overview

| Category | Endpoint | Method | Description |
|----------|----------|--------|-------------|
| Auth | `/api/auth/register` | POST | Register new user |
| Auth | `/api/auth/login` | POST | User login |
| Assessment | `/api/assessment/submit` | POST | Submit PHQ-8 assessment |
| Assessment | `/api/assessment/history` | GET | Get assessment history |
| Assessment | `/api/assessment/analysis/:id` | GET | Get AI analysis |
| Chat | `/api/chat/ai` | POST | Send message to AI |
| Journal | `/api/journal/entries` | GET | Get journal entries |
| Journal | `/api/journal/entry` | POST | Create journal entry |
| Health | `/api/health/sync` | POST | Sync HealthKit data |
| Health | `/api/health/metrics` | GET | Get health metrics |
| Health | `/api/health/summary` | GET | Get weekly summary |
| Community | `/api/community/posts` | GET | Get community posts |
| Community | `/api/community/post` | POST | Create new post |
| Community | `/api/community/react` | POST | React to post |
| Goals | `/api/goals` | GET | Get user goals |
| Goals | `/api/goals` | POST | Create new goal |
| Goals | `/api/goals/:id/progress` | POST | Update goal progress |

---

For full documentation, see the complete API reference in the backend repository.
