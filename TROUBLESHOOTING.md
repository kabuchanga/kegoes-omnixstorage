# OmnixStorage Deployment Troubleshooting

## 503 Service Unavailable Errors

If you're seeing 503 errors when accessing the application, follow these steps:

### 1. Check Container Status
Verify all three containers are running:
```bash
docker ps | grep omnix
docker ps | grep etcd
```

Expected running containers:
- `omnix-etcd` - Distributed metadata store
- `omnix-node1` - Storage service node
- `omnix-console` - Web UI console

### 2. Check Container Logs
Review logs for each service:
```bash
# Check etcd startup
docker logs omnix-etcd

# Check storage node for connection issues
docker logs omnix-node1

# Check console for API connection errors
docker logs omnix-console
```

### 3. Verify Network Connectivity
Ensure containers can reach each other:
```bash
# Check if omnix-node1 can reach etcd
docker exec omnix-node1 curl -f http://etcd:2379/version

# Check if console can reach the storage API
docker exec omnix-console curl -f http://omnix-node1:5000/health
```

### 4. Check Health Status
Verify services pass health checks:
```bash
# etcd health
docker exec omnix-etcd curl http://localhost:2379/health

# Storage node health
docker exec omnix-node1 curl http://localhost:5000/health
```

### 5. Environment Variables
Ensure required environment variables are set:
```bash
# Copy .env.example to .env and customize
cp .env.example .env

# Verify Docker Compose is using the .env file
docker compose config | grep OMNIX
```

### 6. Resource Constraints
Check if containers are out of memory or CPU:
```bash
docker stats
```

Current limits: 4 CPUs, 8GB RAM per service

---

## Common Issues & Solutions

### etcd Health Check Failing
**Error:** `healthcheck: etcdctl: command not found`
- **Solution:** Health check uses `wget` instead of `etcdctl` - ensure wget is available

### omnix-node1 Won't Start
**Error:** `Cannot connect to etcd at http://etcd:2379`
- **Solution:** 
  1. Check etcd is fully started: `docker logs omnix-etcd | tail -20`
  2. Wait 30+ seconds for etcd to be ready
  3. Manually restart the node: `docker restart omnix-node1`

### Console Shows 503 Errors
**Error:** Cannot reach the storage API
- **Solution:**
  1. Verify `OMNIX_CONSOLE_API_URL` points to the correct storage endpoint
  2. Check `omnix-node1` is responding: `curl http://<node-ip>:9000/health`
  3. Verify network connectivity between console and storage containers

### Out of Memory
**Error:** `Container killed` or `OOMKilled`
- **Solution:** Increase memory limits in `docker-compose.yml`:
  ```yaml
  deploy:
    resources:
      limits:
        memory: 16G  # Increase if available
  ```

### Port Conflicts
**Error:** `Cannot bind to port 9000/5000/3001`
- **Solution:** Check if ports are already in use:
  ```bash
  netstat -ano | findstr :9000  # Windows
  lsof -i :9000                  # Linux/Mac
  ```

---

## Quick Restart

To restart all services cleanly:
```bash
# Stop all containers
docker compose down

# Wait a moment
sleep 5

# Start fresh
docker compose up -d

# Monitor startup - wait until all services are healthy
docker compose logs -f

# Check health status (Ctrl+C when satisfied)
```

---

## Performance Tuning

### Increase Concurrency
Edit `omnix-node1` environment variables:
```yaml
- ASPNETCORE_Kestrel__Limits__MaxConcurrentConnections=5000
- ASPNETCORE_Kestrel__Limits__MaxRequestBodySize=10737418240  # 10GB
```

### Optimize Storage
For better performance with large files:
```yaml
- USE_REPLICATION_MODE=true
- REPLICATION_FACTOR=2  # Increase from 1
```

---

## Production Checklist

- [ ] Change default credentials (`OMNIX_ADMIN_PASSWORD`, `OMNIX_S3_SECRET_KEY`)
- [ ] Set `ASPNETCORE_ENVIRONMENT=Production` (already set)
- [ ] Configure persistent volumes (already configured)
- [ ] Set resource limits appropriately for your hardware
- [ ] Configure backups for etcd data
- [ ] Monitor logs regularly
- [ ] Set up health check monitoring
- [ ] Plan cluster expansion (add more nodes)
