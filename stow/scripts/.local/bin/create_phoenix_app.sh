#!/bin/bash

set -e

# Configuration
DEPENDENCIES=(
  "oban:Oban (background jobs):{:oban, \"~> 2.17\"}, {:oban_web, \"~> 2.12\"}"
  "bodyguard:Bodyguard (authorization):{:bodyguard, \"~> 2.4\"}"
  "req:Req (HTTP client):{:req, \"~> 0.4\"}"
  "waffle:Waffle (file upload):{:waffle, \"~> 1.1\"}, {:waffle_ecto, \"~> 0.0.11\"}"
  "open_api_spex:OpenApiSpex (API docs):{:open_api_spex, \"~> 3.19\"}"
)

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
  echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Get user input for project name
get_project_name() {
  read -rp "Enter project name: " project_name
  echo "$project_name"
}

# Get database selection
get_database_selection() {
  PS3="Choose your database: "
  options=("PostgreSQL (default)" "MySQL" "SQLite" "None")
  select opt in "${options[@]}"
  do
    case $opt in
      "PostgreSQL (default)") echo ""; break;;
      "MySQL") echo "--database mysql"; break;;
      "SQLite") echo "--database sqlite3"; break;;
      "None") echo "--no-ecto"; break;;
      *) echo "Invalid option";;
    esac
  done
}

# Get optional features
get_optional_features() {
  local features=()
  read -rp "Include LiveView? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && features+=("") || features+=("--no-live")
  read -rp "Include TailwindCSS? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && features+=("") || features+=("--no-tailwind")
  read -rp "Include built-in Mailer (Swoosh)? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && features+=("") || features+=("--no-mailer")
  echo "${features[@]}"
}

# Get additional dependencies
get_additional_dependencies() {
  local extra_deps=()
  local auth=false
  
  for dep_config in "${DEPENDENCIES[@]}"; do
    IFS=':' read -r key name deps <<< "$dep_config"
    read -rp "Include $name? (Y/n): " yn
    if [[ ! $yn =~ ^[Nn]$ ]]; then
      extra_deps+=(":$key")
    fi
  done
  
  read -rp "Include Authentication (phx.gen.auth)? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && auth=true
  
  echo "${extra_deps[@]}:$auth"
}

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

# Build dependency lines for mix.exs
build_dependency_lines() {
  local extra_deps="$1"
  local dep_lines=""
  local dep_count=0
  local total_deps=$(echo "$extra_deps" | wc -w)
  
  for dep in $extra_deps; do
    ((dep_count++))
    case $dep in
      :oban) 
        if [ $dep_count -eq $total_deps ]; then
          dep_lines="${dep_lines}      {:oban, \"~> 2.17\"},
      {:oban_web, \"~> 2.12\"}
"
        else
          dep_lines="${dep_lines}      {:oban, \"~> 2.17\"},
      {:oban_web, \"~> 2.12\"},
"
        fi
        ;;
      :bodyguard) 
        if [ $dep_count -eq $total_deps ]; then
          dep_lines="${dep_lines}      {:bodyguard, \"~> 2.4\"}
"
        else
          dep_lines="${dep_lines}      {:bodyguard, \"~> 2.4\"},
"
        fi
        ;;
      :req) 
        if [ $dep_count -eq $total_deps ]; then
          dep_lines="${dep_lines}      {:req, \"~> 0.4\"}
"
        else
          dep_lines="${dep_lines}      {:req, \"~> 0.4\"},
"
        fi
        ;;
      :waffle) 
        if [ $dep_count -eq $total_deps ]; then
          dep_lines="${dep_lines}      {:waffle, \"~> 1.1\"},
      {:waffle_ecto, \"~> 0.0.11\"}
"
        else
          dep_lines="${dep_lines}      {:waffle, \"~> 1.1\"},
      {:waffle_ecto, \"~> 0.0.11\"},
"
        fi
        ;;
      :open_api_spex) 
        if [ $dep_count -eq $total_deps ]; then
          dep_lines="${dep_lines}      {:open_api_spex, \"~> 3.19\"}
"
        else
          dep_lines="${dep_lines}      {:open_api_spex, \"~> 3.19\"},
"
        fi
        ;;
    esac
  done
  
  echo "$dep_lines"
}

