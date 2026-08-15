# Environment Configuration Guide

## Overview

This project uses environment-specific configuration files for development and production deployments.

### Environment Files

| File | Purpose | Git Status | Usage |
|------|---------|-----------|-------|
| `.env.dev.example` | Development template | ✅ Committed | Copy to `.env.dev` |
| `.env.dev` | Development config | ❌ Git-ignored | Local dev with docker-compose |
| `.env.example` | Local/default template | ✅ Committed | Copy to `.env` |
| `.env` | Local config | ❌ Git-ignored | Local development (fallback) |
| `.env.prod.example` | Production template | ✅ Committed | Copy to `.env.prod` |
| `.env.prod` | Production config | ❌ Git-ignored | Production with docker-compose.prod.yml |

---

## Development Setup

### Option 1: Using `.env.dev` (Recommended for Docker Compose)

```bash
# 1. Create development environment file
cp .env.dev.example .env.dev

# 2. (Optional) Customize if needed
nano .env.dev

# 3. Start services - automatically loads .env.dev
docker-compose up -d
```

**Services Started:**
- PostgreSQL on `localhost:5433`
- MongoDB on `localhost:27017`
- Spring Boot App on `localhost:8081`

### Option 2: Using `.env` (Local development without Docker Compose)

```bash
# 1. Create environment file
cp .env.example .env

# 2. (Optional) Customize if needed
nano .env

# 3. Run Spring Boot locally
mvn spring-boot:run
```

---

## Development Environment Settings

```properties
# .env.dev Configuration

# Database (Docker container names)
SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/college_dev_db
SPRING_DATASOURCE_USERNAME=college_dev_user
SPRING_DATASOURCE_PASSWORD=dev_password_123

# Logging - Verbose for debugging
LOGGING_LEVEL_ROOT=INFO
LOGGING_LEVEL_COM_MY_COLLEGEMANAGEMENT=DEBUG

# Development Features
SPRING_JPA_SHOW_SQL=true           # Show SQL queries
SPRING_JPA_HIBERNATE_DDL_AUTO=update  # Auto-update schema
SPRING_FLYWAY_ENABLED=true         # Enable migrations

# Connection Pool - Small for dev
SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE=5
SPRING_DATASOURCE_HIKARI_MINIMUM_IDLE=2

Spring Profile: dev
```

---

## Production Setup

### Step 1: Prepare Production Environment

```bash
# 1. Copy production template
cp .env.prod.example .env.prod

# 2. IMPORTANT: Edit with real production credentials
nano .env.prod
```

### Step 2: Set Production Credentials

Edit `.env.prod` and change these values:

```properties
# Change from example values:
POSTGRES_DB=college_prod_db                    # ← Your prod DB name
POSTGRES_USER=college_prod_user                # ← Your prod DB user
POSTGRES_PASSWORD=YourSecurePassword123!@#$   # ← STRONG password (min 16 chars)

# If using Azure/AWS managed database, update:
SPRING_DATASOURCE_URL=jdbc:postgresql://your-prod-host:5432/college_prod_db
SPRING_DATASOURCE_USERNAME=your_prod_user@server
SPRING_DATASOURCE_PASSWORD=YourSecurePassword123!@#$
```

### Step 3: Deploy Production

```bash
# Deploy with production configuration
docker-compose -f docker-compose.prod.yml up -d

# Verify
docker-compose -f docker-compose.prod.yml ps
```

---

## Production Environment Settings

```properties
# .env.prod Configuration

# Database (Managed service)
SPRING_DATASOURCE_URL=jdbc:postgresql://college-prod-db.azure.com:5432/college_prod_db
SPRING_DATASOURCE_USERNAME=dbadmin@college-prod-db
SPRING_DATASOURCE_PASSWORD=YourSecurePassword123!@#$

# Logging - Production level (warnings only)
LOGGING_LEVEL_ROOT=WARN
LOGGING_LEVEL_COM_MY_COLLEGEMANAGEMENT=INFO

# Production Settings
SPRING_JPA_SHOW_SQL=false          # Don't log SQL
SPRING_JPA_HIBERNATE_DDL_AUTO=validate  # Never modify schema
SPRING_FLYWAY_ENABLED=true         # Migrations only
SPRING_FLYWAY_BASELINE_ON_MIGRATE=false

# Connection Pool - Large for production
SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE=10
SPRING_DATASOURCE_HIKARI_MINIMUM_IDLE=5

Spring Profile: prod
```

---

## Environment Variable Reference

### Database Variables

```bash
# PostgreSQL Configuration
POSTGRES_DB                     # Database name
POSTGRES_USER                   # Database user
POSTGRES_PASSWORD               # Database password

# MongoDB Configuration
MONGO_INITDB_DATABASE          # MongoDB database name

# Spring Datasource
SPRING_DATASOURCE_URL          # JDBC connection string
SPRING_DATASOURCE_USERNAME     # Database username
SPRING_DATASOURCE_PASSWORD     # Database password
```

