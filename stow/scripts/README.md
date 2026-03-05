# Personal Toolset (x_ scripts)

A collection of bash scripts for project bootstrapping, system utilities, and development workflows. All tools use the `x_` prefix and live in `~/.local/bin`.

**Quick start:** Run `x_` to list all tools. Run `x_install` to add `~/.local/bin` to PATH.

See [STRUCTURE.md](STRUCTURE.md) for the full layout and rename mapping.

---

# Phoenix Bootstrap (x_phoenix_create / x_phoenix_enhance)

A comprehensive, modular bash script that creates Phoenix applications with popular ecosystem libraries and proper bootstrapping.

## 🏗️ Architecture

The Phoenix scripts are organized into modular components:

```
.local/bin/
├── _common.sh              # Shared utilities and functions
├── _phoenix.sh             # Core Phoenix application setup
├── _oban.sh                # Oban background jobs setup
├── x_phoenix_create        # Main orchestrator script
└── x_phoenix_enhance       # Enhance existing projects
```

### **Benefits of Modular Architecture**

- **🔧 Single Responsibility**: Each module has one clear purpose
- **🧩 Reusable**: Modules can be used independently
- **🛠️ Maintainable**: Easy to modify individual components
- **🧪 Testable**: Each module can be tested in isolation
- **📈 Scalable**: Easy to add new component modules

## 🚀 Features

### **Core Phoenix Setup**
- ✅ Project creation with custom database selection
- ✅ Optional features (LiveView, TailwindCSS, Mailer)
- ✅ Proper dependency injection into `mix.exs`
- ✅ Database setup and migration handling

### **Ecosystem Libraries**
- ✅ **Oban** - Background job processing with full bootstrap
- ✅ **Bodyguard** - Authorization library (only offered with auth)
- ✅ **Req** - HTTP client
- ✅ **Waffle** - File upload handling
- ✅ **OpenApiSpex** - API documentation
- ✅ **Authentication** - phx.gen.auth integration

### **Smart Dependency Management**
- **🔐 Auth + Bodyguard Coupling**: Bodyguard is only offered when authentication is selected
- **🔄 Existing Project Detection**: Enhancement script detects existing dependencies
- **⚡ Smart Enhancement**: Skip already installed components

### **Oban Bootstrap (Complete Setup)**
When Oban is selected, the script automatically:
- ✅ Adds dependencies to `mix.exs`
- ✅ Configures Oban in `config/config.exs` and `config/runtime.exs`
- ✅ Adds Oban to the supervision tree in `lib/app_name/application.ex`
- ✅ Generates and configures database migration
- ✅ Creates sample worker in `lib/app_name/workers/`
- ✅ Sets up Oban Web dashboard routes
- ✅ Provides monitoring at `http://localhost:4000/oban`

## 📁 Project Structure

```
my_app/
├── lib/my_app/
│   ├── application.ex          # Oban supervision added
│   └── workers/               # Sample Oban worker
│       └── sample_worker.ex
├── config/
│   ├── config.exs             # Oban configuration
│   └── runtime.exs            # Runtime Oban config
├── priv/repo/migrations/      # Oban jobs table migration
├── lib/my_app_web/router.ex   # Oban Web routes
└── startup.md                 # Setup instructions
```

## 🛠️ How to Use

### **Create New Project**
```bash
x_phoenix_create
```

### **Enhance Existing Project**
```bash
cd your_phoenix_project
x_phoenix_enhance
```

## 🔧 Module Structure

### **`_common.sh` - Shared Utilities**
- Color output functions
- User input functions
- Dependency management
- File manipulation utilities
- Documentation generation

### **`_phoenix.sh` - Core Phoenix Setup**
- Project creation
- Authentication setup
- Database configuration
- Dependency injection
- Summary generation

### **`_oban.sh` - Oban Component**
- Configuration setup
- Supervision tree modification
- Migration generation
- Worker creation
- Web dashboard setup

### **`x_phoenix_create` - Main Orchestrator**
- Sources all modules
- Coordinates the setup process
- Manages component execution order

### **`x_phoenix_enhance` - Project Enhancement**
- Detects existing Phoenix projects
- Identifies already installed dependencies
- Adds new components to existing projects
- Smart dependency management

## 🔐 Smart Dependency Logic

### **Authentication + Authorization Coupling**
The script intelligently manages dependencies:

1. **Authentication First**: Always asks about authentication first
2. **Bodyguard Conditional**: Bodyguard is only offered if authentication is selected
3. **Logical Flow**: This prevents illogical combinations like Bodyguard without auth

### **Existing Project Enhancement**
The enhancement script:

1. **Detects Phoenix Project**: Validates you're in a Phoenix project directory
2. **Identifies Existing Dependencies**: Scans `mix.exs` for already installed components
3. **Skips Installed Components**: Won't re-install already present dependencies
4. **Smart Detection**: Automatically detects if auth is already set up

## 🔧 Adding New Components

### **Step 1: Create Component Module**

Create `_your_component.sh`:

