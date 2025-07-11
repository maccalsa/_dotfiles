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

# Configuration
DEPENDENCIES=(
  "oban:Oban (background jobs):{:oban, \"~> 2.17\"}, {:oban_web, \"~> 2.12\"}"
  "bodyguard:Bodyguard (authorization):{:bodyguard, \"~> 2.4\"}"
  "req:Req (HTTP client):{:req, \"~> 0.4\"}"
  "waffle:Waffle (file upload):{:waffle, \"~> 1.1\"}, {:waffle_ecto, \"~> 0.0.11\"}"
  "open_api_spex:OpenApiSpex (API docs):{:open_api_spex, \"~> 3.19\"}"
)

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
  
  # First, ask about authentication
  read -rp "Include Authentication (phx.gen.auth)? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && auth=true
  
  # Then ask about other dependencies
  for dep_config in "${DEPENDENCIES[@]}"; do
    IFS=':' read -r key name deps <<< "$dep_config"
    
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

# Build dependency lines for mix.exs
build_dependency_lines() {
  local extra_deps="$1"
  local dep_lines=""
  local dep_count=0
  local total_deps=$(echo "$extra_deps" | wc -w)
  
  echo "[DEBUG] build_dependency_lines called with: '$extra_deps'" >&2
  echo "[DEBUG] total_deps: $total_deps" >&2
  
  for dep in $extra_deps; do
    ((dep_count++))
    echo "[DEBUG] Processing dep: '$dep' (count: $dep_count)" >&2
    case $dep in
      :oban) 
        echo "[DEBUG] Found oban dependency" >&2
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
      *) 
        echo "[DEBUG] Unknown dependency: '$dep'" >&2
        ;;
    esac
  done
  
  echo "[DEBUG] Final dep_lines: '$dep_lines'" >&2
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
  
  echo "[DEBUG] add_dependencies_to_mix called with: '$extra_deps'" >&2
  
  if [ -n "$extra_deps" ]; then
    print_step "Adding dependencies to mix.exs"
    
    local temp_mix="$(mktemp)"
    local dep_lines=$(build_dependency_lines "$extra_deps")
    
    echo "[DEBUG] Generated dep_lines: '$dep_lines'" >&2
    
    create_awk_script
    
    # Use the external awk script
    awk -v deps="$dep_lines" -f /tmp/add_deps.awk mix.exs > "$temp_mix"
    
    # Clean up the temporary awk script
    rm /tmp/add_deps.awk
    
    # Replace the original file
    mv "$temp_mix" mix.exs
    print_success "Dependencies added to mix.exs"
  else
    echo "[DEBUG] extra_deps is empty, skipping dependency addition" >&2
  fi
}

# Install dependencies
install_dependencies() {
  print_step "Installing dependencies"
  mix deps.get
  print_success "Dependencies installed"
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
- Run migrations: \`mix ecto.migrate\`
- Monitor jobs at: http://localhost:4000/oban (dev only)
- Sample worker: \`lib/app_name/workers/sample_worker.ex\`

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
  echo "   2. mix ecto.migrate"
  echo "   3. mix phx.server"
  echo "   4. Visit http://localhost:4000"
  echo ""
  echo "📖 See startup.md for detailed setup instructions for each component."
} 