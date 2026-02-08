# Coolify Reverse Proxy Configuration - "No Available Server" Fix

## The Problem

When deployed through Coolify, the reverse proxy (nginx) doesn't know how to route requests:

```
Browser Request
    ↓
Coolify Reverse Proxy (HTTPS port 443)
    ↓
??? Where to send the request?
    - Console (port 3001)? 
    - API (port 5000)?
    ↓
If only console is configured:
    Console receives API request → "no available server" (can't find the endpoint)
```

---

## Root Cause

Coolify's reverse proxy is only configured to forward traffic to the **console** (nginx on port 3001).

When the console's JavaScript tries to call the API at `https://demo.omnixstorage.kegeosapps.com`, the request goes:
1. Browser → Coolify reverse proxy (HTTPS)
2. Coolify reverse proxy → Console (port 3001)
3. Console receives the request but doesn't have `/health` or S3 API endpoints
4. Result: **"no available server"**

---

## SOLUTION 1: Configure Multiple Exposed Ports in Coolify (RECOMMENDED)

**In Coolify Dashboard:**

1. **Application > Settings > Port/Expose**
2. You should see the current port (likely 3001)
3. **Add another port binding:**
   - Port: `9000`
   - Service: `omnix-node1`
   - Public: Yes (expose publicly)

4. **Save and redeploy**

This tells Coolify:
- Port 3001 → Console (UI)
- Port 9000 → API (backend)

---

## SOLUTION 2: Use Internal Container URL (Alternative)

If you can only expose ONE port in Coolify:

**Modify the console API URL to use internal container networking:**

```env
# Instead of:
OMNIX_CONSOLE_API_URL=https://demo.omnixstorage.kegeosapps.com

# Use internal container URL:
OMNIX_CONSOLE_API_URL=http://omnix-node1:5000
```

**How it works:**
1. Browser loads console from `https://demo.omnixstorage.kegeosapps.com:3001`
2. Console's JavaScript code calls `http://omnix-node1:5000` (internal Docker network)
3. Docker DNS resolves `omnix-node1` to the correct container IP
4. Request reaches the API successfully

**Caveat:** Modern browsers may block this due to CORS or mixed content policies.

---

## SOLUTION 3: Path-Based Routing (Advanced)

If Coolify supports custom nginx configuration:

```nginx
server {
    listen 443 ssl http2;
    server_name demo.omnixstorage.kegeosapps.com;
    
    # Route /health and S3 API to backend
    location ~ ^/(health|s3/|api/) {
        proxy_pass http://omnix-node1:5000;
        proxy_set_header Host $host;
    }
    
    # Everything else to console
    location / {
        proxy_pass http://omnix-console:80;
        proxy_set_header Host $host;
    }
}
```

But this requires SSH access to Coolify server.

---

## RECOMMENDED FIX: Solution 1 + Updates

### Step 1: Update Environment Variable in Coolify

In Coolify Environment Variables, change:
```
FROM:
OMNIX_CONSOLE_API_URL=https://demo.omnixstorage.kegeosapps.com

TO:
OMNIX_CONSOLE_API_URL=https://demo.omnixstorage.kegeosapps.com:9000
```

This tells the console to reach the API on port 9000.

### Step 2: Expose Port 9000 in Coolify

1. Application > Settings > Port
2. Add exposed port: **9000** (pointing to omnix-node1:5000)
3. Ensure port 3001 is also exposed (for console)
4. Save

### Step 3: Update docker-compose.yaml

Add explicit labels for Coolify port detection:

```yaml
omnix-node1:
  # ... existing config ...
  ports:
    - "9000:5000"  # Exposed for Coolify reverse proxy
  labels:
    - "coolify.port=9000"  # Tell Coolify this is an exposed service

console:
  # ... existing config ...
  ports:
    - "3001:80"  # Exposed for UI
  labels:
    - "coolify.port=3001"  # Tell Coolify this is an exposed service
```

### Step 4: Redeploy

After making changes in Coolify:
1. Click "Redeploy" or "Restart"
2. Wait 60 seconds for all containers to start
3. Try accessing the app again

---

## VERIFICATION

After applying the fix:

1. **Test Console**
   ```
   https://demo.omnixstorage.kegeosapps.com:3001
   # Should load the UI
   ```

2. **Test API**
   ```
   https://demo.omnixstorage.kegeosapps.com:9000/health
   # Should return 200
   ```

3. **Browser Console (F12)**
   - Open DevTools
   - Network tab
   - Should see API requests going to `:9000`
   - Should be 200 status, not failing

---

## If Still Not Working

### Check Coolify Settings

1. **Which port is "primary"?**
   - Application > Settings
   - Look for "Port" or "Expose" settings
   - Verify BOTH 3001 and 9000 are listed

2. **Check firewall rules**
   - Coolify server may block outgoing ports from Docker
   - Contact your hosting provider

3. **Check Docker networking**
   - From Coolify server:
   ```bash
   docker exec omnix-console curl http://omnix-node1:5000/health
   # Should return 200
   ```

### Alternative: Use Kubernetes Network Policy

If running on Coolify with Kubernetes:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-omnix
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 5000
```

---

## Summary

The "no available server" error happens because:
1. ❌ Coolify reverse proxy only knows about console (port 3001)
2. ❌ Console tries to reach API at the same domain
3. ❌ Request loops back to console, which has no S3 API endpoints

Fix by:
1. ✅ Expose port 9000 in Coolify (for omnix-node1)
2. ✅ Update console API URL to point to port 9000
3. ✅ Redeploy
