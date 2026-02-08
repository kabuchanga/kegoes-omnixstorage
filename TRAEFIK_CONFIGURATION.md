# Traefik Configuration for Coolify

## Overview

Coolify uses **Traefik** as its reverse proxy and load balancer. Traefik uses Docker labels to automatically discover and configure routes.

The docker-compose.yaml now includes Traefik labels that tell Coolify how to route traffic:
- Console requests → omnix-console (port 80)
- API requests → omnix-node1 (port 5000)

---

## How It Works

### Without Traefik Labels
```
Browser → Coolify Reverse Proxy
  ↓
❌ Doesn't know where to send request
  ↓
Result: "no available server"
```

### With Traefik Labels (Current)
```
Browser → Coolify Reverse Proxy (Traefik)
  ↓
Reads labels from containers
  ↓
Routes based on:
  - Host/domain
  - Path pattern (/health, /s3/*, /api/*, /bucket/*)
  - Priority (API path: priority 10, Console: priority 1)
  ↓
✅ Console request → omnix-console:80
✅ API request → omnix-node1:5000
```

---

## Label Explanations

### For omnix-node1 (Storage API)

```yaml
labels:
  # Enable Traefik service discovery for this container
  - "traefik.enable=true"
  
  # Define the internal service
  # (Traefik needs to know which port to forward to)
  - "traefik.http.services.omnixstorage-api.loadbalancer.server.port=5000"
  
  # Define routing rule
  # Routes requests matching these paths to this service
  - "traefik.http.routers.omnixstorage-api.rule=Host(`demo.omnixstorage.kegeosapps.com`) && PathPrefix(`/health`, `/s3`, `/api`, `/bucket`)"
  
  # Use HTTPS (secure)
  - "traefik.http.routers.omnixstorage-api.entrypoints=websecure"
  - "traefik.http.routers.omnixstorage-api.tls=true"
  
  # Priority: Higher numbers match first
  # API has priority 10, so it matches before console (priority 1)
  - "traefik.http.routers.omnixstorage-api.priority=10"
```

### For omnix-console (Web UI)

```yaml
labels:
  # Enable Traefik service discovery
  - "traefik.enable=true"
  
  # Define the internal service
  - "traefik.http.services.omnixstorage-console.loadbalancer.server.port=80"
  
  # Define routing rule (all requests to this domain)
  - "traefik.http.routers.omnixstorage-console.rule=Host(`demo.omnixstorage.kegeosapps.com`)"
  
  # Use HTTPS (secure)
  - "traefik.http.routers.omnixstorage-console.entrypoints=websecure"
  - "traefik.http.routers.omnixstorage-console.tls=true"
  
  # Priority: Lower number (catch-all route)
  # This is the default/fallback route
  - "traefik.http.routers.omnixstorage-console.priority=1"
```

---

## Routing Logic

When a request comes in:

### Scenario 1: API Request
```
GET https://demo.omnixstorage.kegeosapps.com/health
  ↓
Traefik checks routers in order of priority
  ↓
Router "omnixstorage-api" (priority 10) matches:
  - Host: demo.omnixstorage.kegeosapps.com ✓
  - Path: /health (matches PathPrefix) ✓
  ↓
Route to service "omnixstorage-api" on port 5000
  ↓
omnix-node1 handles the request ✅
```

### Scenario 2: Console Request
```
GET https://demo.omnixstorage.kegeosapps.com/
  ↓
Traefik checks routers in order of priority
  ↓
Router "omnixstorage-api" (priority 10) checks:
  - Host: demo.omnixstorage.kegeosapps.com ✓
  - Path: / (does NOT match PathPrefix) ✗
  ↓
Router "omnixstorage-console" (priority 1) checks:
  - Host: demo.omnixstorage.kegeosapps.com ✓
  ↓
Route to service "omnixstorage-console" on port 80
  ↓
omnix-console handles the request ✅
```

---

## Environment Variables

### OMNIX_PUBLIC_DOMAIN
Used in the Traefik labels for routing rules.

```env
# In .env file:
OMNIX_PUBLIC_DOMAIN=demo.omnixstorage.kegeosapps.com
```

