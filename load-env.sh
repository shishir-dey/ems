#!/bin/bash

# Enterprise Management Suite (EMS) - Environment Loader (Unix/macOS)
# This script loads environment variables from config.env for local development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_FILE="$SCRIPT_DIR/config.env"

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate environment variables
validate_env_vars() {
    local missing_vars=()
    local required_vars=(
        "DATABASE_URL"
        "SUPABASE_URL"
        "SUPABASE_ANON_KEY"
        "JWT_SECRET"
    )
    
    for var in "${required_vars[@]}"; do
        local value="${!var}"
        if [[ -z "$value" ]] || [[ "$value" == *"your-"* ]] || [[ "$value" == *"example"* ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        print_error "Missing or unconfigured environment variables:"
        for var in "${missing_vars[@]}"; do
            print_error "  - $var"
        done
        print_error "Please configure these variables in config.env"
        return 1
    fi
    
    return 0
}

# Function to load environment variables from config.env
load_environment() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        
        if [[ -f "$SCRIPT_DIR/config.env.example" ]]; then
            print_warning "Found config.env.example. Creating config.env..."
            cp "$SCRIPT_DIR/config.env.example" "$CONFIG_FILE"
            print_success "Config file created from template"
            print_warning "Please edit config.env with your actual configuration values"
            return 1
        else
            print_error "config.env.example not found either"
            return 1
        fi
    fi
    
    print_header "Loading Environment Configuration"
    
    # Load variables from config.env
    local loaded_count=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Check if line contains an assignment
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$ ]]; then
            local var_name="${BASH_REMATCH[1]}"
            local var_value="${BASH_REMATCH[2]}"
            
            # Remove quotes if present
            var_value="${var_value%\"}"
            var_value="${var_value#\"}"
            var_value="${var_value%\'}"
            var_value="${var_value#\'}"
            
            # Export the variable
            export "$var_name"="$var_value"
            ((loaded_count++))
        fi
    done < "$CONFIG_FILE"
    
    print_success "Loaded $loaded_count environment variables from config.env"
    
    # Validate critical environment variables
    if validate_env_vars; then
        print_success "All required environment variables are configured"
        return 0
    else
        return 1
    fi
}

# Function to show environment status
show_env_status() {
    print_header "Environment Status"
    
    # Check Node.js
    if command_exists node; then
        local node_version=$(node --version)
        print_success "Node.js: $node_version"
    else
        print_warning "Node.js not found"
    fi
    
    # Check npm
    if command_exists npm; then
        local npm_version=$(npm --version)
        print_success "npm: $npm_version"
    else
        print_warning "npm not found"
    fi
    
    # Check Rust
    if command_exists rustc; then
        local rust_version=$(rustc --version)
        print_success "Rust: $rust_version"
    else
        print_warning "Rust not found"
    fi
    
    # Check Cargo
    if command_exists cargo; then
        local cargo_version=$(cargo --version)
        print_success "Cargo: $cargo_version"
    else
        print_warning "Cargo not found"
    fi
    
    # Check Docker (optional)
    if command_exists docker; then
        local docker_version=$(docker --version)
        print_success "Docker: $docker_version"
    fi
    
    # Show key environment variables (without revealing sensitive values)
    echo ""
    print_header "Key Environment Variables"
    
    local env_vars=(
        "ENVIRONMENT"
        "FRONTEND_PORT"
        "BACKEND_PORT"
        "DATABASE_URL"
        "SUPABASE_URL"
        "VITE_API_BASE_URL"
    )
    
    for var in "${env_vars[@]}"; do
        local value="${!var}"
        if [[ -n "$value" ]]; then
            # Mask sensitive URLs and keys
            if [[ "$var" == "DATABASE_URL" ]] || [[ "$var" == "SUPABASE_URL" ]]; then
                local masked_value=$(echo "$value" | sed 's/:[^@]*@/:***@/g' | sed 's/\/\/[^@]*@/\/\/***@/g')
                echo "  $var: $masked_value"
            else
                echo "  $var: $value"
            fi
        else
            echo "  $var: (not set)"
        fi
    done
}

# Function to export environment for child processes
export_environment() {
    # Export common development variables
    export RUST_LOG="${RUST_LOG:-info}"
    export RUST_BACKTRACE="${RUST_BACKTRACE:-1}"
    
    # Export paths
    export PROJECT_ROOT="$SCRIPT_DIR"
    export CLIENT_DIR="$SCRIPT_DIR/src/client"
    export SERVER_DIR="$SCRIPT_DIR/src/server"
    
    print_success "Environment exported for child processes"
}

# Main function
main() {
    local command="${1:-status}"
    
    case "$command" in
        "load")
            if load_environment; then
                export_environment
                print_success "Environment loaded successfully!"
                print_warning "Run 'source load-env.sh' or '. load-env.sh' to export variables to your current shell"
            else
                print_error "Failed to load environment"
                exit 1
            fi
            ;;
        "status")
            if load_environment; then
                show_env_status
            else
                print_error "Failed to load environment for status check"
                exit 1
            fi
            ;;
        "validate")
            if load_environment; then
                print_success "Environment validation passed!"
            else
                print_error "Environment validation failed!"
                exit 1
            fi
            ;;
        "help"|"-h"|"--help")
            print_header "EMS Environment Loader (Unix/macOS)"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  load      Load environment variables from config.env"
            echo "  status    Show environment and tool status"
            echo "  validate  Validate environment configuration"
            echo "  help      Show this help message"
            echo ""
            echo "To load environment variables into your current shell:"
            echo "  source $0 load"
            echo "  . $0 load"
            echo ""
            echo "Examples:"
            echo "  $0 status                    # Show environment status"
            echo "  source $0 load              # Load env vars into current shell"
            echo "  $0 validate                 # Validate configuration"
            ;;
        *)
            print_error "Unknown command: $command"
            print_warning "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run the main function with all arguments
main "$@" 