#!/bin/bash

set -e

# Get the actual script directory (resolving symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# Source all modules
source "$SCRIPT_DIR/_common.sh"
source "$SCRIPT_DIR/_phoenix.sh"
source "$SCRIPT_DIR/_oban.sh"

# Main execution
main() {
  # Get user inputs
  local project_name=$(get_project_name)
  local db_flag=$(get_database_selection)
  local features=$(get_optional_features)
  local deps_and_auth=$(get_additional_dependencies)
  
  # Parse dependencies and auth
  local extra_deps=$(echo "$deps_and_auth" | sed 's/^://' | cut -d: -f1)
  local auth=$(echo "$deps_and_auth" | cut -d: -f2)
  
  print_info "Raw deps_and_auth: $deps_and_auth"
  print_info "Parsed extra_deps: $extra_deps"
  print_info "Parsed auth: $auth"
  
  # Setup Phoenix (core application)
  setup_phoenix "$project_name" "$db_flag" "$features" "$extra_deps" "$auth"

  # Debug: print extra_deps before calling setup_oban
  print_info "[DEBUG] extra_deps before setup_oban: '$extra_deps'"

  # Setup Oban (if selected)
  setup_oban "$project_name" "$extra_deps"
  
  # Future: Add other component setups here
  # setup_bodyguard "$project_name" "$extra_deps"
  # setup_req "$project_name" "$extra_deps"
  # setup_waffle "$project_name" "$extra_deps"
  # setup_open_api_spex "$project_name" "$extra_deps"
}

# Run main function
main 