```bash
#!/bin/bash

# Source common functions
source "$(dirname "$0")/_common.sh"

# Setup Your Component
setup_your_component() {
  local project_name="$1"
  local extra_deps="$2"
  
  if echo "$extra_deps" | grep -q ":your_component"; then
    print_step "Setting up Your Component"
    
    # Add your component setup logic here
    # - Configuration files
    # - Database migrations
    # - Supervision setup
    # - Sample files
    
    print_success "Your Component setup complete"
  else
    print_info "Your Component not selected, skipping setup"
  fi
}
```

### **Step 2: Add to Main Script**

In `x_phoenix_create`:

```bash
# Source your component
source "$(dirname "$0")/_your_component.sh"

# In main function
setup_your_component "$project_name" "$extra_deps"
```

### **Step 3: Add to Dependencies**

In `_common.sh`:

```bash
DEPENDENCIES=(
  "oban:Oban (background jobs):{:oban, \"~> 2.17\"}, {:oban_web, \"~> 2.12\"}"
  "your_component:Your Component (description):{:your_component, \"~> 1.0\"}"
)
```

### **Step 4: Add Dependency Logic**

In `build_dependency_lines()`:

```bash
:your_component) 
  if [ $dep_count -eq $total_deps ]; then
    dep_lines="${dep_lines}      {:your_component, \"~> 1.0\"}
"
  else
    dep_lines="${dep_lines}      {:your_component, \"~> 1.0\"},
"
  fi
  ;;
```

### **Step 5: Add to Enhancement Script**

In `x_phoenix_enhance`, add to `get_existing_dependencies()`:

```bash
if grep -q ":your_component" mix.exs; then
  existing_deps+=("your_component")
fi
```

## 📋 Component Enhancement Guide

### **For Database-Required Components**

1. **Migration Generation**
   ```bash
   mix ecto.gen.migration add_your_component_table
   ```

2. **Migration Content**
   ```elixir
   defmodule AppName.Repo.Migrations.AddYourComponentTable do
     use Ecto.Migration
     
     def change do
       create table(:your_table) do
         add :field, :string
         timestamps()
       end
     end
   end
   ```

3. **Schema Creation**
   ```bash
   mkdir -p lib/${project_name}/schemas
   cat > lib/${project_name}/schemas/your_schema.ex << 'Schema'
   defmodule ${project_name}.Schemas.YourSchema do
     use Ecto.Schema
     import Ecto.Changeset
     
     schema "your_table" do
       field :field, :string
       timestamps()
     end
   end
   Schema
   ```

### **For Web Components**

1. **Router Updates**
   ```bash
   # Add routes to router.ex
   awk -v project="$project_name" '
   /scope "\/", ${project}_web do/ {
     print
     print "    get \"/your-route\", YourController, :index"
     next
   }
   { print }
   ' lib/${project_name}_web/router.ex > "$temp_router"
   ```

2. **Controller Creation**
   ```bash
   mkdir -p lib/${project_name}_web/controllers
   cat > lib/${project_name}_web/controllers/your_controller.ex << 'Controller'
   defmodule ${project_name}_web.YourController do
     use ${project_name}_web, :controller
     
     def index(conn, _params) do
       render(conn, :index)
     end
   end
   Controller
   ```

### **For Configuration Components**

1. **Config Files**
   ```bash
   # Add to config/config.exs
   cat >> config/config.exs << 'Config'
   
   # Your Component Configuration
   config :${project_name}, YourComponent,
     setting: "value"
   Config
   
   # Add to config/runtime.exs
   cat >> config/runtime.exs << 'RuntimeConfig'
   
   # Your Component Runtime Configuration
   config :${project_name}, YourComponent,
     url: System.get_env("YOUR_COMPONENT_URL")
   RuntimeConfig
   ```

## 🎯 Best Practices

### **1. Modular Functions**
- Keep each component setup in its own function
- Use descriptive function names
- Pass project_name as parameter

### **2. Error Handling**
- Check if files exist before modifying
- Use temporary files for modifications
- Provide clear error messages

### **3. Documentation**
- Update startup.md with new components
- Include links to official documentation
- Provide usage examples

### **4. Testing**
- Test each component independently
- Verify file modifications
- Check generated code syntax

## 🔍 Troubleshooting

### **Common Issues**

1. **Migration Not Found**
   ```bash
   # Ensure migration file exists
   local migration_file=$(find priv/repo/migrations -name "*_migration_name.exs" | head -1)
   ```

2. **File Modification Errors**
   ```bash
   # Use temporary files
   local temp_file="$(mktemp)"
   # Modify temp_file
   mv "$temp_file" target_file
   ```

3. **Variable Scope Issues**
   ```bash
   # Use local variables
   local project_name="$1"
   local extra_deps="$2"
   ```

## 📚 Resources

- [Phoenix Framework](https://phoenixframework.org/)
- [Oban Documentation](https://hexdocs.pm/oban/readme.html)
- [Bodyguard](https://github.com/schrockwell/bodyguard)
- [Req HTTP Client](https://hexdocs.pm/req/readme.html)
- [Waffle File Upload](https://github.com/elixir-waffle/waffle)
- [OpenApiSpex](https://github.com/open-api-spex/open_api_spex)

## 🤝 Contributing

To add new components:

1. Follow the enhancement guide above
2. Test thoroughly with different configurations
3. Update documentation
4. Ensure backward compatibility

## 📄 License

This script is provided as-is for educational and development purposes. 