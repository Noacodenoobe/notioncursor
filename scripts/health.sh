#!/bin/bash

# BWS Stack - Service Health Check
# This script checks the health of all BWS Stack services

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

# Function to check service health
check_service() {
    local service=$1
    local url=$2
    local endpoint=$3
    local description=$4
    
    print_status "Checking $service ($description)..."
    
    if command_exists curl; then
        local full_url="${url}${endpoint}"
        
        if curl -s --max-time 10 "$full_url" >/dev/null 2>&1; then
            print_success "$service is healthy ✓"
            return 0
        else
            print_error "$service is not responding ✗"
            return 1
        fi
    else
        print_warning "Cannot check $service - curl not available"
        return 1
    fi
}

# Function to check Docker container
check_container() {
    local container=$1
    local description=$2
    
    print_status "Checking $container ($description)..."
    
    if command_exists docker; then
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container.*Up"; then
            print_success "$container is running ✓"
            return 0
        else
            print_error "$container is not running ✗"
            return 1
        fi
    else
        print_warning "Cannot check $container - docker not available"
        return 1
    fi
}

# Function to check database connection
check_database() {
    local db_type=$1
    local host=$2
    local port=$3
    local description=$4
    
    print_status "Checking $db_type ($description)..."
    
    if command_exists nc; then
        if nc -z "$host" "$port" 2>/dev/null; then
            print_success "$db_type is accessible ✓"
            return 0
        else
            print_error "$db_type is not accessible ✗"
            return 1
        fi
    elif command_exists telnet; then
        if timeout 5 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
            print_success "$db_type is accessible ✓"
            return 0
        else
            print_error "$db_type is not accessible ✗"
            return 1
        fi
    else
        print_warning "Cannot check $db_type - no suitable tool available"
        return 1
    fi
}

print_status "Starting BWS Stack health check..."

# Initialize counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Check Docker containers
print_status "=== Container Health ==="

check_container "bws-postgres" "PostgreSQL Database" && ((PASSED_CHECKS++)) || ((FAILED_CHECKS++))
((TOTAL_CHECKS++))

check_container "bws-redis" "Redis Cache" && ((PASSED_CHECKS++)) || ((FAILED_CHECKS++))
((TOTAL_CHECKS++))

check_container "bws-n8n" "n8n Workflow Engine" && ((PASSED_CHECKS++)) || ((FAILED_CHECKS++))
((TOTAL_CHECKS++))

check_container "bws-ollama" "Ollama LLM Service" && ((PASSED_CHECKS++)) || ((FAILED_CHECKS++))
((TOTAL_CHECKS++))

check_container "bws-qdrant" "Qdrant Vector Database" && ((PASSED_CHECKS++)) || ((FAILED_CHECKS++))
((TOTAL_CHECKS++))

# Check service endpoints
print_status "=== Service Health ==="

check_service "n8n" "http://localhost:5678" "" "Workflow Automation Platform" && ((PASSED_CHECKS++)) || ((FAILED_CHECKS++))
((TOTAL_CHECKS++))

check_service "Ollama" "http://localhost:11434" "/api/tags" "LLM API" && ((PASSED_CHECKS++)) || ((FAILED_CHECKS++))
((TOTAL_CHECKS++))

check_service "Qdrant" "http://localhost:6333" "/health" "Vector Database API" && ((PASSED_CHECKS++)) || ((FAILED_CHECKS++))
((TOTAL_CHECKS++))

# Check database connections
print_status "=== Database Connectivity ==="

check_database "PostgreSQL" "localhost" "5432" "Primary Database" && ((PASSED_CHECKS++)) || ((FAILED_CHECKS++))
((TOTAL_CHECKS++))

check_database "Redis" "localhost" "6379" "Cache Database" && ((PASSED_CHECKS++)) || ((FAILED_CHECKS++))
((TOTAL_CHECKS++))

# Check n8n workflows
print_status "=== n8n Workflows ==="

if command_exists curl; then
    print_status "Checking n8n workflow status..."
    
    # Try to get workflows (this might require authentication)
    if curl -s --max-time 10 "http://localhost:5678/rest/workflows" >/dev/null 2>&1; then
        print_success "n8n workflows are accessible ✓"
        ((PASSED_CHECKS++))
    else
        print_warning "n8n workflows require authentication or are not accessible"
        ((FAILED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
else
    print_warning "Cannot check n8n workflows - curl not available"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
fi

# Check Ollama models
print_status "=== Ollama Models ==="

if command_exists curl; then
    print_status "Checking available Ollama models..."
    
    MODELS_RESPONSE=$(curl -s --max-time 10 "http://localhost:11434/api/tags" 2>/dev/null || echo "")
    
    if [ -n "$MODELS_RESPONSE" ]; then
        MODEL_COUNT=$(echo "$MODELS_RESPONSE" | grep -o '"name"' | wc -l)
        if [ "$MODEL_COUNT" -gt 0 ]; then
            print_success "Ollama has $MODEL_COUNT model(s) available ✓"
            ((PASSED_CHECKS++))
        else
            print_warning "Ollama is running but no models are installed"
            ((FAILED_CHECKS++))
        fi
    else
        print_error "Cannot retrieve Ollama models"
        ((FAILED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
else
    print_warning "Cannot check Ollama models - curl not available"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
fi

# Check Qdrant collections
print_status "=== Qdrant Collections ==="

if command_exists curl; then
    print_status "Checking Qdrant collections..."
    
    COLLECTIONS_RESPONSE=$(curl -s --max-time 10 "http://localhost:6333/collections" 2>/dev/null || echo "")
    
    if [ -n "$COLLECTIONS_RESPONSE" ]; then
        print_success "Qdrant collections endpoint is accessible ✓"
        ((PASSED_CHECKS++))
    else
        print_error "Cannot access Qdrant collections"
        ((FAILED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
else
    print_warning "Cannot check Qdrant collections - curl not available"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
fi

# Summary
print_status "=== Health Check Summary ==="

echo "Total checks: $TOTAL_CHECKS"
echo "Passed: $PASSED_CHECKS"
echo "Failed: $FAILED_CHECKS"

if [ $FAILED_CHECKS -eq 0 ]; then
    print_success "All services are healthy! 🎉"
    exit 0
elif [ $PASSED_CHECKS -gt $FAILED_CHECKS ]; then
    print_warning "Most services are healthy, but some issues detected"
    exit 1
else
    print_error "Multiple services are unhealthy"
    exit 1
fi
