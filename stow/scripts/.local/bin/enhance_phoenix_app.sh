#!/bin/bash

set -e

# Get the actual script directory (resolving symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# Source all modules
source "$SCRIPT_DIR/_common.sh"
source "$SCRIPT_DIR/_oban.sh"

# Check if we're in a Phoenix project
check_phoenix_project() {
  if [ ! -f "mix.exs" ]; then
    print_error "Not in a Phoenix project directory. Please run this script from your Phoenix project root."
    exit 1
  fi
  
  if ! grep -q "phoenix" mix.exs; then
    print_error "This doesn't appear to be a Phoenix project. Please run this script from your Phoenix project root."
    exit 1
  fi
  
  print_success "Phoenix project detected"
}

# Get project name from mix.exs
get_project_name_from_mix() {
  local project_name=$(grep -o 'def project do' mix.exs -A 10 | grep 'app:' | sed 's/.*app: :\([^,]*\).*/\1/')
  echo "$project_name"
}

# Get existing dependencies
get_existing_dependencies() {
  local existing_deps=()
  
  if grep -q ":oban" mix.exs; then
    existing_deps+=("oban")
  fi
  
  if grep -q ":bodyguard" mix.exs; then
    existing_deps+=("bodyguard")
  fi
  
  if grep -q ":req" mix.exs; then
    existing_deps+=("req")
  fi
  
  if grep -q ":waffle" mix.exs; then
    existing_deps+=("waffle")
  fi
  
  if grep -q ":open_api_spex" mix.exs; then
    existing_deps+=("open_api_spex")
  fi
  
  echo "${existing_deps[*]}"
}

# Get enhancement options
get_enhancement_options() {
  local existing_deps="$1"
  local extra_deps=()
  local auth=false
  
  # Check if auth is already set up
  if [ -d "lib" ] && find lib -name "*auth*" -type d | grep -q .; then
    print_info "Authentication appears to be already set up"
    auth=true
  else
    read -rp "Include Authentication (phx.gen.auth)? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && auth=true
  fi
  
  # Ask about each dependency
  for dep_config in "${DEPENDENCIES[@]}"; do
    IFS=':' read -r key name deps <<< "$dep_config"
    
    # Skip if already installed
    if echo "$existing_deps" | grep -q "$key"; then
      print_info "$name is already installed, skipping"
      continue
    fi
    
    # Skip Bodyguard if auth is not selected
    if [[ "$key" == "bodyguard" && "$auth" != true ]]; then
      continue
    fi
    
    read -rp "Include $name? (Y/n): " yn
    if [[ ! $yn =~ ^[Nn]$ ]]; then
      extra_deps+=(":$key")
    fi
  done
  
  # Join array elements with spaces and add auth
  local deps_string="${extra_deps[*]}"
  echo "${deps_string}:$auth"
}

# Setup authentication for existing project
setup_authentication_existing() {
  local auth="$1"
  
  if [ "$auth" = true ]; then
    print_step "Setting up authentication"
    mix phx.gen.auth Accounts User users
    print_step "Installing auth dependencies"
    mix deps.get
    print_success "Authentication setup complete"
  fi
}

# Main enhancement function
enhance_phoenix_project() {
  local project_name="$1"
  local extra_deps="$2"
  local auth="$3"
  
  print_step "Enhancing Phoenix project: $project_name"
  
  # Add dependencies
  add_dependencies_to_mix "$extra_deps"
  
  # Install dependencies
  install_dependencies
  
  # Setup authentication
  setup_authentication_existing "$auth"
  
  # Setup Oban (if selected)
  setup_oban "$project_name" "$extra_deps"
  
  # Future: Add other component setups here
  # setup_bodyguard "$project_name" "$extra_deps"
  # setup_req "$project_name" "$extra_deps"
  # setup_waffle "$project_name" "$extra_deps"
  # setup_open_api_spex "$project_name" "$extra_deps"
  
  print_success "Project enhancement complete!"
  
  # Print summary
  echo ""
  echo "🎉 Phoenix project '$project_name' enhanced successfully!"
  echo ""
  echo "📋 What was added:"
  
  if [ -n "$extra_deps" ]; then
    echo "   📦 Dependencies:"
    for dep in $extra_deps; do
      case $dep in
        :oban) echo "     - Oban (background jobs)";;
        :bodyguard) echo "     - Bodyguard (authorization)";;
        :req) echo "     - Req (HTTP client)";;
        :waffle) echo "     - Waffle (file upload)";;
        :open_api_spex) echo "     - OpenApiSpex (API docs)";;
      esac
    done
  fi
  
  if [ "$auth" = true ]; then
    echo "   🔐 Authentication (phx.gen.auth)"
  fi
  
  echo ""
  echo "🚀 Next steps:"
  echo "   1. mix ecto.migrate"
  echo "   2. mix phx.server"
  echo "   3. Visit http://localhost:4000"
  echo ""
  echo "📖 See startup.md for detailed setup instructions for each component."
}

# Main execution
main() {
  print_step "Phoenix Project Enhancement Tool"
  echo ""
  
  # Check if we're in a Phoenix project
  check_phoenix_project
  
  # Get project name
  local project_name=$(get_project_name_from_mix)
  print_info "Project name: $project_name"
  
  # Get existing dependencies
  local existing_deps=$(get_existing_dependencies)
  if [ -n "$existing_deps" ]; then
    print_info "Existing dependencies: $existing_deps"
  else
    print_info "No existing dependencies found"
  fi
  
  # Get enhancement options
  local deps_and_auth=$(get_enhancement_options "$existing_deps")
  
  # Parse dependencies and auth
  local extra_deps=$(echo "$deps_and_auth" | cut -d: -f1)
  local auth=$(echo "$deps_and_auth" | cut -d: -f2)
  
  print_info "Raw deps_and_auth: $deps_and_auth"
  print_info "Parsed extra_deps: $extra_deps"
  print_info "Parsed auth: $auth"
  
  # Enhance project
  enhance_phoenix_project "$project_name" "$extra_deps" "$auth"
}

# Run main function
main 