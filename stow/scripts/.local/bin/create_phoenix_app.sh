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
mix phx.new "$project_name" $db_flag "${features[@]}"
cd "$project_name" || exit

# Add dependencies to mix.exs
for dep in "${extra_deps[@]}"; do
  case $dep in
    :oban) echo '{:oban, "~> 2.17"}, {:oban_web, "~> 2.12"},' >> mix.exs;;
    :bodyguard) echo '{:bodyguard, "~> 2.4"},' >> mix.exs;;
    :req) echo '{:req, "~> 0.4"},' >> mix.exs;;
    :waffle) echo '{:waffle, "~> 1.1"}, {:waffle_ecto, "~> 0.0.11"},' >> mix.exs;;
    :open_api_spex) echo '{:open_api_spex, "~> 3.19"},' >> mix.exs;;
  esac
done

mix deps.get

# Set up Auth if selected
if [ "$auth" = true ]; then
  mix phx.gen.auth Accounts User users
  mix deps.get
fi

# Setup Database
if [ -z "$db_flag" ] || [[ $db_flag != "--no-ecto" ]]; then
  mix ecto.create
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

