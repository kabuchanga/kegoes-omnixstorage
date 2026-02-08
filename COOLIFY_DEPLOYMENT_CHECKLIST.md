# Coolify Deployment Checklist for OmnixStorage

This checklist guides you through deploying OmnixStorage to Coolify with proper configuration for the "no available server" issue.

## Pre-Deployment Checklist

### 1. **GitHub Repository** ✅
- [x] Code pushed to: `https://github.com/kabuchanga/kegoes-omnixstorage.git`
- [x] Branch: `main`
- [x] Contains: `docker-compose.yaml`, `docker-compose.yml`, `.env.example`

### 2. **Connect to Coolify** 
- [ ] Create new application in Coolify
- [ ] Connect GitHub repository: `https://github.com/kabuchanga/kegoes-omnixstorage.git`
- [ ] Select branch: `main`
- [ ] Set custom domain: `demo.omnixstorage.kegeosapps.com` (your domain)
- [ ] Choose docker-compose deployment type
- [ ] Set docker-compose file path: `./docker-compose.yaml` (default)

### 3. **Configure Environment Variables** ⚠️ IMPORTANT
- [ ] Application > Settings > General > Environment Variables
- [ ] Add the following variables:

| Variable | Value | Notes |
|----------|-------|-------|
| `OMNIX_PUBLIC_DOMAIN` | `demo.omnixstorage.kegeosapps.com` | **Your domain** - Used by Traefik for routing |
| `OMNIX_TAG` | `omnixstorage` | Docker image tag |
| `OMNIX_ADMIN_USER` | `admin` | Console username |
| `OMNIX_ADMIN_PASSWORD` | `change-me-in-production` | **Change this!** |
| `OMNIX_S3_ACCESS_KEY` | `admin` | S3 API access key |
| `OMNIX_S3_SECRET_KEY` | `change-me-in-production` | **Change this!** |
| `OMNIX_CONSOLE_API_URL` | `https://demo.omnixstorage.kegeosapps.com:9000` | **Must include :9000** |

### 4. **Port Mapping Configuration** 🔌
The `docker-compose.yaml` defines explicit port mappings. **Expose both ports in Coolify:**

- [ ] Application > Settings > Ports
- [ ] Port 3001 (Console UI) - Maps to nginx:80 inside container
- [ ] Port 9000 (Storage API) - Maps to omnix-node1:5000 inside container

**Port Mapping Details:**
```
External Port → Internal Service → Container Port
3001 → omnix-console → 80 (nginx)
9000 → omnix-node1 → 5000 (.NET API)
```

**Why both ports?**
- Coolify's reverse proxy uses these ports to route traffic
- Console UI requests → port 3001 → omnix-console
- API requests → port 9000 → omnix-node1
- Both must be accessible for the system to work

### 5. **Traefik Reverse Proxy Configuration** 🔄
The `docker-compose.yaml` includes Traefik labels that configure Coolify's reverse proxy:

