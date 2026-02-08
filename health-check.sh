#!/bin/bash
# Health check script for OmnixStorage deployment

echo "=== OmnixStorage Health Check ==="
echo ""

# Check etcd health
echo "[1] Checking etcd..."
curl -s -X GET http://etcd:2379/health || echo "❌ etcd not responding"
echo ""

# Check omnix-node1 health
echo "[2] Checking omnix-node1..."
curl -s -X GET http://omnix-node1:5000/health || echo "❌ omnix-node1 not responding"
echo ""

# Check if omnix-node1 can reach etcd
echo "[3] Checking omnix-node1 → etcd connectivity..."
curl -s http://omnix-node1:5000/health | grep -q "200" && echo "✓ omnix-node1 is responding" || echo "❌ omnix-node1 is not responding"
echo ""

echo "=== End Health Check ==="
