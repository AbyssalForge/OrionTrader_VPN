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
RED='\033[0;31m'
NC='\033[0m' # No Color

# App directory
APP_DIR="$HOME/wg-easy"

echo -e "${YELLOW}📁 Setting up directory...${NC}"

# Check if it's a valid git repository
if [ -d "$APP_DIR/.git" ]; then
    echo -e "${YELLOW}📥 Updating existing repository...${NC}"
    cd "$APP_DIR"
    git fetch origin
    git reset --hard origin/main
    git clean -fd
else
    echo -e "${YELLOW}📥 Setting up fresh repository...${NC}"
    # Remove directory if it exists but is not a git repo
    if [ -d "$APP_DIR" ]; then
        echo -e "${YELLOW}🗑️  Removing existing non-git directory...${NC}"
        sudo rm -rf "$APP_DIR"
    fi
    # Clone repository
    if [ -n "$GITHUB_REPOSITORY" ]; then
        git clone "https://github.com/$GITHUB_REPOSITORY" "$APP_DIR"
    else
        echo "⚠️  GITHUB_REPOSITORY not set, please clone manually"
        exit 1
    fi
    cd "$APP_DIR"
fi

# Verify docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ ERROR: docker-compose.yml not found!${NC}"
    ls -la
    exit 1
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
