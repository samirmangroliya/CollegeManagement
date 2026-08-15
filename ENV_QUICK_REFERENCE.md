# Environment Configuration - Quick Reference

## 📁 File Structure

```
✅ COMMITTED (Safe to share)
├── .env.dev.example      ← Development template
├── .env.example          ← Local/default template  
└── .env.prod.example     ← Production template

❌ GIT-IGNORED (Secrets - Never share)
├── .env                  ← Your local development
├── .env.dev              ← Your dev Docker Compose
└── .env.prod             ← Your production (KEEP SECURE!)
```

---

## 🚀 Getting Started

### Development (Docker Compose)

```bash
# 1. One-time setup
cp .env.dev.example .env.dev

# 2. Start services
docker-compose up -d

# 3. Verify
docker-compose ps
curl http://localhost:8081/actuator/health
```

**What you get:**
- PostgreSQL on `localhost:5433`
- MongoDB on `localhost:27017`
- Spring Boot on `localhost:8081`
- Full debug logging enabled
- Auto-schema updates enabled

### Production (Docker Compose)

```bash
# 1. One-time setup
cp .env.prod.example .env.prod
nano .env.prod  # ← EDIT WITH YOUR REAL CREDENTIALS!

# 2. Start services
docker-compose -f docker-compose.prod.yml up -d

# 3. Verify
docker-compose -f docker-compose.prod.yml ps
```

**What you get:**
- Managed PostgreSQL database
- Production logging (WARN only)
- Schema validation (never auto-update)
- Resource limits enforced
- Health checks configured

---

## 📋 Configuration Differences

### Development (.env.dev)

```properties
POSTGRES_PASSWORD=dev_password_123
SPRING_JPA_SHOW_SQL=true
LOGGING_LEVEL_COM_MY_COLLEGEMANAGEMENT=DEBUG
SPRING_JPA_HIBERNATE_DDL_AUTO=update
Connection Pool Size: 5
```

### Production (.env.prod)

```properties
POSTGRES_PASSWORD=YourSecurePassword123!@#$  (16+ chars!)
SPRING_JPA_SHOW_SQL=false
LOGGING_LEVEL_COM_MY_COLLEGEMANAGEMENT=INFO
SPRING_JPA_HIBERNATE_DDL_AUTO=validate
Connection Pool Size: 10
```

---

## ⚠️ Important Security Notes

### DO ✅
- ✅ Keep `.env.prod` secure and backed up
- ✅ Use strong passwords (16+ chars, mixed case, symbols)
- ✅ Rotate production credentials quarterly
- ✅ Store `.env.prod` in secure secret management
- ✅ Use development credentials only locally
- ✅ Test in dev/staging before production

### DON'T ❌
- ❌ Never commit `.env` or `.env.prod` to git
- ❌ Never use dev passwords in production
- ❌ Never hardcode secrets in code
- ❌ Never share `.env.prod` via email/Slack
- ❌ Never use same password across environments
- ❌ Never set `DDL_AUTO=update` in production

---

## 🔄 Workflow by Role

### Developer
```bash
# Clone repo
git clone your-repo.git

# Setup once
cp .env.dev.example .env.dev

# Daily work
docker-compose up -d
docker-compose logs -f spring-boot-app
docker-compose down
```

### DevOps/Operations
```bash
# Get repo
git clone your-repo.git

# Prepare production (once)
cp .env.prod.example .env.prod
# Edit with real production credentials from secret vault

# Deploy to production
docker-compose -f docker-compose.prod.yml up -d
docker-compose -f docker-compose.prod.yml ps
```

### CI/CD Pipeline
```bash
# In GitHub Actions / GitLab CI
# Secrets are injected as environment variables
# Never commit actual values
export SPRING_DATASOURCE_PASSWORD=${{ secrets.DB_PASSWORD }}
docker-compose -f docker-compose.prod.yml up -d
```

---

## 📊 Environment Variables Overview

| Variable | Dev | Prod | Purpose |
|----------|-----|------|---------|
| `POSTGRES_PASSWORD` | Simple | Strong 16+ chars | DB security |
| `SPRING_PROFILES_ACTIVE` | dev | prod | Spring profile |
| `LOGGING_LEVEL_*` | DEBUG | INFO/WARN | Logging verbosity |
| `SPRING_JPA_SHOW_SQL` | true | false | Performance |
| `SPRING_JPA_HIBERNATE_DDL_AUTO` | update | validate | Schema safety |
| `DATASOURCE_POOL_SIZE` | 5 | 10 | Resource management |

---

## 🆘 Troubleshooting

### "Which .env file is being used?"

```bash
# Development
docker-compose config | grep "SPRING_DATASOURCE_URL"

# Production
docker-compose -f docker-compose.prod.yml config | grep "SPRING_DATASOURCE_URL"
```

### "Want to switch environments?"

```bash
# Stop current environment
docker-compose down

# Start different environment
docker-compose -f docker-compose.prod.yml up -d
```

### "Accidentally committed secrets?"

```bash
# Remove from git history (URGENT!)
git rm --cached .env.prod
git commit --amend

# Rotate all credentials immediately!
```

---

## 📝 Environment Variable Checklist

### Development (.env.dev)
- [ ] File exists
- [ ] Credentials are simple (dev-only)
- [ ] `SPRING_PROFILES_ACTIVE=dev`
- [ ] `SPRING_JPA_SHOW_SQL=true`
- [ ] `LOGGING_LEVEL=DEBUG`

### Production (.env.prod)
- [ ] File exists and is git-ignored
- [ ] Credentials are strong (16+ chars)
- [ ] Database URL points to production
- [ ] `SPRING_PROFILES_ACTIVE=prod`
- [ ] `SPRING_JPA_SHOW_SQL=false`
- [ ] `LOGGING_LEVEL=WARN/INFO`
- [ ] Stored in secure location (Key Vault)
- [ ] Backed up
- [ ] Rotation schedule set

---

## 💾 Backup & Recovery

### Backup .env.prod

```bash
# Secure backup
cp .env.prod .env.prod.backup.$(date +%Y%m%d)
# Store in secure location (not git!)
```

### Restore .env.prod

```bash
# Restore from backup
cp .env.prod.backup.20240815 .env.prod
docker-compose -f docker-compose.prod.yml restart
```

---

## 🔐 Sharing with Team

### What to share (Safe)
```
✅ .env.dev.example      ← Use this as template
✅ .env.prod.example     ← Use this as template
✅ ENV_CONFIGURATION.md  ← This guide
```

### What to NOT share (Secrets)
```
❌ .env                  ← Contains dev passwords
❌ .env.dev              ← Contains dev credentials
❌ .env.prod             ← NEVER EVER SHARE!
```

---

**Last Updated**: 2026-08-15  
**Version**: 1.0  
**Status**: Production Ready ✅
