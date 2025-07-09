#!/bin/bash

# Get the actual script directory (resolving symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/_common.sh"

# Create Phoenix project
create_phoenix_project() {
  local project_name="$1"
  local db_flag="$2"
  local features="$3"
  
  print_step "Creating Phoenix project: $project_name"
  mix phx.new "$project_name" $db_flag $features
  
  if [ ! -d "$project_name" ]; then
    print_error "Failed to create project. Please check your inputs and try again."
    exit 1
  fi
  
  cd "$project_name" || exit
  print_success "Project created successfully!"
}

# Setup authentication
setup_authentication() {
  local auth="$1"
  
  if [ "$auth" = true ]; then
    print_step "Setting up authentication"
    mix phx.gen.auth Accounts User users
    print_step "Installing auth dependencies"
    mix deps.get
    print_success "Authentication setup complete"
  fi
}

# Main Phoenix setup function
setup_phoenix() {
  local project_name="$1"
  local db_flag="$2"
  local features="$3"
  local extra_deps="$4"
  local auth="$5"
  
  # Create project
  create_phoenix_project "$project_name" "$db_flag" "$features"
  
  # Add dependencies
  add_dependencies_to_mix "$extra_deps"
  
  # Install dependencies
  install_dependencies
  
  # Setup authentication
  setup_authentication "$auth"
  
  # Setup database
  setup_database "$db_flag"
  
  # Generate documentation
  generate_startup_docs
  
  # Print summary
  print_summary "$project_name" "$extra_deps" "$auth"
} 