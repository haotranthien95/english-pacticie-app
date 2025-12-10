# Deployment Guide - English Learning App Backend

This guide covers deploying the English Learning App backend to production environments.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Production Setup](#production-setup)
3. [Environment Configuration](#environment-configuration)
4. [Database Setup](#database-setup)
5. [Docker Deployment](#docker-deployment)
6. [Kubernetes Deployment](#kubernetes-deployment)
7. [Monitoring & Logging](#monitoring--logging)
8. [Backup & Recovery](#backup--recovery)
9. [Security Hardening](#security-hardening)
10. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Services
- **Azure Speech Services**: Create resource in Azure Portal
  - Get API key and region
  - Pricing: Standard tier recommended for production
  
### Infrastructure Requirements
- **Compute**: 2+ CPU cores, 4GB+ RAM per backend instance
- **Storage**: 50GB+ for database, 100GB+ for object storage
- **Network**: HTTPS/SSL certificate, domain name

### Tools
- Docker 20.10+
- Docker Compose 2.0+
- PostgreSQL client tools
- kubectl (for Kubernetes deployment)

## Production Setup

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/english-learning-app.git
cd english-learning-app/apps/backend
```

### 2. Configure Environment

```bash
# Copy production template
cp .env.prod.template .env.prod

# Generate secure secrets
openssl rand -hex 32  # For JWT_SECRET_KEY
openssl rand -base64 32  # For passwords
```

Edit `.env.prod` with your values:

```bash
# Critical: Set strong passwords
POSTGRES_PASSWORD=<STRONG_PASSWORD>
REDIS_PASSWORD=<STRONG_PASSWORD>
MINIO_ROOT_PASSWORD=<STRONG_PASSWORD>
GRAFANA_ADMIN_PASSWORD=<STRONG_PASSWORD>

# Critical: Set JWT secret
JWT_SECRET_KEY=<GENERATED_HEX_STRING>

# Critical: Azure credentials
AZURE_SPEECH_KEY=<YOUR_KEY>
AZURE_SPEECH_REGION=<YOUR_REGION>

# Update CORS for your domain
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

### 3. Prepare SSL Certificates

For production, use Let's Encrypt or your certificate provider:

```bash
# Using certbot (Let's Encrypt)
sudo certbot certonly --standalone -d api.yourdomain.com

# Certificates will be in:
# /etc/letsencrypt/live/api.yourdomain.com/
```

## Environment Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_PASSWORD` | Database password | `random_secure_string` |
| `REDIS_PASSWORD` | Redis password | `random_secure_string` |
| `MINIO_ROOT_USER` | MinIO admin user | `minioadmin` |
| `MINIO_ROOT_PASSWORD` | MinIO admin password | `random_secure_string` |
| `AZURE_SPEECH_KEY` | Azure API key | `abc123...` |
| `AZURE_SPEECH_REGION` | Azure region | `eastus` |
| `JWT_SECRET_KEY` | JWT signing key | `64_char_hex_string` |
| `CORS_ORIGINS` | Allowed origins | `https://app.com` |

### Optional OAuth Variables

```bash
# Google OAuth
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret

# Apple Sign In
APPLE_CLIENT_ID=com.yourapp.service
APPLE_TEAM_ID=YOUR_TEAM_ID
APPLE_KEY_ID=YOUR_KEY_ID
APPLE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----...

# Facebook Login
FACEBOOK_APP_ID=your_app_id
FACEBOOK_APP_SECRET=your_app_secret
```

## Database Setup

### Initial Migration

```bash
# Start only database first
docker-compose -f docker-compose.prod.yml up -d postgres

# Wait for database to be ready
docker-compose -f docker-compose.prod.yml exec postgres pg_isready

# Run migrations
docker-compose -f docker-compose.prod.yml run --rm backend alembic upgrade head
```

### Seed Initial Data

```bash
# Create admin user and sample data
docker-compose -f docker-compose.prod.yml run --rm backend python scripts/seed_database.py
```

### Database Backup

```bash
# Automated daily backup
docker-compose -f docker-compose.prod.yml exec postgres \
  pg_dump -U postgres english_app > backup_$(date +%Y%m%d).sql

# Restore from backup
docker-compose -f docker-compose.prod.yml exec -T postgres \
  psql -U postgres english_app < backup_20240110.sql
```

## Docker Deployment

### Production Stack

```bash
# Start all services
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f backend

# Check health
curl http://localhost:8000/health
```

### Service Scaling

```bash
# Scale backend to 4 instances
docker-compose -f docker-compose.prod.yml up -d --scale backend=4

# Note: Requires load balancer (nginx/traefik)
```

### Update Deployment

```bash
# Pull latest changes
git pull origin main

# Rebuild backend
docker-compose -f docker-compose.prod.yml build backend

# Rolling restart
docker-compose -f docker-compose.prod.yml up -d --no-deps backend
```

## Kubernetes Deployment

### Namespace Setup

```bash
# Create namespace
kubectl create namespace english-app

# Create secrets
kubectl create secret generic app-secrets \
  --from-env-file=.env.prod \
  -n english-app
```

### Deploy Services

```bash
# Apply manifests
kubectl apply -f deploy/k8s/ -n english-app

# Check status
kubectl get pods -n english-app
kubectl get services -n english-app
```

### Horizontal Pod Autoscaling

```yaml
# deploy/k8s/backend-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Monitoring & Logging

### Prometheus Metrics

Access at `/metrics` endpoint:

```bash
# Check metrics
curl http://localhost:8000/metrics
```

### Grafana Dashboards

1. Access Grafana: http://localhost:3001
2. Login with credentials from `.env.prod`
3. Import dashboards from `deploy/grafana/dashboards/`

### Log Aggregation

Structured JSON logs are written to stdout:

```bash
# View logs
docker-compose -f docker-compose.prod.yml logs -f backend

# Filter by log level
docker-compose -f docker-compose.prod.yml logs backend | grep '"level":"error"'
```

For production, ship logs to:
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Datadog
- CloudWatch (AWS)
- Google Cloud Logging

### Alerts Configuration

Configure Prometheus alerts in `deploy/prometheus/alerts.yml`:

```yaml
groups:
  - name: api_alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        annotations:
          summary: "High error rate detected"
```

## Backup & Recovery

### Automated Backups

```bash
# Database backup script
#!/bin/bash
BACKUP_DIR="/backups/postgres"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

docker-compose -f docker-compose.prod.yml exec -T postgres \
  pg_dump -U postgres english_app | \
  gzip > "$BACKUP_DIR/backup_$TIMESTAMP.sql.gz"

# Keep only last 30 days
find "$BACKUP_DIR" -name "backup_*.sql.gz" -mtime +30 -delete
```

### MinIO Backup

```bash
# Using mc (MinIO Client)
mc alias set minio http://localhost:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD
mc mirror minio/english-app-audio /backups/minio/
```

### Disaster Recovery

```bash
# 1. Stop services
docker-compose -f docker-compose.prod.yml down

# 2. Restore database
gunzip < backup_20240110.sql.gz | \
  docker-compose -f docker-compose.prod.yml exec -T postgres \
  psql -U postgres english_app

# 3. Restore MinIO data
mc mirror /backups/minio/ minio/english-app-audio

# 4. Start services
docker-compose -f docker-compose.prod.yml up -d
```

## Security Hardening

### Network Security

```bash
# Firewall rules (iptables example)
# Allow only 80/443 (HTTP/HTTPS)
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Block all other incoming
iptables -A INPUT -j DROP
```

### SSL/TLS Configuration

Use nginx as reverse proxy with SSL:

```nginx
# /etc/nginx/sites-available/english-app
server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Rate Limiting

Already configured in application (SlowAPI):
- 100 requests/minute per IP (global)
- 10 requests/minute for login
- 5 requests/minute for registration

### Security Scans

```bash
# Run before each deployment
bandit -r app/ -ll
safety check
```

## Troubleshooting

### Backend Won't Start

```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs backend

# Common issues:
# 1. Database not ready - wait for postgres health check
# 2. Missing environment variables - check .env.prod
# 3. Port conflicts - change BACKEND_PORT
```

### Database Connection Issues

```bash
# Test connection
docker-compose -f docker-compose.prod.yml exec postgres \
  psql -U postgres -d english_app -c "SELECT 1;"

# Check database URL format
echo $DATABASE_URL
# Should be: postgresql://user:pass@postgres:5432/dbname
```

### High Memory Usage

```bash
# Check container stats
docker stats

# Limit backend memory in docker-compose.prod.yml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 2G
```

### Slow API Responses

```bash
# Check Prometheus metrics
curl http://localhost:8000/metrics | grep http_request_duration

# Enable query logging in PostgreSQL
# Set log_statement = 'all' in postgresql.conf

# Check Redis cache hit rate
redis-cli INFO stats | grep keyspace
```

### MinIO Connection Errors

```bash
# Test MinIO health
curl http://localhost:9000/minio/health/live

# Check bucket exists
docker-compose -f docker-compose.prod.yml exec minio \
  mc ls minio/english-app-audio
```

## Performance Tuning

### Database Optimization

```sql
-- Create indexes for common queries
CREATE INDEX idx_speeches_level ON speeches(level);
CREATE INDEX idx_speeches_type ON speeches(type);
CREATE INDEX idx_game_results_session ON game_results(session_id);
CREATE INDEX idx_game_sessions_user_created ON game_sessions(user_id, created_at DESC);

-- Analyze tables
ANALYZE speeches;
ANALYZE game_sessions;
ANALYZE game_results;
```

### Redis Configuration

```bash
# In docker-compose.prod.yml
redis:
  command: >
    redis-server
    --maxmemory 512mb
    --maxmemory-policy allkeys-lru
    --save 60 1000
```

### Backend Workers

```bash
# Increase Uvicorn workers
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "8"]
```

## Health Checks

### Endpoint Monitoring

```bash
# Health check script
#!/bin/bash
HEALTH_URL="https://api.yourdomain.com/health"

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL")

if [ "$RESPONSE" -eq 200 ]; then
  echo "✓ API is healthy"
  exit 0
else
  echo "✗ API is down (HTTP $RESPONSE)"
  exit 1
fi
```

### Database Health

```bash
# Check connections
docker-compose -f docker-compose.prod.yml exec postgres \
  psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"
```

## Support

For additional help:
- Check logs: `docker-compose logs -f`
- Review metrics: `http://localhost:9090` (Prometheus)
- Monitor dashboards: `http://localhost:3001` (Grafana)
- Open GitHub issue: https://github.com/yourusername/english-learning-app/issues

## Checklist

Before going to production:

- [ ] Environment variables configured in `.env.prod`
- [ ] SSL certificates installed
- [ ] Database migrations applied
- [ ] Initial data seeded
- [ ] Security scans passed (Bandit, Safety)
- [ ] Backups configured and tested
- [ ] Monitoring and alerting set up
- [ ] Load testing completed
- [ ] Disaster recovery plan documented
- [ ] Team trained on deployment process