### Spring Boot Variables

```bash
# Profile and Logging
SPRING_PROFILES_ACTIVE              # dev or prod
LOGGING_LEVEL_ROOT                  # Root logging level
LOGGING_LEVEL_COM_MY_COLLEGEMANAGEMENT  # App logging level

# Database Settings
SPRING_JPA_SHOW_SQL                 # Show SQL queries (dev only)
SPRING_JPA_HIBERNATE_DDL_AUTO       # update/validate/none
SPRING_FLYWAY_ENABLED               # Enable migrations
SPRING_FLYWAY_BASELINE_ON_MIGRATE   # Baseline on first migration

# Connection Pooling
SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE    # Max connections
SPRING_DATASOURCE_HIKARI_MINIMUM_IDLE         # Min connections
SPRING_DATASOURCE_HIKARI_CONNECTION_TIMEOUT   # Connection timeout
SPRING_DATASOURCE_HIKARI_IDLE_TIMEOUT         # Idle connection timeout
SPRING_DATASOURCE_HIKARI_MAX_LIFETIME         # Max connection lifetime
```

---

## Docker Compose Commands

### Development

```bash
# Start services (uses .env.dev)
docker-compose up -d

# View services
docker-compose ps

# View logs
docker-compose logs -f spring-boot-app

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

### Production

```bash
# Start services (uses .env.prod)
docker-compose -f docker-compose.prod.yml up -d

# View services
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f spring-boot-app

# Stop services
docker-compose -f docker-compose.prod.yml down
```

---

## Security Checklist

- [ ] **Never commit `.env` or `.env.prod`** - These files are git-ignored
- [ ] **Use strong passwords** in `.env.prod`
  - Minimum 16 characters
  - Mix of uppercase, lowercase, numbers, special characters
  - Don't reuse passwords
- [ ] **Store `.env.prod` securely**
  - Use Azure Key Vault / AWS Secrets Manager
  - Don't share via email
  - Rotate credentials regularly
- [ ] **Development credentials** can be simple (since it's local/dev only)
- [ ] **Never use dev password in production**

---

## Troubleshooting

### "Services not starting"

```bash
# Check which .env file is being used
docker-compose config | grep -A 10 'environment:'

# Explicitly use specific file
docker-compose --env-file .env.dev up -d
```

### "Database connection refused"

```bash
# Check environment variables are loaded
docker-compose config | grep SPRING_DATASOURCE

# Verify database is running
docker-compose ps postgres
```

### "Wrong configuration in production"

```bash
# Verify you're using production compose file
docker-compose -f docker-compose.prod.yml config | head -20

# Check which .env file is being used
docker-compose -f docker-compose.prod.yml config | grep SPRING_DATASOURCE_URL
```

---

## Environment Comparison

### Development vs Production

| Aspect | Development | Production |
|--------|-------------|-----------|
| **Database** | Docker container (ephemeral) | Managed service (persistent) |
| **Backups** | Manual or none | Automated daily |
| **SQL Logging** | Enabled for debugging | Disabled for performance |
| **Schema Changes** | Auto-update (DDL=update) | Never auto (DDL=validate) |
| **Connection Pool** | Small (5 max) | Large (10 max) |
| **Logging Level** | DEBUG | WARN/INFO |
| **Replicas** | 1 | 2+ (high availability) |
| **Resource Limits** | None | Strict limits |
| **Health Checks** | Basic | Comprehensive |

---

## Quick Start

### For Developers

```bash
# Setup (one time)
cp .env.dev.example .env.dev

# Daily usage
docker-compose up -d
curl http://localhost:8081/actuator/health
docker-compose logs -f spring-boot-app
```

### For Operations/DevOps

```bash
# Setup (one time)
cp .env.prod.example .env.prod
# Edit .env.prod with production credentials
chmod 600 .env.prod

# Deploy
docker-compose -f docker-compose.prod.yml up -d
docker-compose -f docker-compose.prod.yml ps
```

---

## File Locations & Access

```
CollegeManagement/
├── .env.dev.example      ← Development template (safe to commit)
├── .env.dev              ← Development config (git-ignored, use locally)
├── .env.example          ← Local template (safe to commit)
├── .env                  ← Local config (git-ignored, use locally)
├── .env.prod.example     ← Production template (safe to commit)
├── .env.prod             ← Production config (git-ignored, STORE SECURELY)
│
├── docker-compose.yml           ← Development compose (uses .env.dev)
├── docker-compose.prod.yml      ← Production compose (uses .env.prod)
```

---

**Last Updated**: 2026-08-15
**Status**: Production Ready ✅
