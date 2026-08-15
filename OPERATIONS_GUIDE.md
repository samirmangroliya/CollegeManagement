# Production Operations Guide

## Quick Reference Commands

### Docker Compose Commands

```bash
# Start services
docker-compose -f docker-compose.prod.yml up -d

# Stop services
docker-compose -f docker-compose.prod.yml down

# View logs (follow mode)
docker-compose -f docker-compose.prod.yml logs -f spring-boot-app

# View logs (last 100 lines)
docker-compose -f docker-compose.prod.yml logs --tail=100 spring-boot-app

# Check service status
docker-compose -f docker-compose.prod.yml ps

# Execute command in container
docker-compose -f docker-compose.prod.yml exec spring-boot-app sh

# Restart a service
docker-compose -f docker-compose.prod.yml restart spring-boot-app

# Update and restart
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

### Kubernetes Commands

```bash
# View deployments
kubectl get deployments -n college-prod
kubectl get pods -n college-prod
kubectl get services -n college-prod

# View detailed pod information
kubectl describe pod <pod-name> -n college-prod

# View logs
kubectl logs <pod-name> -n college-prod
kubectl logs -f <pod-name> -n college-prod  # Follow mode
kubectl logs --tail=100 <pod-name> -n college-prod

# Execute command in pod
kubectl exec -it <pod-name> -n college-prod -- /bin/sh

# Port forward for debugging
kubectl port-forward <pod-name> 8080:8080 -n college-prod

# Scale deployment
kubectl scale deployment college-management-app --replicas=3 -n college-prod

# Update image
kubectl set image deployment/college-management-app \
  college-management=collegemanagementacr.azurecr.io/college-management:new-version \
  -n college-prod

# Rollback deployment
kubectl rollout undo deployment/college-management-app -n college-prod
kubectl rollout history deployment/college-management-app -n college-prod

# View events
kubectl get events -n college-prod --sort-by='.lastTimestamp'
```

### Database Commands

```bash
# Connect to PostgreSQL
psql -h college-prod-db.postgres.database.azure.com \
  -U college_prod_user@college-prod-db \
  -d college_prod_db \
  -p 5432

# Common PostgreSQL queries
SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database;
SELECT * FROM pg_stat_activity WHERE datname='college_prod_db';

# Backup database
pg_dump -h college-prod-db.postgres.database.azure.com \
  -U college_prod_user@college-prod-db \
  college_prod_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore database
psql -h college-prod-db.postgres.database.azure.com \
  -U college_prod_user@college-prod-db \
  college_prod_db < backup_20240815_120000.sql
```

---

## Common Troubleshooting Scenarios

### Issue: Application not starting

**Symptoms**: Container exits immediately or stays in CrashLoopBackOff

**Investigation**:
```bash
# Docker Compose
docker-compose -f docker-compose.prod.yml logs spring-boot-app

# Kubernetes
kubectl logs <pod-name> -n college-prod
kubectl describe pod <pod-name> -n college-prod
```

**Common causes**:
- Database connection failure
- Invalid environment variables
- Out of memory (OOM)
- Misconfigured health checks

**Solutions**:
1. Check environment variables are correct
2. Verify database is accessible
3. Check application logs for specific errors
4. Increase resource limits if OOM
5. Verify health check endpoint is correct

---

### Issue: Database connection errors

**Symptoms**: `java.sql.SQLException: unable to connect`

**Investigation**:
```bash
# Test database connectivity
telnet college-prod-db.postgres.database.azure.com 5432

# Or with curl (requires pg_client)
pg_isready -h college-prod-db.postgres.database.azure.com -p 5432 -U college_prod_user
```

**Common causes**:
- Database not running or accessible
- Firewall rules blocking access
- Incorrect connection string
- Wrong username/password
- Network connectivity issues

**Solutions**:
1. Verify database service is running
2. Check firewall rules allow your IP/CIDR
3. Verify connection string format
4. Test credentials directly
5. Check network connectivity

---

### Issue: High memory usage

**Symptoms**: Memory usage keeps increasing, container killed

**Investigation**:
```bash
# View current memory usage
docker stats  # Docker Compose
kubectl top pods -n college-prod  # Kubernetes

# Check JVM memory settings
# Look at Spring Boot startup logs
```

**Common causes**:
- Memory leak in application
- Connection pool not releasing connections
- Cache growing unbounded
- Insufficient JVM heap size

**Solutions**:
1. Check application logs for memory leaks
2. Verify connection pool configuration
3. Increase memory limits
4. Enable memory profiling
5. Review recent code changes

---

### Issue: Slow database queries

**Symptoms**: Application responding slowly, high CPU

**Investigation**:
```bash
# Connect to database
psql -h college-prod-db.postgres.database.azure.com \
  -U college_prod_user@college-prod-db \
  -d college_prod_db

