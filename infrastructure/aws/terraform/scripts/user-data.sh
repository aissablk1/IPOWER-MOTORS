#!/bin/bash
# User Data Script pour IPOWER MOTORS Backend
# ===========================================

set -e

# Variables
APP_NAME="ipower-backend"
APP_USER="ipower"
APP_DIR="/opt/ipower-backend"
LOG_DIR="/var/log/ipower-backend"
SERVICE_FILE="/etc/systemd/system/ipower-backend.service"

# Mise à jour du système
echo "🔄 Mise à jour du système..."
apt-get update
apt-get upgrade -y

# Installation des dépendances
echo "📦 Installation des dépendances..."
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Installation de Node.js 18.x
echo "🟢 Installation de Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Installation de PM2
echo "⚡ Installation de PM2..."
npm install -g pm2

# Installation de Docker
echo "🐳 Installation de Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Création de l'utilisateur applicatif
echo "👤 Création de l'utilisateur applicatif..."
useradd -m -s /bin/bash $APP_USER || true
usermod -aG docker $APP_USER

# Création des répertoires
echo "📁 Création des répertoires..."
mkdir -p $APP_DIR
mkdir -p $LOG_DIR
chown -R $APP_USER:$APP_USER $APP_DIR
chown -R $APP_USER:$APP_USER $LOG_DIR

# Configuration de l'environnement
echo "⚙️ Configuration de l'environnement..."
cat > $APP_DIR/.env << EOF
NODE_ENV=production
PORT=3001
HOST=0.0.0.0

# Base de données (sera configurée par Terraform)
DB_HOST=\${DB_HOST}
DB_PORT=5432
DB_NAME=\${DB_NAME}
DB_USER=\${DB_USER}
DB_PASSWORD=\${DB_PASSWORD}
DB_SSL=true

# S3 (via IAM Role)
S3_BUCKET_FRONTEND=\${S3_BUCKET_FRONTEND}
S3_BUCKET_DOCUMENTS=\${S3_BUCKET_DOCUMENTS}
S3_BUCKET_BACKUPS=\${S3_BUCKET_BACKUPS}
S3_REGION=eu-west-3

# JWT
JWT_SECRET=\${JWT_SECRET}
JWT_EXPIRES_IN=24h

# CORS
CORS_ORIGIN=https://ipowerfrance.fr,https://www.ipowerfrance.fr

# Logging
LOG_LEVEL=info
LOG_FILE=$LOG_DIR/app.log

# Monitoring
ENABLE_METRICS=true
HEALTH_CHECK_INTERVAL=30000
EOF

# Service systemd
echo "🔧 Configuration du service systemd..."
cat > $SERVICE_FILE << EOF
[Unit]
Description=IPOWER MOTORS Backend
After=network.target

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
Environment=PORT=3001
ExecStart=/usr/bin/node dist/server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$APP_NAME

[Install]
WantedBy=multi-user.target
EOF

# Activation du service
systemctl daemon-reload
systemctl enable ipower-backend

# Configuration du firewall
echo "🔥 Configuration du firewall..."
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3001/tcp

# Configuration de la surveillance
echo "📊 Configuration de la surveillance..."
cat > /etc/cron.daily/ipower-health-check << EOF
#!/bin/bash
# Vérification de santé quotidienne
curl -f http://localhost:3001/health || systemctl restart ipower-backend
EOF

chmod +x /etc/cron.daily/ipower-health-check

# Installation de CloudWatch Agent
echo "☁️ Installation de CloudWatch Agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Configuration CloudWatch
cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json << EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "$LOG_DIR/app.log",
            "log_group_name": "/aws/ec2/ipower-backend",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "IPOWER-MOTORS/EC2",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "diskio": {
        "measurement": ["io_time"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": ["tcp_established", "tcp_time_wait"],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": ["swap_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Démarrage de CloudWatch Agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Configuration des logs
echo "📝 Configuration des logs..."
cat > /etc/logrotate.d/ipower-backend << EOF
$LOG_DIR/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 $APP_USER $APP_USER
    postrotate
        systemctl reload ipower-backend
    endscript
}
EOF

# Installation de l'application (sera fait par le déploiement)
echo "🚀 Préparation de l'application..."
cd $APP_DIR
git clone https://github.com/ipower-motors/ipower-backend.git . || true

# Installation des dépendances
if [ -f "package.json" ]; then
    echo "📦 Installation des dépendances Node.js..."
    npm install --production
    npm run build
fi

# Démarrage du service
echo "▶️ Démarrage du service..."
systemctl start ipower-backend

# Vérification du statut
echo "✅ Vérification du statut..."
systemctl status ipower-backend --no-pager

# Configuration finale
echo "🎯 Configuration finale..."
echo "Application installée dans: $APP_DIR"
echo "Logs dans: $LOG_DIR"
echo "Service: ipower-backend"
echo "Port: 3001"
echo "Utilisateur: $APP_USER"

# Nettoyage
echo "🧹 Nettoyage..."
rm -f /tmp/*.deb
rm -f /tmp/*.tar.gz

echo "🎉 Configuration terminée avec succès !"
echo "Votre application IPOWER MOTORS est prête !"
