# Technical Specifications

## Architecture Overview

### System Architecture
```
┌─────────────┐
│   Mobile    │
│     App     │
└──────┬──────┘
       │
       │ REST API / GraphQL
       │
┌──────▼──────┐
│   Backend   │
│     API     │
└──────┬──────┘
       │
┌──────▼──────┐
│  Database   │
└─────────────┘
```

## Technology Stack

### Backend
- **Language**: [To be specified - Node.js/Python/Java/etc.]
- **Framework**: [To be specified - Express/NestJS/Django/Spring/etc.]
- **Database**: [To be specified - PostgreSQL/MongoDB/MySQL/etc.]
- **Authentication**: JWT, OAuth 2.0
- **API Style**: RESTful / GraphQL

### Mobile
- **Framework**: [To be specified - React Native/Flutter/Native/etc.]
- **State Management**: [To be specified]
- **Local Storage**: SQLite / Realm / AsyncStorage
- **Networking**: Axios / Fetch API

### Infrastructure
- **Hosting**: [To be specified - AWS/GCP/Azure/etc.]
- **CI/CD**: [To be specified - GitHub Actions/Jenkins/etc.]
- **Monitoring**: [To be specified]
- **Analytics**: [To be specified]

## API Specifications

### Base URL
```
Production: https://api.englishpracticeapp.com/v1
Development: http://localhost:3000/api/v1
```

### Authentication
All API requests require authentication using JWT tokens in the Authorization header:
```
Authorization: Bearer <token>
```

### Core Endpoints

#### Authentication
- `POST /auth/register` - User registration
- `POST /auth/login` - User login
- `POST /auth/logout` - User logout
- `POST /auth/refresh` - Refresh access token

#### User Management
- `GET /users/me` - Get current user profile
- `PUT /users/me` - Update user profile
- `GET /users/me/progress` - Get user progress

#### Learning Content
- `GET /lessons` - Get list of lessons
- `GET /lessons/:id` - Get lesson details
- `POST /lessons/:id/complete` - Mark lesson as complete

#### Exercises
- `GET /exercises` - Get list of exercises
- `GET /exercises/:id` - Get exercise details
- `POST /exercises/:id/submit` - Submit exercise answer
- `GET /exercises/:id/results` - Get exercise results

#### Progress & Analytics
- `GET /progress/overview` - Get progress overview
- `GET /progress/statistics` - Get detailed statistics
- `GET /achievements` - Get user achievements

## Database Schema

### Users Table
```sql
users
- id (UUID, PK)
- email (VARCHAR, UNIQUE)
- username (VARCHAR, UNIQUE)
- password_hash (VARCHAR)
- first_name (VARCHAR)
- last_name (VARCHAR)
- proficiency_level (ENUM)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

### Lessons Table
```sql
lessons
- id (UUID, PK)
- title (VARCHAR)
- description (TEXT)
- content (JSON)
- difficulty_level (ENUM)
- category (VARCHAR)
- order_index (INTEGER)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

### Exercises Table
```sql
exercises
- id (UUID, PK)
- lesson_id (UUID, FK)
- type (ENUM: vocabulary, grammar, reading, listening, speaking, writing)
- question (TEXT)
- options (JSON)
- correct_answer (TEXT)
- difficulty (ENUM)
- points (INTEGER)
- created_at (TIMESTAMP)
```

### User Progress Table
```sql
user_progress
- id (UUID, PK)
- user_id (UUID, FK)
- lesson_id (UUID, FK)
- status (ENUM: not_started, in_progress, completed)
- score (INTEGER)
- completed_at (TIMESTAMP)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

### Exercise Submissions Table
```sql
exercise_submissions
- id (UUID, PK)
- user_id (UUID, FK)
- exercise_id (UUID, FK)
- answer (TEXT)
- is_correct (BOOLEAN)
- points_earned (INTEGER)
- submitted_at (TIMESTAMP)
```

## Security Requirements

### Data Protection
- All passwords must be hashed using bcrypt
- Sensitive data encrypted at rest
- HTTPS/TLS for all communications
- Input validation and sanitization

### Authentication & Authorization
- JWT tokens with appropriate expiration
- Refresh token rotation
- Role-based access control (RBAC)
- Rate limiting on API endpoints

### Compliance
- GDPR compliance for EU users
- COPPA compliance for users under 13
- Data retention policies
- Privacy policy and terms of service

## Performance Requirements

### Response Times
- API response time: < 200ms (95th percentile)
- Page load time: < 2s
- Time to interactive: < 3s

### Scalability
- Support 10,000 concurrent users
- Handle 1,000 requests per second
- Database query optimization
- Caching strategy (Redis/Memcached)

### Availability
- 99.9% uptime SLA
- Automated failover
- Regular backups
- Disaster recovery plan

---
*Last Updated: December 9, 2025*
