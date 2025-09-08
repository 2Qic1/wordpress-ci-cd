#!/bin/bash

# Создание структуры директорий
mkdir -p wordpress/{templates,config,src} argocd discord .github/workflows

# WordPress Deployment
cat > wordpress/templates/deployment.yaml << 'DEPLOYMENT'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  replicas: 2
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress:6.4
        ports:
        - containerPort: 80
        env:
        - name: WORDPRESS_DB_HOST
          valueFrom:
            configMapKeyRef:
              name: wordpress-config
              key: db-host
        - name: WORDPRESS_DB_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: username
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: password
        - name: WORDPRESS_DB_NAME
          value: wordpress
        volumeMounts:
        - name: nfs-volume
          mountPath: /var/www/html/wp-content
      volumes:
      - name: nfs-volume
        nfs:
          server: 192.168.37.105
          path: /mnt/IT-Academy/nfs-data/sa2-32-25/qic/default/project
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress-service
spec:
  selector:
    app: wordpress
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
DEPLOYMENT

# Ingress
cat > wordpress/templates/ingress.yaml << 'INGRESS'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: wordpress.k8s-3.sa
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wordpress-service
            port:
              number: 80
INGRESS

# ConfigMap
cat > wordpress/templates/configmap.yaml << 'CONFIGMAP'
apiVersion: v1
kind: ConfigMap
metadata:
  name: wordpress-config
data:
  db-host: mysql-service
  app-version: "v1"
CONFIGMAP

# MySQL Deployment
cat > wordpress/templates/mysql.yaml << 'MYSQL'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: password
        - name: MYSQL_DATABASE
          value: wordpress
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: username
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: password
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
  type: ClusterIP
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
MYSQL

# Secret манифест (для создания через kubectl)
cat > wordpress/templates/secret.yaml << 'SECRET'
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
type: Opaque
data:
  username: d3B1c2Vy
  password: d3BwYXNzd29yZA==
SECRET

# ArgoCD Application
cat > argocd/application.yaml << 'ARGOCD'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: wordpress-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/2Qic1/wordpress-ci-cd.git
    targetRevision: HEAD
    path: wordpress
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
    - CreateNamespace=true
ARGOCD

# Discord webhook script
cat > discord/webhook.py << 'DISCORD'
#!/usr/bin/env python3
import requests
import json
import time
import sys
import os

WEBHOOK_URL = "https://discordapp.com/api/webhooks/1409577998444793856/TAduFB3cR-Ip3CxquarZbn99cvKUKTuJFonE8kVxosxbUTtFZVTF-haqyPw8GPZkANmG"

def send_discord_message(message, deployment_time=None):
    data = {
        "content": message,
        "username": "CI/CD Bot",
        "embeds": []
    }
    
    if deployment_time:
        embed = {
            "title": "Deployment Statistics",
            "color": 0x00ff00,
            "fields": [
                {
                    "name": "Deployment Time",
                    "value": f"{deployment_time:.2f} seconds",
                    "inline": True
                },
                {
                    "name": "Status",
                    "value": "✅ Successful",
                    "inline": True
                }
            ]
        }
        data["embeds"].append(embed)
    
    response = requests.post(WEBHOOK_URL, json=data)
    return response.status_code == 204

if __name__ == "__main__":
    if len(sys.argv) > 1:
        action = sys.argv[1]
        start_time = float(sys.argv[2]) if len(sys.argv) > 2 else time.time()
        
        if action == "start":
            send_discord_message("🚀 Deployment started!")
        elif action == "success":
            end_time = time.time()
            deployment_time = end_time - start_time
            send_discord_message("✅ Deployment completed successfully!", deployment_time)
        elif action == "fail":
            send_discord_message("❌ Deployment failed!")
DISCORD

# GitHub Actions workflow
cat > .github/workflows/ci-cd.yaml << 'WORKFLOW'
name: WordPress CI/CD

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Validate Kubernetes manifests
      run: |
        find . -name "*.yaml" -o -name "*.yml" | xargs -I {} sh -c 'echo "Validating {}" && kubectl apply -f {} --dry-run=client || exit 1'
        
    - name: Check YAML syntax
      uses: actions-hub/yamllint@master
      with:
        file_or_dir: .
        config_file: .yamllint.yml
        
    - name: Test Discord webhook
      run: |
        python3 discord/webhook.py test
        
  deploy:
    needs: test
    if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || github.ref == 'refs/heads/master')
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Start deployment notification
      run: |
        echo "DEPLOYMENT_START=$(date +%s)" >> $GITHUB_ENV
        python3 discord/webhook.py start $DEPLOYMENT_START
        
    - name: Setup Kubernetes
      uses: azure/setup-kubectl@v1
      
    - name: Deploy to Kubernetes
      run: |
        kubectl apply -f wordpress/templates/secret.yaml
        kubectl apply -f wordpress/templates/
        
    - name: Success notification
      run: |
        python3 discord/webhook.py success $DEPLOYMENT_START
        
    - name: Failure notification
      if: failure()
      run: |
        python3 discord/webhook.py fail $DEPLOYMENT_START
WORKFLOW

