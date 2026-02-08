#!/bin/bash
# OmnixStorage Coolify Quick Fix Automation
# This script helps verify and configure everything needed for Coolify deployment

set -e

echo "🚀 OmnixStorage Coolify Reverse Proxy Fix"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Verify docker-compose files
echo "📋 Step 1: Verifying docker-compose configuration..."
if docker-compose -f docker-compose.yaml config > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} docker-compose.yaml is valid"
else
    echo -e "${RED}✗${NC} docker-compose.yaml has errors"
    exit 1
fi

# Step 2: Check environment file
echo ""
echo "📋 Step 2: Checking environment variables..."

if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠${NC}  No .env file found. Creating from template..."
    cp .env.example .env
    echo -e "${GREEN}✓${NC} Created .env file"
fi

# Verify required variables
required_vars=("OMNIX_CONSOLE_API_URL" "OMNIX_TAG" "OMNIX_ADMIN_PASSWORD")

for var in "${required_vars[@]}"; do
    if grep -q "^$var=" .env; then
        value=$(grep "^$var=" .env | cut -d '=' -f 2)
        echo -e "${GREEN}✓${NC} $var = $value"
    else
        echo -e "${RED}✗${NC} Missing: $var"
    fi
done

# Step 3: Display Configuration Checklist
echo ""
echo "=========================================="
echo "⚙️  MANUAL CONFIGURATION CHECKLIST"
echo "=========================================="
echo ""
echo "Follow these steps in Coolify Dashboard:"
echo ""
echo "1️⃣  Go to Application > Settings > General"
echo "   Ensure OMNIX_CONSOLE_API_URL includes port 9000:"
echo "   Value: https://demo.omnixstorage.kegeosapps.com:9000"
echo ""
echo "2️⃣  Go to Application > Settings > Port/Expose"
echo "   ${YELLOW}ADD two port bindings:${NC}"
echo "   • Port 3001 → omnix-console:80 (UI)"
echo "   • Port 9000 → omnix-node1:5000 (API)"
echo ""
echo "3️⃣  Go to Application > Deployments"
echo "   Click ${YELLOW}\"Redeploy\"${NC} or ${YELLOW}\"Restart\"${NC}}"
echo "   Wait 2-3 minutes for containers to start"
echo ""
echo "4️⃣  Verify by testing:"
echo "   curl https://demo.omnixstorage.kegeosapps.com:3001/"
echo "   curl https://demo.omnixstorage.kegeosapps.com:9000/health"
echo ""
echo "=========================================="
echo ""

# Step 4: Show current configuration
echo "📦 Current Configuration:"
echo ""
echo "Services exposed in docker-compose:"
docker-compose -f docker-compose.yaml config | grep -A 2 "ports:" || echo "No ports found"
echo ""

# Step 5: Test local connectivity (if running locally)
echo "🔍 Local diagnostics:"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker is installed"
    
    if docker ps &> /dev/null; then
        echo -e "${GREEN}✓${NC} Docker daemon is running"
    else
        echo -e "${YELLOW}⚠${NC}  Docker daemon may not be running"
    fi
else
    echo -e "${YELLOW}⚠${NC}  Docker is not installed (expected if using Coolify)"
fi

echo ""
echo "=========================================="
echo "NEXT STEPS:"
echo "=========================================="
echo "1. Open your Coolify Dashboard"
echo "2. Expose BOTH ports 3001 (console) and 9000 (API)"
echo "3. Redeploy the application"
echo "4. Wait 2-3 minutes for startup"
echo "5. Test at: https://demo.omnixstorage.kegeosapps.com:3001"
echo ""
echo "For detailed instructions, see:"
echo "  - COOLIFY_REVERSE_PROXY_FIX.md"
echo "  - COOLIFY_NO_SERVER_FIX.md"
echo "=========================================="
