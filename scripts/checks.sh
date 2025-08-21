#!/bin/bash

# BWS Stack Health Checks
# This script checks dependencies and port availability

set -e

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
    local service=$2
    
    if command_exists lsof; then
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            print_warning "Port $port ($service) is in use"
            return 0
        else
            print_success "Port $port ($service) is available"
            return 1
        fi
    elif command_exists netstat; then
        if netstat -tuln | grep ":$port " >/dev/null 2>&1; then
            print_warning "Port $port ($service) is in use"
            return 0
        else
            print_success "Port $port ($service) is available"
            return 1
        fi
    else
        print_warning "Cannot check port $port - no suitable tool available"
        return 1
    fi
}

# Function to check service health
check_service_health() {
    local service=$1
    local url=$2
    
    if command_exists curl; then
        if curl -s --max-time 5 "$url" >/dev/null 2>&1; then
            print_success "$service is responding at $url"
            return 0
        else
            print_error "$service is not responding at $url"
            return 1
        fi
    else
        print_warning "Cannot check $service - curl not available"
        return 1
    fi
}

print_status "Running BWS Stack health checks..."

# Check system requirements
print_status "Checking system requirements..."

# Check Docker
if command_exists docker; then
    print_success "Docker is installed"
    if docker info >/dev/null 2>&1; then
        print_success "Docker daemon is running"
    else
        print_error "Docker daemon is not running"
    fi
else
    print_error "Docker is not installed"
fi

# Check Docker Compose
if command_exists docker-compose; then
    print_success "Docker Compose is installed"
else
    print_error "Docker Compose is not installed"
fi

# Check Make
if command_exists make; then
    print_success "Make is installed"
else
    print_warning "Make is not installed (optional)"
fi

# Check Git
if command_exists git; then
    print_success "Git is installed"
else
    print_warning "Git is not installed (optional)"
fi

# Check required ports
print_status "Checking required ports..."

REQUIRED_PORTS=(
    "5432:PostgreSQL"
    "6379:Redis"
    "5678:n8n"
    "11434:Ollama"
    "6333:Qdrant"
    "6334:Qdrant Admin"
    "8000:AI Bridge"
)

UNAVAILABLE_PORTS=()

for port_info in "${REQUIRED_PORTS[@]}"; do
    IFS=':' read -r port service <<< "$port_info"
    if check_port $port "$service"; then
        UNAVAILABLE_PORTS+=("$port ($service)")
    fi
done

if [ ${#UNAVAILABLE_PORTS[@]} -gt 0 ]; then
    print_warning "The following ports are in use:"
    for port in "${UNAVAILABLE_PORTS[@]}"; do
        echo "  - $port"
    done
    print_status "You may need to stop conflicting services or modify docker-compose.yml"
else
    print_success "All required ports are available"
fi

# Check environment file
print_status "Checking environment configuration..."

if [ -f .env ]; then
    print_success ".env file exists"
    
    # Check for required variables
    REQUIRED_VARS=(
        "POSTGRES_PASSWORD"
        "N8N_USER"
        "N8N_PASSWORD"
        "N8N_ENCRYPTION_KEY"
    )
    
    MISSING_VARS=()
    
    for var in "${REQUIRED_VARS[@]}"; do
        if ! grep -q "^${var}=" .env; then
            MISSING_VARS+=($var)
        fi
    done
    
    if [ ${#MISSING_VARS[@]} -gt 0 ]; then
        print_warning "Missing required environment variables:"
        for var in "${MISSING_VARS[@]}"; do
            echo "  - $var"
        done
    else
        print_success "All required environment variables are defined"
    fi
else
    print_error ".env file not found"
    print_status "Copy env.example to .env and configure it"
fi

# Check Docker containers if running
print_status "Checking running containers..."

if command_exists docker; then
    RUNNING_CONTAINERS=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(bws-|postgres|redis|n8n|ollama|qdrant)" || true)
    
    if [ -n "$RUNNING_CONTAINERS" ]; then
        print_success "Found running BWS containers:"
        echo "$RUNNING_CONTAINERS"
        
        # Check service health
        print_status "Checking service health..."
        
        check_service_health "n8n" "http://localhost:5678" || true
        check_service_health "Ollama" "http://localhost:11434/api/tags" || true
        check_service_health "Qdrant" "http://localhost:6333/health" || true
        check_service_health "AI Bridge" "http://localhost:8000/health" || true
    else
        print_status "No BWS containers are currently running"
        print_status "Run 'make start' to start the services"
    fi
fi

# Check disk space
print_status "Checking disk space..."

if command_exists df; then
    DISK_USAGE=$(df -h . | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 90 ]; then
        print_error "Disk usage is high: ${DISK_USAGE}%"
    elif [ "$DISK_USAGE" -gt 80 ]; then
        print_warning "Disk usage is moderate: ${DISK_USAGE}%"
    else
        print_success "Disk usage is good: ${DISK_USAGE}%"
    fi
fi

# Check memory
print_status "Checking memory..."

if command_exists free; then
    MEMORY_INFO=$(free -h | grep Mem)
    TOTAL_MEM=$(echo $MEMORY_INFO | awk '{print $2}')
    USED_MEM=$(echo $MEMORY_INFO | awk '{print $3}')
    print_status "Memory: $USED_MEM / $TOTAL_MEM used"
fi

print_status "Health checks completed!"
