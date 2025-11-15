# Depresso Backend Server

Node.js/Express backend server for the Depresso mental health app, integrated with Huawei Cloud AI services.

---

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Setup database
createdb depresso_db
psql depresso_db < schema.sql

# Configure environment
cp .env.example .env
# Edit .env with your values

# Start server
npm start
```

Server runs on `http://localhost:3000`

---

## 📋 Environment Variables

Create a `.env` file with the following:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Database
DATABASE_URL=postgresql://postgres:password@localhost:5432/depresso_db

# JWT Secret (generate with: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
JWT_SECRET=your_secret_key_min_32_characters

# Huawei Cloud
HUAWEI_AUTH_TOKEN=your_x_auth_token
HUAWEI_REGION=ap-southeast-1
HUAWEI_PROJECT_ID=your_project_id
QWEN_API_ENDPOINT=https://qwen-plus.ap-southeast-1.myhuaweicloud.com

# Optional: Logging
LOG_LEVEL=info
```

---

## 🗄 Database Schema

### Tables

1. **users** - User accounts
2. **assessments** - PHQ-8 assessments
3. **journal_entries** - AI chat conversations
4. **health_metrics** - HealthKit synced data
5. **community_posts** - Community content
6. **goals** - User wellness goals

### Migrations

```bash
# Create database
createdb depresso_db

# Run schema
psql depresso_db < schema.sql

# Seed sample data (optional)
psql depresso_db < seed.sql

# Verify tables
psql depresso_db -c "\dt"
```

---

## 🔌 API Endpoints

### Health Check
```
GET /health
```

### Authentication
```
POST /api/auth/register
POST /api/auth/login
```

### Assessments
```
POST /api/assessment/submit
GET  /api/assessment/history
GET  /api/assessment/analysis/:id
```

### AI Chat
```
POST /api/chat/ai
GET  /api/journal/entries
POST /api/journal/entry
```

### Health Metrics
```
POST /api/health/sync
GET  /api/health/metrics
GET  /api/health/summary
```

### Community
```
GET  /api/community/posts
POST /api/community/post
POST /api/community/react
```

### Goals
```
GET  /api/goals
POST /api/goals
POST /api/goals/:id/progress
```

Full API documentation: [API_DOCUMENTATION.md](../docs/API_DOCUMENTATION.md)

---

## 🧪 Testing

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- routes/auth.test.js

# Watch mode
npm run test:watch
```

### Test Scripts

```bash
# Test PHQ-8 flow
./test-phq8-flow.sh

# Test assessment flow
./test-assessment-flow.sh
```

---

## 🔒 Security

### Authentication
- JWT tokens with 24-hour expiration
- bcrypt password hashing (10 rounds)
- Token refresh mechanism

### Rate Limiting
- 100 requests per 15 min per IP (general)
- 20 requests per 15 min for AI endpoints
- 5 login attempts per 15 min per IP

### Input Validation
- Express-validator for request validation
- SQL injection prevention via parameterized queries
- XSS protection with sanitization

---

## 📊 Logging

Uses Winston for structured logging:

```javascript
// Log levels
logger.error('Critical error');
logger.warn('Warning message');
logger.info('Information');
logger.debug('Debug info');
```

Logs are written to:
- Console (development)
- `logs/error.log` (errors only)
- `logs/combined.log` (all logs)

---

## 🔧 Development

### File Structure

```
depresso-backend/
├── src/
│   ├── routes/           # API route handlers
│   │   ├── auth.js
│   │   ├── assessment.js
│   │   ├── chat.js
│   │   ├── health.js
│   │   ├── community.js
│   │   └── goals.js
│   ├── middleware/       # Express middleware
│   │   ├── auth.js
│   │   ├── validation.js
│   │   └── errorHandler.js
│   ├── services/         # Business logic
│   │   ├── huaweiCloud.js
│   │   └── healthAnalytics.js
│   ├── config/          # Configuration
│   │   └── database.js
│   └── index.js         # Server entry point
├── migrations/          # Database migrations
├── tests/              # Test files
├── .env                # Environment variables
├── package.json        # Dependencies
└── schema.sql          # Database schema
```

### Adding New Endpoints

1. Create route file in `src/routes/`
2. Implement route handlers
3. Add authentication middleware if needed
4. Register route in `src/index.js`
5. Add tests
6. Update API documentation

Example:
```javascript
// src/routes/example.js
const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');

router.get('/example', authenticateToken, async (req, res) => {
    try {
        // Implementation
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

module.exports = router;
```

---

## 🐛 Troubleshooting

### Database Connection Fails

```bash
# Check PostgreSQL is running
brew services list | grep postgresql

# Test connection
psql -U postgres -h localhost

# Verify DATABASE_URL in .env
echo $DATABASE_URL
```

### Huawei Cloud API Errors

```bash
# Check token expiration
curl -H "X-Auth-Token: $HUAWEI_AUTH_TOKEN" \
  https://iam.ap-southeast-1.myhuaweicloud.com/v3/auth/projects

# Refresh token
./update-token.sh

# Verify endpoint
echo $QWEN_API_ENDPOINT
```

### Server Won't Start

```bash
# Check port availability
lsof -i :3000

# Kill process if needed
kill -9 $(lsof -t -i:3000)

# Check logs
tail -f logs/error.log
```

---

## 📦 Dependencies

### Production
- `express` - Web framework
- `pg` - PostgreSQL client
- `jsonwebtoken` - JWT authentication
- `bcrypt` - Password hashing
- `axios` - HTTP client
- `dotenv` - Environment variables
- `winston` - Logging
- `express-rate-limit` - Rate limiting
- `helmet` - Security headers
- `cors` - CORS middleware

### Development
- `nodemon` - Auto-restart
- `jest` - Testing framework
- `supertest` - HTTP testing
- `eslint` - Code linting

---

## 🚀 Deployment

### Docker (Recommended)

```bash
# Build image
docker build -t depresso-backend .

# Run container
docker run -p 3000:3000 --env-file .env depresso-backend
```

### Manual Deployment

1. Provision server (Ubuntu 20.04+)
2. Install Node.js, PostgreSQL
3. Clone repository
4. Install dependencies
5. Configure environment
6. Setup systemd service
7. Configure nginx reverse proxy
8. Enable SSL with Let's Encrypt

Detailed deployment guide: [DEPLOYMENT.md](../docs/DEPLOYMENT.md)

---

## 📈 Performance

### Optimizations
- Connection pooling for database
- Response caching for repeated queries
- Gzip compression
- Async/await for non-blocking I/O

### Monitoring

Endpoints for monitoring:
```
GET /health - Health check
GET /metrics - Performance metrics (coming soon)
```

---

## 🔄 Maintenance

### Database Backup

```bash
# Backup
pg_dump depresso_db > backup_$(date +%Y%m%d).sql

# Restore
psql depresso_db < backup_20251115.sql
```

### Log Rotation

Logs auto-rotate daily. Manual cleanup:
```bash
find logs/ -name "*.log" -mtime +30 -delete
```

### Token Refresh

Huawei tokens expire after 24 hours. Automate refresh:
```bash
# Add to crontab (refresh every 12 hours)
0 */12 * * * /path/to/depresso-backend/update-token.sh
```

---

## 📚 Resources

- [Express.js Documentation](https://expressjs.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Huawei Cloud API Reference](https://support.huaweicloud.com/intl/en-us/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)

---

## 🤝 Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

---

## 📄 License

MIT License - see [LICENSE](../LICENSE)

---

**Questions? Open an issue or discussion on GitHub!**
