#!/bin/bash

set -e

read -rp "Enter project name: " project_name

# Database selection
PS3="Choose your database: "
options=("PostgreSQL (default)" "MySQL" "SQLite" "None")
select opt in "${options[@]}"
do
    case $opt in
        "PostgreSQL (default)") db_flag=""; break;;
        "MySQL") db_flag="--database mysql"; break;;
        "SQLite") db_flag="--database sqlite3"; break;;
        "None") db_flag="--no-ecto"; break;;
        *) echo "Invalid option";;
    esac
done

# Optional features
features=()
read -rp "Include LiveView? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && features+=("") || features+=("--no-live")
read -rp "Include TailwindCSS? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && features+=("") || features+=("--no-tailwind")
read -rp "Include built-in Mailer (Swoosh)? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && features+=("") || features+=("--no-mailer")

# Additional ecosystem libraries
extra_deps=()
read -rp "Include Oban (background jobs)? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && extra_deps+=(":oban")
read -rp "Include Authentication (phx.gen.auth)? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && auth=true
read -rp "Include Authorization (Bodyguard)? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && extra_deps+=(":bodyguard")
read -rp "Include Req (HTTP Client)? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && extra_deps+=(":req")
read -rp "Include Waffle (File Upload)? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && extra_deps+=(":waffle")
read -rp "Include OpenApiSpex (API docs)? (Y/n): " yn && [[ ! $yn =~ ^[Nn]$ ]] && extra_deps+=(":open_api_spex")

# Create project
echo "Creating Phoenix project: $project_name"
mix phx.new "$project_name" $db_flag "${features[@]}"

# Check if project creation was successful
if [ ! -d "$project_name" ]; then
  echo "❌ Failed to create project. Please check your inputs and try again."
  exit 1
fi

cd "$project_name" || exit
echo "✅ Project created successfully!"

# Add dependencies to mix.exs
if [ ${#extra_deps[@]} -gt 0 ]; then
  echo "📦 Adding dependencies to mix.exs..."
  # Create a temporary file for the new mix.exs
  temp_mix="$(mktemp)"
  
  # Build the dependency lines to insert
  dep_lines=""
  dep_count=0
  total_deps=${#extra_deps[@]}
  
  for dep in "${extra_deps[@]}"; do
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
  
  # Create external awk script to avoid bash syntax conflicts
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

  # Use the external awk script
  awk -v deps="$dep_lines" -f /tmp/add_deps.awk mix.exs > "$temp_mix"
  
  # Clean up the temporary awk script
  rm /tmp/add_deps.awk
  
  # Replace the original file
  echo "✅ Dependencies added to mix.exs"
fi

echo "📦 Installing dependencies..."
mix deps.get

# Set up Auth if selected
if [ "$auth" = true ]; then
  echo "🔐 Setting up authentication..."
  mix phx.gen.auth Accounts User users
  echo "📦 Installing auth dependencies..."
  mix deps.get
  echo "✅ Authentication setup complete"
fi

# Setup Database
if [ -z "$db_flag" ] || [[ $db_flag != "--no-ecto" ]]; then
  echo "🗄️  Setting up database..."
  mix ecto.create
  echo "✅ Database setup complete"
fi

# Generate startup.md
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

# Done
echo "✅ Setup complete! See startup.md for next steps."

# Print summary
echo ""
echo "🎉 Phoenix project '$project_name' created successfully!"
echo ""
echo "📋 What was installed:"
if [ ${#extra_deps[@]} -gt 0 ]; then
  echo "   📦 Dependencies:"
  for dep in "${extra_deps[@]}"; do
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