# Version 1 - Базовая версия
cat > wordpress/src/index-v1.php << 'V1'
<?php
// Базовая версия WordPress
echo "<!DOCTYPE html>
<html>
<head>
    <title>WordPress v1 - Basic</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f0f0f0; }
        .header { background: #0073aa; color: white; padding: 20px; text-align: center; }
        .content { background: white; padding: 20px; margin: 20px 0; border-radius: 5px; }
        .footer { text-align: center; color: #666; margin-top: 30px; }
    </style>
</head>
<body>
    <div class='header'>
        <h1>WordPress v1 - Basic Version</h1>
    </div>
    <div class='content'>
        <h2>Welcome to WordPress</h2>
        <p>This is the basic version of our WordPress site.</p>
        <p>Version: v1.0.0</p>
    </div>
    <div class='footer'>
        <p>Powered by WordPress CI/CD Pipeline</p>
    </div>
</body>
</html>";
?>
V1

# Version 2 - Измененный интерфейс
cat > wordpress/src/index-v2.php << 'V2'
<?php
// Версия 2 - Улучшенный интерфейс
echo "<!DOCTYPE html>
<html>
<head>
    <title>WordPress v2 - Enhanced</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { 
            background: rgba(255,255,255,0.1); 
            backdrop-filter: blur(10px);
            color: white; 
            padding: 30px; 
            text-align: center; 
            border-radius: 15px;
            margin-bottom: 30px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        }
        .content { 
            background: rgba(255,255,255,0.95); 
            padding: 30px; 
            border-radius: 15px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        }
        .footer { 
            text-align: center; 
            color: rgba(255,255,255,0.8); 
            margin-top: 40px;
            padding: 20px;
        }
        h1 { font-size: 2.5em; margin: 0; }
        h2 { color: #333; border-bottom: 2px solid #0073aa; padding-bottom: 10px; }
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🚀 WordPress v2 - Enhanced</h1>
            <p>Modern design with gradient background</p>
        </div>
        <div class='content'>
            <h2>Welcome to Enhanced WordPress</h2>
            <p>This version features a modern glass-morphism design with smooth gradients.</p>
            <p>Version: v2.0.0</p>
            <p>New features: Responsive design, Modern UI, Better user experience</p>
        </div>
        <div class='footer'>
            <p>Powered by WordPress CI/CD Pipeline | Enhanced Edition</p>
        </div>
    </div>
</body>
</html>";
?>
V2

# Version 3 - Нерабочая версия
cat > wordpress/src/index-v3.php << 'V3'
<?php
// Версия 3 - Нерабочая (с ошибкой)
echo "<!DOCTYPE html>
<html>
<head>
    <title>WordPress v3 - Broken</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .error { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h1>WordPress v3 - Broken Version</h1>
    
    <?php
    // Намеренная ошибка - несуществующая функция
    non_existent_function();
    ?>
    
    <p class='error'>This version contains intentional errors for testing rollback functionality.</p>
</body>
</html>";
?>
V3

# Основной index.php который будет менять версии
cat > wordpress/src/index.php << 'MAIN'
<?php
// Определяем версию из ConfigMap
$version = getenv('APP_VERSION') ?: 'v1';

// Загружаем соответствующую версию
if ($version === 'v2') {
    include 'index-v2.php';
} elseif ($version === 'v3') {
    include 'index-v3.php';
} else {
    include 'index-v1.php';
}
?>
MAIN

# Kustomization файл
cat > wordpress/kustomization.yaml << 'KUSTOMIZE'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- templates/deployment.yaml
- templates/service.yaml
- templates/ingress.yaml
- templates/configmap.yaml
- templates/mysql.yaml
- templates/secret.yaml

configMapGenerator:
- name: wordpress-config
  behavior: merge
  literals:
  - app-version=v1
KUSTOMIZE

# Make файл для управления версиями
cat > Makefile << 'MAKEFILE'
.PHONY: deploy-v1 deploy-v2 deploy-v3 rollback

deploy-v1:
@echo "Deploying version v1..."
kubectl patch configmap wordpress-config -p '{"data":{"app-version":"v1"}}'
@echo "Version v1 deployed"

deploy-v2:
@echo "Deploying version v2..."
kubectl patch configmap wordpress-config -p '{"data":{"app-version":"v2"}}'
@echo "Version v2 deployed"

deploy-v3:
@echo "Deploying version v3 (broken)..."
kubectl patch configmap wordpress-config -p '{"data":{"app-version":"v3"}}'
@echo "Version v3 deployed"

rollback:
@echo "Rolling back to previous version..."
kubectl patch configmap wordpress-config -p '{"data":{"app-version":"v1"}}'
@echo "Rollback completed"

status:
@echo "Current version: $$(kubectl get configmap wordpress-config -o jsonpath='{.data.app-version}')"

test-webhook:
python3 discord/webhook.py test
MAKEFILE

# Даем права на выполнение
chmod +x discord/webhook.py
chmod +x setup-ci-cd.sh

echo "✅ Setup completed!"
echo "📁 Project structure created with:"
echo "   - WordPress Kubernetes manifests"
echo "   - ArgoCD application configuration"
echo "   - Discord webhook integration"
echo "   - GitHub Actions workflow"
echo "   - 3 versions of WordPress (v1, v2, v3)"
echo ""
echo "🚀 Next steps:"
echo "   1. Commit and push to GitHub:"
echo "      git add . && git commit -m 'Setup CI/CD pipeline' && git push"
echo "   2. Create secret in Kubernetes:"
echo "      kubectl apply -f wordpress/templates/secret.yaml"
echo "   3. Apply initial deployment:"
echo "      kubectl apply -f wordpress/templates/"
echo "   4. Set up ArgoCD application:"
echo "      kubectl apply -f argocd/application.yaml"
echo ""
echo "📋 To switch versions:"
echo "   make deploy-v1    # Базовая версия"
echo "   make deploy-v2    # Улучшенная версия"
echo "   make deploy-v3    # Нерабочая версия (тест rollback)"
echo "   make rollback     # Откат на предыдущую версию"
