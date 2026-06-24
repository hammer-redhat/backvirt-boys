#!/bin/bash

# GitHub OAuth Token Setup Helper Script
# This script helps users set up GitHub OAuth tokens securely for the Ansible playbook

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
VAULT_FILE="github-secrets.yml"
VARS_FILE="github-oauth-vars.yml"

echo -e "${BLUE}🔑 GitHub OAuth Token Setup Helper${NC}"
echo -e "${BLUE}=====================================${NC}"
echo

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help        Show this help message"
    echo "  -v, --vault       Create Ansible vault file (most secure)"
    echo "  -e, --env         Set up environment variable"
    echo "  -c, --check       Check existing token validity"
    echo "  -s, --scopes      Show required OAuth scopes"
    echo
    echo "Examples:"
    echo "  $0 -v             Create encrypted vault file"
    echo "  $0 -e             Set up environment variable"
    echo "  $0 -c             Check token validity"
    echo "  $0 -s             Show required scopes"
}

# Function to show required OAuth scopes
show_scopes() {
    echo -e "${YELLOW}📋 Required OAuth Scopes${NC}"
    echo -e "${YELLOW}========================${NC}"
    echo
    echo "For PUBLIC repositories:"
    echo "  ✅ public_repo - Access to public repositories"
    echo
    echo "For PRIVATE repositories:"
    echo "  ✅ repo - Full control of private repositories"
    echo
    echo "Optional but recommended:"
    echo "  ✅ user - Read user profile data"
    echo "  ✅ user:email - Read user email addresses"
    echo "  ✅ delete_repo - Delete repositories"
    echo
    echo -e "${BLUE}💡 Generate your token at: https://github.com/settings/tokens${NC}"
}

# Function to check token validity
check_token() {
    if [[ -z "$GITHUB_TOKEN" ]]; then
        echo -e "${RED}❌ GITHUB_TOKEN environment variable not set${NC}"
        echo "Please set your token first:"
        echo "  export GITHUB_TOKEN=\"your_token_here\""
        return 1
    fi
    
    echo -e "${BLUE}🔍 Checking token validity...${NC}"
    
    response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                   -H "Accept: application/vnd.github.v3+json" \
                   https://api.github.com/user)
    
    if echo "$response" | grep -q "login"; then
        username=$(echo "$response" | grep -o '"login":"[^"]*' | cut -d'"' -f4)
        echo -e "${GREEN}✅ Token is valid!${NC}"
        echo "   Username: $username"
        
        # Check scopes
        scopes=$(curl -s -I -H "Authorization: token $GITHUB_TOKEN" \
                     https://api.github.com/user | grep -i "x-oauth-scopes" | cut -d' ' -f2-)
        echo "   Scopes: $scopes"
        
        # Test repository access
        echo -e "${BLUE}🔍 Testing repository access...${NC}"
        repo_response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                           -H "Accept: application/vnd.github.v3+json" \
                           https://api.github.com/user/repos?per_page=1)
        
        if echo "$repo_response" | grep -q "name"; then
            echo -e "${GREEN}✅ Repository access confirmed${NC}"
        else
            echo -e "${YELLOW}⚠️  Repository access may be limited${NC}"
        fi
    else
        echo -e "${RED}❌ Token is invalid or expired${NC}"
        echo "Response: $response"
        return 1
    fi
}

# Function to set up environment variable
setup_env() {
    echo -e "${BLUE}🌍 Setting up environment variable${NC}"
    echo -e "${BLUE}==================================${NC}"
    echo
    
    echo "Enter your GitHub Personal Access Token:"
    read -s token
    echo
    
    if [[ -z "$token" ]]; then
        echo -e "${RED}❌ Token cannot be empty${NC}"
        return 1
    fi
    
    # Validate token
    echo -e "${BLUE}🔍 Validating token...${NC}"
    response=$(curl -s -H "Authorization: token $token" \
                   -H "Accept: application/vnd.github.v3+json" \
                   https://api.github.com/user)
    
    if echo "$response" | grep -q "login"; then
        echo -e "${GREEN}✅ Token is valid!${NC}"
        echo
        echo "Add this to your shell profile (.bashrc, .zshrc, etc.):"
        echo -e "${YELLOW}export GITHUB_TOKEN=\"$token\"${NC}"
        echo
        echo "Or run this command for current session:"
        echo -e "${YELLOW}export GITHUB_TOKEN=\"$token\"${NC}"
        echo
        echo "Then run the playbook with:"
        echo -e "${BLUE}ansible-playbook create-github-repo-oauth.yml -e @github-oauth-vars.yml -e \"github_token=\${GITHUB_TOKEN}\"${NC}"
    else
        echo -e "${RED}❌ Token is invalid${NC}"
        return 1
    fi
}

# Function to create Ansible vault
setup_vault() {
    echo -e "${BLUE}🔒 Setting up Ansible Vault${NC}"
    echo -e "${BLUE}===========================${NC}"
    echo
    
    if [[ -f "$VAULT_FILE" ]]; then
        echo -e "${YELLOW}⚠️  Vault file $VAULT_FILE already exists${NC}"
        echo "Do you want to overwrite it? (y/N)"
        read -r overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            return 1
        fi
    fi
    
    echo "Enter your GitHub Personal Access Token:"
    read -s token
    echo
    
    if [[ -z "$token" ]]; then
        echo -e "${RED}❌ Token cannot be empty${NC}"
        return 1
    fi
    
    # Validate token
    echo -e "${BLUE}🔍 Validating token...${NC}"
    response=$(curl -s -H "Authorization: token $token" \
                   -H "Accept: application/vnd.github.v3+json" \
                   https://api.github.com/user)
    
    if echo "$response" | grep -q "login"; then
        echo -e "${GREEN}✅ Token is valid!${NC}"
        echo
        
        # Create vault file
        echo "github_token: \"$token\"" | ansible-vault encrypt --output "$VAULT_FILE"
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✅ Vault file created: $VAULT_FILE${NC}"
            echo
            echo "Run the playbook with:"
            echo -e "${BLUE}ansible-playbook create-github-repo-oauth.yml -e @github-oauth-vars.yml -e @$VAULT_FILE --ask-vault-pass${NC}"
        else
            echo -e "${RED}❌ Failed to create vault file${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Token is invalid${NC}"
        return 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check if ansible-vault is available
    if ! command -v ansible-vault &> /dev/null; then
        echo -e "${RED}❌ ansible-vault not found. Please install Ansible.${NC}"
        return 1
    fi
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}❌ curl not found. Please install curl.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites met${NC}"
    return 0
}

# Main script logic
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            ;;
        -v|--vault)
            check_prerequisites && setup_vault
            ;;
        -e|--env)
            check_prerequisites && setup_env
            ;;
        -c|--check)
            check_prerequisites && check_token
            ;;
        -s|--scopes)
            show_scopes
            ;;
        "")
            echo "No option specified. Use -h for help."
            echo
            echo "Quick setup options:"
            echo "  $0 -v    Create secure vault file"
            echo "  $0 -e    Set up environment variable"
            echo "  $0 -s    Show required OAuth scopes"
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h for help."
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 