# Check slow queries (in PostgreSQL)
SELECT query, calls, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;

# Enable query logging
SET log_min_duration_statement = 1000; -- 1 second
```

**Common causes**:
- Missing database indexes
- Inefficient queries
- High volume of queries
- Incorrect statistics

**Solutions**:
1. Analyze slow query log
2. Add missing indexes
3. Optimize queries
4. Consider query caching
5. Increase database resources

---

### Issue: High error rate

**Symptoms**: Application returning 500 errors, exceptions in logs

**Investigation**:
```bash
# Check recent logs
kubectl logs -f deployment/college-management-app -n college-prod --timestamps=true

# Count errors
kubectl logs deployment/college-management-app -n college-prod | grep ERROR | wc -l
```

**Common causes**:
- Database connection pool exhausted
- Downstream service unavailable
- Invalid input/request
- Code bug or regression

**Solutions**:
1. Review error logs for patterns
2. Check database connection pool status
3. Verify downstream services
4. Check recent deployments for changes
5. Roll back if recent deployment caused it

---

### Issue: Deployment stuck in pending

**Symptoms**: Pod remains in Pending state, doesn't start

**Investigation**:
```bash
kubectl describe pod <pod-name> -n college-prod
kubectl get events -n college-prod --sort-by='.lastTimestamp'
```

**Common causes**:
- Insufficient cluster resources
- Image pull errors
- Resource requests too high
- Node selector mismatch

**Solutions**:
1. Scale cluster up (add more nodes)
2. Check image exists in registry
3. Reduce resource requests
4. Check node labels match selectors

---

## Performance Tuning

### Database Connection Pooling
```properties
# Optimal for medium traffic
SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE=10
SPRING_DATASOURCE_HIKARI_MINIMUM_IDLE=5
SPRING_DATASOURCE_HIKARI_CONNECTION_TIMEOUT=30000
SPRING_DATASOURCE_HIKARI_IDLE_TIMEOUT=600000
SPRING_DATASOURCE_HIKARI_MAX_LIFETIME=1800000
```

### Kubernetes Resource Limits
```yaml
resources:
  requests:
    cpu: 250m      # Guaranteed resources
    memory: 512Mi
  limits:
    cpu: 500m      # Maximum resources
    memory: 1Gi
```

### Auto-scaling Configuration
```yaml
minReplicas: 2       # Minimum for HA
maxReplicas: 5       # Scale up limit
CPU threshold: 70%   # Scale up at this CPU
Memory threshold: 80%  # Scale up at this memory
```

---

## Monitoring Queries

### Kubernetes Pod Health
```bash
# Check pod restart count
kubectl get pods -n college-prod -o wide

# Check for OOMKilled
kubectl get pods -n college-prod -o jsonpath='{.items[*].status.containerStatuses[*].lastState.terminated.reason}'

# Show resource usage
kubectl top pods -n college-prod
kubectl top nodes
```

### Application Health
```bash
# Health check endpoint
curl http://<app-url>/actuator/health

# Metrics endpoint
curl http://<app-url>/actuator/metrics

# Detailed metrics
curl http://<app-url>/actuator/metrics/jvm.memory.usage
curl http://<app-url>/actuator/metrics/http.server.requests
```

---

## Backup & Recovery

### Automated Backups
```bash
# Verify backup exists
az postgres server backup list \
  --resource-group college-management-rg \
  --server-name college-prod-db-server

# Manual backup
pg_dump -h college-prod-db.postgres.database.azure.com \
  -U college_prod_user@college-prod-db \
  college_prod_db | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Store backup securely
az storage blob upload \
  --account-name <storage-account> \
  --container-name backups \
  --name backup_$(date +%Y%m%d).sql.gz \
  --file backup_*.sql.gz
```

### Restore from Backup
```bash
# Restore from Azure backup
az postgres server restore \
  --resource-group college-management-rg \
  --server-name college-prod-db-server-restored \
  --restore-point-in-time "2024-08-15T12:00:00"

# Or restore from dump file
gunzip -c backup_20240815_120000.sql.gz | \
psql -h college-prod-db.postgres.database.azure.com \
  -U college_prod_user@college-prod-db \
  college_prod_db
```

---

## Alerts & Notifications

### Key Metrics to Monitor
- Pod restart count (should be 0)
- CPU usage (alert if > 80% for 5 min)
- Memory usage (alert if > 85% for 5 min)
- Error rate (alert if > 1% for 5 min)
- Database connection pool (alert if > 80% full)
- Response time (alert if p99 > 1 second)
- Database size (alert if growing unexpectedly)

### Setting up Alerts
```bash
# Azure Monitor Alert for high CPU
az monitor metrics alert create \
  --name high-cpu-alert \
  --resource-group college-management-rg \
  --scopes <resource-id> \
  --condition "avg Percentage CPU > 80" \
  --description "Alert when CPU exceeds 80%"
```
