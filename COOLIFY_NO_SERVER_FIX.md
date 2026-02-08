# OmnixStorage Coolify Deployment - Quick Fix Guide

## "No Available Server" Error - Diagnosis & Fix

### Root Cause
The console (nginx/UI) cannot reach the omnix-node1 (storage API) service.

---

## QUICK FIXES (Try These First)

### Fix 1: Verify Environment Variables in Coolify
**In Coolify Dashboard:**
1. Go to Application > Settings > General
2. Look at **Environment Variables** section
3. Ensure these are set exactly:

```
OMNIX_TAG=omnixstorage
OMNIX_ADMIN_USER=admin
OMNIX_ADMIN_PASSWORD=omnix-console-2026
OMNIX_S3_ACCESS_KEY=admin
OMNIX_S3_SECRET_KEY=omnix-secret-2026
OMNIX_CONSOLE_API_URL=https://demo.omnixstorage.kegeosapps.com
```

**Important:** The `OMNIX_CONSOLE_API_URL` must use your full domain with HTTPS.

### Fix 2: Restart All Containers
In Coolify Dashboard:
1. Go to Application > Deployments
2. Click "Stop" button
3. Wait 30 seconds
4. Click "Restart" / "Deploy"
5. Wait 60 seconds for all containers to start
6. Check if error is fixed

### Fix 3: Check Container Health
In Coolify Dashboard:
1. Go to Application > Deployments
2. Expand container list
3. All three should show **running** status:
   - ✅ omnix-etcd (running)
   - ✅ omnix-node1 (running)
   - ✅ omnix-console (running)

If any show **unhealthy** or **restarting**, click on it to see error logs.

### Fix 4: Force Redeploy (Nuclear Option)
If still failing:
1. In Coolify Dashboard > Application > Settings
2. Find **Persistent Volumes** section
3. **Back up data** if you have important data
4. Delete all volumes (etcd-data, node1-data, omnix-keys)
5. Click "Redeploy from scratch"
6. Wait 2-3 minutes for full startup

---

## ADVANCED DIAGNOSTICS

### Check Console Logs
**In Coolify:**
1. Application > Deployments > View Logs
2. Filter for "console" or "omnix-console"
3. Look for error messages like:
   - `Connection refused`
   - `Unable to reach`
   - `ECONNREFUSED`

### Check API Logs
**In Coolify:**
1. Application > Deployments > View Logs  
2. Filter for "omnix-node1"
3. Verify you see messages like:
   - `ready to serve client requests` (from etcd)
   - `[AFTER-SIGV4-MIDDLEWARE] Path` (from omnix-node1)

### Test Connectivity
If you have SSH access to Coolify server:

```bash
# 1. Check if containers exist and are running
docker ps | grep omnix

# 2. Test console → API connectivity
docker exec omnix-console curl -v http://omnix-node1:5000/health

# 3. Test API directly
docker exec omnix-node1 curl -v http://localhost:5000/health

# 4. Test etcd
docker exec omnix-etcd curl http://localhost:2379/health

# 5. Check container logs
docker logs omnix-node1 | tail -50
docker logs omnix-console | tail -50
```

---

## COMMON CAUSES & SOLUTIONS

### Issue: omnix-node1 container crashes on startup

**Symptoms:**
- Container shows "restarting" in Coolify
- Logs show connection errors to etcd

**Solution:**
1. Increase startup delay in docker-compose.yaml:
```yaml
omnix-node1:
  healthcheck:
    start_period: 60s  # Increase from 30s
```
2. Redeploy

### Issue: etcd fails to start

**Symptoms:**
- etcd container keeps restarting
- Logs show "directory /etcd-data exist, but the permission is..."

**Solution:**
1. In Coolify, delete the etcd-data volume (it will recreate)
2. Redeploy
3. etcd will initialize fresh

### Issue: Wrong API URL in console

**Symptoms:**
- Console loads fine
- Network tab shows requests to `localhost:9000` instead of your domain

**Solution:**
1. In Coolify Environment Variables, set:
```
OMNIX_CONSOLE_API_URL=https://demo.omnixstorage.kegeosapps.com
```
2. Redeploy console only

### Issue: Mixed HTTP/HTTPS

**Symptoms:**
- Browser console shows: "Mixed Content: The page was loaded over HTTPS, but requested an insecure resource"

**Solution:**
1. Ensure **OMNIX_CONSOLE_API_URL** uses `https://` (not `http://`)
2. Coolify reverse proxy handles the HTTPS
3. Internal containers communicate via HTTP

### Issue: Network connectivity between containers

**Symptoms:**
- All containers running but can't communicate
- `curl` tests timeout

**Cause:**
- Coolify network configuration issue
- Docker compose version mismatch

**Solution:**
1. In docker-compose.yaml, verify network definition:
```yaml
networks:
  omnix-network:
    driver: bridge
```
2. Redeploy
3. Or contact Coolify support

---

## VERIFICATION CHECKLIST

After fixing, verify these steps:

- [ ] All 3 containers show "running" in Coolify
- [ ] `curl https://demo.omnixstorage.kegeosapps.com/health` returns 200
- [ ] Browser console shows NO network errors (F12 > Network tab)
- [ ] Page loads without "no available server" message
- [ ] Can create a bucket or view buckets in the UI

---

## IF STILL FAILING

1. **Collect Logs**
   - Go to Application > Deployments > View All Logs
   - Copy entire log output
   - Save to file

2. **Check Coolify Status**
   - Dashboard > Settings > System
   - Verify Coolify version is up to date
   - Check disk space is available

3. **Check DNS**
   ```bash
   nslookup demo.omnixstorage.kegeosapps.com
   # Should return your Coolify server's IP
   ```

4. **Get Help**
   - Share the logs with support
   - Include your docker-compose.yaml
   - Include environment variables list
   - Include exact error message from browser