# Create awk script for dependency injection
create_awk_script() {
  cat > /tmp/add_deps.awk << 'AWK_SCRIPT'
BEGIN {
  in_deps = 0
  deps_added = 0
  in_list = 0
  last_line = ""
}
/^  defp deps do$/ {
  print
  in_deps = 1
  next
}
in_deps && /^    \[$/ {
  in_list = 1
  print
  next
}
in_deps && in_list && /^    \]$/ {
  if (!deps_added) {
    # Add comma to the last existing dependency if it doesn't have one
    if (index(last_line, ",") == 0) {
      sub(/$/, ",", last_line)
      print last_line
    }
    # Add the new dependencies
    printf "%s", deps
    deps_added = 1
  }
  print
  in_list = 0
  next
}
in_deps && in_list {
  # Store the last line to potentially add a comma
  last_line = $0
  print
  next
}
in_deps && /^  end$/ {
  print
  in_deps = 0
  next
}
{ print }
AWK_SCRIPT
}

# Add dependencies to mix.exs
add_dependencies_to_mix() {
  local extra_deps="$1"
  
  if [ -n "$extra_deps" ]; then
    print_step "Adding dependencies to mix.exs"
    
    local temp_mix="$(mktemp)"
    local dep_lines=$(build_dependency_lines "$extra_deps")
    
    create_awk_script
    
    # Use the external awk script
    awk -v deps="$dep_lines" -f /tmp/add_deps.awk mix.exs > "$temp_mix"
    
    # Clean up the temporary awk script
    rm /tmp/add_deps.awk
    
    # Replace the original file
    mv "$temp_mix" mix.exs
    print_success "Dependencies added to mix.exs"
  fi
}

# Install dependencies
install_dependencies() {
  print_step "Installing dependencies"
  mix deps.get
  print_success "Dependencies installed"
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

# Setup database
setup_database() {
  local db_flag="$1"
  
  if [ -z "$db_flag" ] || [[ $db_flag != "--no-ecto" ]]; then
    print_step "Setting up database"
    mix ecto.create
    print_success "Database setup complete"
  fi
}

# Generate startup documentation
generate_startup_docs() {
  cat <<EOF > startup.md
# Startup Guide

## Background Jobs (Oban)
- Configure in \`config/config.exs\`: [Oban Setup](https://hexdocs.pm/oban/readme.html)

## Authentication (Phx.Gen.Auth)
- Run migrations: \`mix ecto.migrate\`
- Routes and templates already generated.

## Authorization (Bodyguard)
- [Bodyguard Setup](https://github.com/schrockwell/bodyguard)

## HTTP Client (Req)
- Usage: [Req docs](https://hexdocs.pm/req/readme.html)

## File Upload (Waffle)
- [Waffle Setup](https://github.com/elixir-waffle/waffle)

## API Documentation (OpenApiSpex)
- Configure via [OpenApiSpex](https://github.com/open-api-spex/open_api_spex)

## TailwindCSS
- Install assets via: \`cd assets && npm install\`

## Mailer (Swoosh)
- [Swoosh Guide](https://hexdocs.pm/swoosh/readme.html)

Start your server:

\`\`\`bash
mix phx.server
\`\`\`
EOF
}

# Print summary
print_summary() {
  local project_name="$1"
  local extra_deps="$2"
  local auth="$3"
  
  echo ""
  echo "🎉 Phoenix project '$project_name' created successfully!"
  echo ""
  echo "📋 What was installed:"
  
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
  echo "   1. cd $project_name"
  echo "   2. mix phx.server"
  echo "   3. Visit http://localhost:4000"
  echo ""
  echo "📖 See startup.md for detailed setup instructions for each component."
}

# Main execution
main() {
  # Get user inputs
  local project_name=$(get_project_name)
  local db_flag=$(get_database_selection)
  local features=$(get_optional_features)
  local deps_and_auth=$(get_additional_dependencies)
  
  # Parse dependencies and auth
  local extra_deps=$(echo "$deps_and_auth" | cut -d: -f1)
  local auth=$(echo "$deps_and_auth" | cut -d: -f2)
  
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

# Run main function
main