**What these labels do:**
- `traefik.enable=true` - Enables automatic service discovery
- `traefik.http.services.*.loadbalancer.server.port=XXXX` - Tells Traefik which port the service listens on
- `traefik.http.routers.*.rule=Host(...) && PathPrefix(...)` - Matches incoming requests to route them correctly
- `traefik.http.routers.*.priority=XX` - Higher priority routes are checked first (API:10, Console:1)
- `traefik.http.routers.*.tls=true` - Enables HTTPS/TLS (Let's Encrypt certificate)

**Routing Logic:**
| Request | Matches | Routes To | Port |
|---------|---------|-----------|------|
| `GET https://demo.omnixstorage.kegeosapps.com/health` | Host + PathPrefix(/health) | omnix-node1 | 9000 |
| `GET https://demo.omnixstorage.kegeosapps.com/s3/...` | Host + PathPrefix(/s3) | omnix-node1 | 9000 |
| `GET https://demo.omnixstorage.kegeosapps.com/api/...` | Host + PathPrefix(/api) | omnix-node1 | 9000 |
| `GET https://demo.omnixstorage.kegeosapps.com/bucket/...` | Host + PathPrefix(/bucket) | omnix-node1 | 9000 |
| `GET https://demo.omnixstorage.kegeosapps.com/` | Host (no path match) | omnix-console | 3001 |

**No additional configuration needed** - Labels in docker-compose.yaml are automatically read by Traefik when the container starts.

### 6. **Deploy the Application** 🚀
- [ ] Application > Settings > Advanced > Deployment
- [ ] Click "Deploy" or "Redeploy"
- [ ] Wait for status to show "Running" (usually 2-5 minutes)
- [ ] Check build logs for any errors (Settings > Logs > Build Logs)

### 7. **Verify Deployment** ✓

**Test Console UI:**
- [ ] Open in browser: `https://demo.omnixstorage.kegeosapps.com:3001`
- [ ] Should display login screen with username/password
- [ ] Login with: username=`admin`, password=`change-me-in-production`

**Test API Health:**
- [ ] Open in browser: `https://demo.omnixstorage.kegeosapps.com:9000/health`
- [ ] Should return HTTP 200 with JSON response like `{"healthy":true}`

**Check Browser Console:**
- [ ] Open DevTools (F12) → Console tab
- [ ] Look for "No available server" errors
- [ ] All API requests should show Status 200, not 0 or 404

## Post-Deployment Configuration

### 8. **Set Production Credentials** 🔐
After verifying deployment works, update environment variables with strong passwords:

- [ ] Application > Settings > Environment Variables
- [ ] Change `OMNIX_ADMIN_PASSWORD` to a strong password
- [ ] Change `OMNIX_S3_SECRET_KEY` to a strong password
- [ ] Click "Save" and redeploy

### 9. **Enable SSL Monitoring** 🔒
- [ ] Application > Settings > SSL
- [ ] Verify Let's Encrypt certificate is present
- [ ] Certificate auto-renewal enabled (must be enabled for zero-downtime renewal)
- [ ] Renewal date shown (should be 30+ days from now)

### 10. **Monitor Application Health** 📊
- [ ] Application > Logs > Deployment Logs
- [ ] Look for errors like "unhealthy" or "connection refused"
- [ ] Application > Logs > Application Logs
- [ ] Verify no 500 errors in /api, /s3, /health endpoints

## Troubleshooting Matrix

| Symptom | Likely Cause | Solution |
|---------|-------------|----------|
| Browser shows "Connection refused" | Port not exposed | Add port 9000 in Coolify Settings > Ports |
| Browser console: "No available server" | API not routable | Check OMNIX_CONSOLE_API_URL includes `:9000` |
| 503 Service Unavailable | Container not healthy | Check build logs for errors, ensure CPU limits are adequate |
| SSL certificate error | Wrong domain in env var | Verify `OMNIX_PUBLIC_DOMAIN` matches actual domain |
| Console not loading at all | Port 3001 not exposed | Add port 3001 in Coolify Settings > Ports |
| etcd connection failed | etcd container unhealthy | Wait 2-3 minutes for startup, check Application Logs |

## Key Files Reference

- **docker-compose.yaml** - Main configuration with all service definitions and Traefik labels
- **docker-compose.yml** - Alternate filename for compatibility  
- **.env.example** - Environment variable template (used by docker-compose)
- **TRAEFIK_CONFIGURATION.md** - Detailed Traefik label documentation and debugging guide
- **TROUBLESHOOTING.md** - Comprehensive troubleshooting guide for all deployment issues

## Quick Command Reference

If you need to SSH into the Coolify server and manually check containers:

```bash
# List running containers
docker ps

# View logs for a specific service
docker logs <container-name>

# Example: View omnix-node1 API logs
docker logs kegoes_omnixstorage_omnix-node1_1

# Test API health from inside
docker exec <container-name> wget -O- http://localhost:5000/health

# View Traefik configuration
docker exec <traefik-container> cat /traefik.yml
```

## Support Resources

- **Traefik Labels**: See TRAEFIK_CONFIGURATION.md for detailed explanation
- **General Troubleshooting**: See TROUBLESHOOTING.md for 500+ line guide
- **Reverse Proxy Issues**: See COOLIFY_REVERSE_PROXY_FIX.md for routing explanation
- **No Available Server Error**: See COOLIFY_NO_SERVER_FIX.md for diagnostic steps

---

**Last Updated:** After adding Traefik reverse proxy labels to docker-compose.yaml  
**Deployment Time Estimate:** 5-10 minutes total (including domain DNS propagation)
