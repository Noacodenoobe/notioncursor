#!/bin/bash

# BWS Stack Installer
# This script sets up the entire BWS Stack environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check port availability
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is available
    fi
}

print_status "Starting BWS Stack installation..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Check prerequisites
print_status "Checking prerequisites..."

# Check Docker
if ! command_exists docker; then
    print_error "Docker is not installed. Please install Docker first."
    print_status "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check Docker Compose (classic or plugin)
if command_exists docker-compose; then
    print_success "Docker Compose (v1) is installed"
elif docker compose version >/dev/null 2>&1; then
    print_success "Docker Compose (plugin) is available"
else
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    print_status "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker daemon is not running. Please start Docker first."
    exit 1
fi

print_success "Docker and Docker Compose are available"

# Check required ports
print_status "Checking port availability..."

REQUIRED_PORTS=(5432 6379 5678 11434 6333 6334)
UNAVAILABLE_PORTS=()

for port in "${REQUIRED_PORTS[@]}"; do
    if check_port $port; then
        UNAVAILABLE_PORTS+=($port)
        print_warning "Port $port is already in use"
    fi
done

if [ ${#UNAVAILABLE_PORTS[@]} -gt 0 ]; then
    print_error "The following ports are already in use: ${UNAVAILABLE_PORTS[*]}"
    print_status "Please stop the services using these ports or modify docker-compose.yml"
    exit 1
fi

print_success "All required ports are available"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    print_status "Creating .env file from template..."
    if [ -f env.example ]; then
        cp env.example .env
        print_warning "Please edit .env file with your configuration before starting services"
    else
        print_error "env.example file not found"
        exit 1
    fi
else
    print_status ".env file already exists"
fi

# Make scripts executable
print_status "Setting up scripts..."
chmod +x scripts/*.sh || true

# Pull Docker images
print_status "Pulling Docker images..."
if [ -x scripts/compose.sh ]; then
    scripts/compose.sh pull
else
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose pull
    else
        docker compose pull
    fi
fi

# Create necessary directories
print_status "Creating directories..."
mkdir -p data/postgres
mkdir -p data/n8n
mkdir -p data/ollama
mkdir -p data/qdrant

# Set proper permissions
print_status "Setting permissions..."
chmod 755 data/

print_success "Installation completed successfully!"

print_status "Next steps:"
echo "1. Edit .env file with your configuration"
echo "2. Run 'make start' to start all services"
echo "3. Run 'make health-check' to verify everything is working"
echo "4. Access n8n at http://localhost:5678"
echo "5. Access Ollama API at http://localhost:11434"
echo "6. Access AI Bridge at http://localhost:8000/health"

print_status "For more information, see README.md"