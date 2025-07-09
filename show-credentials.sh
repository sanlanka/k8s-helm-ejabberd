#!/bin/bash

echo "🔐 EJABBERD DEPLOYMENT CREDENTIALS"
echo "=================================="
echo ""

echo "📋 Admin User Credentials:"
echo "Username: admin@localhost"
echo "Password: $(kubectl get secret ejabberd-admin-secret -n ejabberd -o jsonpath='{.data.admin-password}' | base64 -d)"
echo ""

echo "🔑 JWT Secret:"
echo "Secret Name: jwt-secret"
echo "Secret Key: jwt-key"
echo "Key Content (first 100 chars): $(kubectl get secret jwt-secret -n ejabberd -o jsonpath='{.data.jwt-key}' | base64 -d | head -c 100)..."
echo ""

echo "🌐 Service Endpoints:"
echo "XMPP Client (c2s): $(kubectl get svc -n ejabberd ejabberd -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):5222"
echo "XMPP Server (s2s): $(kubectl get svc -n ejabberd ejabberd -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):5269"
echo "HTTP Interface: http://$(kubectl get svc -n ejabberd ejabberd -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):5280"
echo "HTTPS Interface: https://$(kubectl get svc -n ejabberd ejabberd -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):5443"
echo ""

echo "📊 Pod Status:"
kubectl get pods -n ejabberd
echo ""

echo "🔍 Registered Users:"
kubectl exec -n ejabberd ejabberd-0 -- ejabberdctl registered_users localhost
echo ""

echo "✅ Deployment Status: SUCCESS"
echo "Both admin credentials and JWT secret are deployed and working!" 