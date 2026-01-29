#!/bin/bash

set -e

echo "🚀 Starting deployment..."

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ] && ! command -v docker &> /dev/null; then
    echo "⚠️  Please run as root or ensure docker is available"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# App directory
APP_DIR="~/wg-easy"

echo -e "${YELLOW}📁 Setting up directory...${NC}"
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# Check if git repo exists
if [ -d ".git" ]; then
    echo -e "${YELLOW}📥 Pulling latest changes...${NC}"
    git pull origin main
else
    echo -e "${YELLOW}📥 Cloning repository...${NC}"
    # Note: Replace with your actual repository URL in production
    if [ -n "$GITHUB_REPOSITORY" ]; then
        git clone "https://github.com/$GITHUB_REPOSITORY" .
    else
        echo "⚠️  GITHUB_REPOSITORY not set, skipping clone"
    fi
fi

# Ensure .env file exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚙️  Creating .env file...${NC}"
    if [ -n "$WG_PASSWORD" ]; then
        cat > .env << EOF
WG_PASSWORD=$WG_PASSWORD
DOCKER_IMAGE=${DOCKER_IMAGE:-oriontrader/wg-easy:latest}
EOF
    else
        echo "⚠️  WG_PASSWORD not set, copying from .env.example"
        cp .env.example .env
    fi
fi

# Pull latest Docker images
echo -e "${YELLOW}🐳 Pulling Docker images...${NC}"
sudo docker-compose pull

# Stop existing containers
echo -e "${YELLOW}🛑 Stopping existing containers...${NC}"
sudo docker-compose down || true

# Start containers
echo -e "${YELLOW}🔄 Starting containers...${NC}"
sudo docker-compose up -d

# Wait for containers to be healthy
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 5

# Show status
echo -e "${YELLOW}📊 Container status:${NC}"
sudo docker-compose ps

# Show logs
echo -e "${YELLOW}📝 Recent logs:${NC}"
sudo docker-compose logs --tail=20

# Clean up old images
echo -e "${YELLOW}🧹 Cleaning up old images...${NC}"
sudo docker image prune -f || true

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${GREEN}🌐 WireGuard VPN is running on port 51820${NC}"
echo -e "${GREEN}🖥️  Admin UI available at http://127.0.0.1:51821${NC}"
