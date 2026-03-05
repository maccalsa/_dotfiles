#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
  echo -e "${BLUE}📦 $1${NC}"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

print_info() {
  echo -e "${YELLOW}ℹ️  $1${NC}" >&2
}

# Version comparison function
version_compare() {
  local v1 v2 IFS=.
  v1=(${1#v})
  v2=(${2#v})
  for ((i=0; i<${#v1[@]}||i<${#v2[@]};i++)); do
    [[ ${v1[i]:-0} -gt ${v2[i]:-0} ]] && return 0
    [[ ${v1[i]:-0} -lt ${v2[i]:-0} ]] && return 1
  done
  return 0
}

# Check if command exists
check() {
  command -v "$1" >/dev/null 2>&1 || abort "$1 is required but not installed."
}

# Abort function
abort() {
  print_error "$1"
  exit 1
}

# Check Node.js version (>= 20)
check_node_version() {
  print_step "Checking Node.js version"
  
  if ! command -v node >/dev/null 2>&1; then
    abort "Node.js is not installed. Please install Node.js 20 or higher."
  fi
  
  local node_version=$(node --version)
  print_info "Found Node.js version: $node_version"
  
  if ! version_compare "$node_version" "v20.0.0"; then
    abort "Node.js version 20 or higher is required. Current version: $node_version"
  fi
  
  print_success "Node.js version check passed"
}

# Check pnpm version (>= 10) or fallback to npm
check_package_manager() {
  print_step "Checking package manager"
  
  if command -v pnpm >/dev/null 2>&1; then
    local pnpm_version=$(pnpm --version)
    print_info "Found pnpm version: $pnpm_version"
    
    if version_compare "$pnpm_version" "10.0.0"; then
      PACKAGE_MANAGER="pnpm"
      print_success "Using pnpm (version $pnpm_version)"
    else
      print_info "pnpm version is below 10, falling back to npm"
      PACKAGE_MANAGER="npm"
    fi
  else
    print_info "pnpm not found, using npm"
    PACKAGE_MANAGER="npm"
  fi
  
  # Verify npm is available as fallback
  if [ "$PACKAGE_MANAGER" = "npm" ]; then
    if ! command -v npm >/dev/null 2>&1; then
      abort "npm is not installed. Please install Node.js which includes npm."
    fi
    local npm_version=$(npm --version)
    print_success "Using npm (version $npm_version)"
  fi
}

# Get user input for project name
get_project_name() {
  read -rp "Enter project name: " project_name
  echo "$project_name"
}

# Get project configuration options
get_project_config() {
  local config=()
  
  # TypeScript (default: yes)
  read -rp "Use TypeScript? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && config+=("--ts") || config+=("--js")
  
  # Tailwind CSS (default: yes)
  read -rp "Use Tailwind CSS? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && config+=("--tailwind") || config+=("--no-tailwind")
  
  # ESLint (default: yes)
  read -rp "Use ESLint? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && config+=("--eslint") || config+=("--no-eslint")
  
  # src/ directory (default: yes)
  read -rp "Use src/ directory? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && config+=("--src-dir") || config+=("--no-src-dir")
  
  # Import alias (default: @/*)
  read -rp "Import alias (default: @/*): " alias
  if [ -n "$alias" ]; then
    config+=("--import-alias" "$alias")
  else
    config+=("--import-alias" "@/*")
  fi
  
  echo "${config[@]}"
}

# Get additional features
get_additional_features() {
  local features=()
  
  # Authentication
  read -rp "Include authentication? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && features+=("auth")
  
  # Database
  read -rp "Include database setup? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && features+=("database")
  
  # UI Components
  read -rp "Include UI component library? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && features+=("ui")
  
  # Testing
  read -rp "Include testing setup? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && features+=("testing")
  
  # API Documentation
  read -rp "Include API documentation? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && features+=("api-docs")
  
  echo "${features[@]}"
}

# Create Next.js project
create_nextjs_project() {
  local project_name="$1"
  local config_options="$2"
  
  print_step "Creating Next.js project: $project_name"
  
  if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
    pnpm create next-app@latest "$project_name" \
      --app --yes $config_options
  else
    npx create-next-app@latest "$project_name" \
      --app --yes $config_options
  fi
  
  if [ ! -d "$project_name" ]; then
    print_error "Failed to create project. Please check your inputs and try again."
    exit 1
  fi
  
  cd "$project_name" || exit
  print_success "Project created successfully!"
}

# Install dependencies
install_dependencies() {
  print_step "Installing dependencies"
  
  if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
    pnpm install
  else
    npm install
  fi
  
  print_success "Dependencies installed"
}

# Print summary
print_summary() {
  local project_name="$1"
  local features="$2"
  
  echo ""
  echo "🎉 Next.js project '$project_name' created successfully!"
  echo ""
  echo "📋 What was installed:"
  echo "   🚀 Next.js with App Router"
  echo "   📦 Package Manager: $PACKAGE_MANAGER"
  
  if [ -n "$features" ]; then
    echo "   🔧 Additional features:"
    for feature in $features; do
      case $feature in
        auth) echo "     - Authentication setup";;
        database) echo "     - Database configuration";;
        ui) echo "     - UI component library";;
        testing) echo "     - Testing setup";;
        api-docs) echo "     - API documentation";;
      esac
    done
  fi
  
  echo ""
  echo "🚀 Next steps:"
  echo "   1. cd $project_name"
  echo "   2. ${PACKAGE_MANAGER} dev"
  echo "   3. Visit http://localhost:3000"
  echo ""
  echo "📖 See README.md for detailed setup instructions."
} 