Traefik substitutes this value in the labels:
```yaml
- "traefik.http.routers.omnixstorage-api.rule=Host(`${OMNIX_PUBLIC_DOMAIN}`)"
```

Becomes (after substitution):
```yaml
- "traefik.http.routers.omnixstorage-api.rule=Host(`demo.omnixstorage.kegeosapps.com`)"
```

---

## Modifying Routes

### Add More API Paths
To route additional paths to the API, update the rule:

```yaml
# Currently:
- "traefik.http.routers.omnixstorage-api.rule=Host(`...`) && PathPrefix(`/health`, `/s3`, `/api`, `/bucket`)"

# Add /metrics path:
- "traefik.http.routers.omnixstorage-api.rule=Host(`...`) && PathPrefix(`/health`, `/s3`, `/api`, `/bucket`, `/metrics`)"
```

### Redirect HTTP to HTTPS
Traefik can automatically redirect:

```yaml
# Add HTTP entrypoint:
- "traefik.http.routers.omnixstorage-api-http.rule=Host(`${OMNIX_PUBLIC_DOMAIN}`)"
- "traefik.http.routers.omnixstorage-api-http.entrypoints=web"
- "traefik.http.routers.omnixstorage-api-http.middlewares=redirect-https"
```

---

## Debugging Traefik Routes

### View Active Routes in Coolify
```
Dashboard > Application > Deployments > View Logs
Look for Traefik entries:
  "loaded provider docker"
  "entrypoint entrypoints has no routes"
  "added router omnixstorage-api"
  "added router omnixstorage-console"
```

### Test Routes Manually
```bash
# Console route
curl -H "Host: demo.omnixstorage.kegeosapps.com" http://localhost:80/

# API route  
curl -H "Host: demo.omnixstorage.kegeosapps.com" http://localhost:9000/health

# Verify routing (should reach correct service)
curl -v https://demo.omnixstorage.kegeosapps.com/health
```

---

## Common Issues & Solutions

### Issue: Traefik ignores labels
**Cause:** `traefik.enable=true` is missing or labels have typos

**Solution:**
```yaml
labels:
  - "traefik.enable=true"  # Must be first
  # ... other labels
```

### Issue: Wrong service receives request
**Cause:** Priority ordering incorrect or path pattern too broad

**Solution:**
- API path check: priority should be higher than console
- Console is catch-all with lower priority
- Check PathPrefix exactly matches your endpoints

### Issue: Mixed HTTP/HTTPS
**Cause:** Not specifying `entrypoints=websecure` and `tls=true`

**Solution:**
```yaml
- "traefik.http.routers.omnixstorage-api.entrypoints=websecure"
- "traefik.http.routers.omnixstorage-api.tls=true"
```

### Issue: CORS or mixed content errors
**Cause:** Console connects to API using HTTP instead of HTTPS

**Solution:**
Ensure `OMNIX_CONSOLE_API_URL` uses HTTPS:
```env
OMNIX_CONSOLE_API_URL=https://demo.omnixstorage.kegeosapps.com:9000
```

---

## Example: Custom Traefik Configuration

If you need advanced routing (middleware, rate limiting, etc.):

1. **SSH into Coolify server**
2. **Modify labels in docker-compose.yaml**
3. **Redeploy**

Example: Add rate limiting
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.services.omnixstorage-api.loadbalancer.server.port=5000"
  - "traefik.http.routers.omnixstorage-api.rule=Host(`...`) && PathPrefix(...)"
  # Add middleware for rate limiting
  - "traefik.http.routers.omnixstorage-api.middlewares=api-ratelimit"
  - "traefik.http.middlewares.api-ratelimit.ratelimit.average=100"
  - "traefik.http.middlewares.api-ratelimit.ratelimit.burst=200"
```

---

## References

- [Traefik Docker Provider Documentation](https://doc.traefik.io/traefik/providers/docker/)
- [Coolify Documentation](https://docs.coollabs.io/)
- [Traefik Routers](https://doc.traefik.io/traefik/routing/routers/)
- [Traefik Services](https://doc.traefik.io/traefik/routing/services/)

---

**Status:** Traefik labels are now configured in docker-compose.yaml ✅  
**Last Updated:** 2026-02-09
