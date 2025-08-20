#!/bin/bash

# BWS Stack - Ollama Models Downloader
# This script downloads and sets up Ollama models for the BWS Stack

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

# Function to check if Ollama is running
check_ollama() {
    if command_exists curl; then
        if curl -s --max-time 5 "http://localhost:11434/api/tags" >/dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Function to check if model exists
model_exists() {
    local model=$1
    if curl -s "http://localhost:11434/api/tags" | grep -q "\"name\":\"$model\""; then
        return 0
    else
        return 1
    fi
}

# Function to pull model
pull_model() {
    local model=$1
    local description=$2
    
    print_status "Checking if $model is already installed..."
    
    if model_exists "$model"; then
        print_success "$model is already installed"
        return 0
    fi
    
    print_status "Pulling $model ($description)..."
    
    if curl -X POST "http://localhost:11434/api/pull" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$model\"}" >/dev/null 2>&1; then
        print_success "$model downloaded successfully"
        return 0
    else
        print_error "Failed to download $model"
        return 1
    fi
}

print_status "Starting Ollama models setup..."

# Check if Ollama is running
print_status "Checking Ollama service..."

if ! check_ollama; then
    print_error "Ollama is not running or not accessible at http://localhost:11434"
    print_status "Please start the BWS Stack first with 'make start'"
    exit 1
fi

print_success "Ollama is running and accessible"

# Define models to download
MODELS=(
    "llama2:7b:General purpose model, good balance of performance and resource usage"
    "llama2:13b:Higher quality model, requires more resources"
    "codellama:7b:Specialized for code generation and analysis"
    "mistral:7b:Fast and efficient model for general tasks"
    "neural-chat:7b:Optimized for conversational AI"
)

# Download models
print_status "Downloading Ollama models..."

FAILED_MODELS=()

for model_info in "${MODELS[@]}"; do
    IFS=':' read -r model description <<< "$model_info"
    
    if pull_model "$model" "$description"; then
        print_success "✓ $model"
    else
        FAILED_MODELS+=("$model")
        print_error "✗ $model"
    fi
done

# Report results
if [ ${#FAILED_MODELS[@]} -eq 0 ]; then
    print_success "All models downloaded successfully!"
else
    print_warning "Some models failed to download:"
    for model in "${FAILED_MODELS[@]}"; do
        echo "  - $model"
    done
    print_status "You can retry downloading failed models manually:"
    print_status "curl -X POST http://localhost:11434/api/pull -d '{\"name\":\"MODEL_NAME\"}'"
fi

# Show available models
print_status "Available models:"
if command_exists curl; then
    curl -s "http://localhost:11434/api/tags" | grep -o '"name":"[^"]*"' | sed 's/"name":"//g' | sed 's/"//g' | sort
fi

print_status "Models setup completed!"
print_status "You can now use these models with the BWS Stack AI features"
