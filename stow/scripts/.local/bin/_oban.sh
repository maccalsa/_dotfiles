#!/bin/bash

# Get the actual script directory (resolving symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/_common.sh"

# Setup Oban configuration
setup_oban_config() {
  local project_name="$1"
  
  print_step "Setting up Oban configuration"
  
  # Add Oban config to config/config.exs
  cat >> config/config.exs << ObanConfig

# Oban Configuration
config :${project_name}, Oban,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Web.Plugins.Stats, interval: :timer.seconds(30)}
  ],
  queues: [
    default: 10,
    mailers: 20,
    events: 50
  ]
ObanConfig

  # Add Oban config to config/runtime.exs
  cat >> config/runtime.exs << ObanRuntimeConfig

# Oban Runtime Configuration
config :${project_name}, Oban,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
ObanRuntimeConfig

  print_success "Oban configuration added"
}

# Setup Oban supervision
setup_oban_supervision() {
  local project_name="$1"
  
  print_step "Setting up Oban supervision"
  
  # Create temporary file for application.ex
  local temp_app="$(mktemp)"
  
  # Add Oban to the supervision tree using sed
  sed "/children = \[/a\    {Oban, Application.fetch_env!(:${project_name}, Oban)}," lib/${project_name}/application.ex > "$temp_app"
  
  # Replace the original file
  mv "$temp_app" lib/${project_name}/application.ex
  
  print_success "Oban supervision configured"
}

# Create Oban migration
create_oban_migration() {
  local project_name="$1"
  
  print_step "Creating Oban migration"
  
  # Generate migration file
  mix ecto.gen.migration add_oban_jobs_table
  
  # Find the generated migration file
  local migration_file=$(find priv/repo/migrations -name "*_add_oban_jobs_table.exs" | head -1)
  
  if [ -n "$migration_file" ]; then
    # Convert project name to proper module name (capitalize first letter)
    local module_name=$(echo "$project_name" | sed 's/^./\U&/')
    
    # Replace the migration content with Oban table structure
    cat > "$migration_file" << ObanMigration
defmodule ${module_name}.Repo.Migrations.AddObanJobsTable do
  use Ecto.Migration

  def up do
    Oban.Migration.up(version: 11)
  end

  def down do
    Oban.Migration.down(version: 1)
  end
end
ObanMigration
    
    print_success "Oban migration created"
  else
    print_error "Failed to create Oban migration"
  fi
}

# Create sample Oban worker
create_oban_worker() {
  local project_name="$1"
  
  print_step "Creating sample Oban worker"
  
  # Create workers directory
  mkdir -p lib/${project_name}/workers
  
  # Convert project name to proper module name (capitalize first letter)
  local module_name=$(echo "$project_name" | sed 's/^./\U&/')
  
  # Create sample worker
  cat > lib/${project_name}/workers/sample_worker.ex << SampleWorker
# This worker requires Oban to be installed and configured
# Run 'mix deps.get' if you see compilation errors
defmodule ${module_name}.Workers.SampleWorker do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message" => message}}) do
    IO.puts("Processing: #{message}")
    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    IO.puts("Processing job with args: #{inspect(args)}")
    :ok
  end
end
SampleWorker
  
  # Compile dependencies to ensure Oban is available
  print_step "Compiling dependencies"
  mix deps.compile
  
  print_success "Sample Oban worker created"
}

# Setup Oban Web routes
setup_oban_web_routes() {
  local project_name="$1"
  
  print_step "Setting up Oban Web routes"
  
  # Create temporary file for router.ex
  local temp_router="$(mktemp)"
  
  # Add Oban Web routes for development
  awk -v project="$project_name" '
  /if Mix.env\(\) == :dev do/ {
    print
    print "  forward \"/oban\", Oban.Web"
    next
  }
  { print }
  ' lib/${project_name}_web/router.ex > "$temp_router"
  
  # Replace the original file
  mv "$temp_router" lib/${project_name}_web/router.ex
  
  print_success "Oban Web routes configured"
}

# Main Oban setup function
setup_oban() {
  local project_name="$1"
  local extra_deps="$2"
  
  print_info "Checking for Oban in dependencies: $extra_deps"
  
  if echo "$extra_deps" | grep -q "oban"; then
    print_step "Setting up Oban"
    
    setup_oban_config "$project_name"
    setup_oban_supervision "$project_name"
    create_oban_migration "$project_name"
    create_oban_worker "$project_name"
    setup_oban_web_routes "$project_name"
    
    print_success "Oban setup complete"
  else
    print_info "Oban not selected, skipping setup"
  fi
} 