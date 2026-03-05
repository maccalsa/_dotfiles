# x_ Toolset - Final Structure

## Folder Layout

```
stow/scripts/
├── .local/bin/                    # All tools (stow to ~/.local)
│   ├── x_                         # Index: list all tools (run "x_" for index)
│   ├── _x_manifest                # Descriptions for x_ index
│   │
│   ├── x_backup                   # Tar backup (local/SSH)
│   ├── x_backup_repos             # GitHub repo backup/archive/delete
│   ├── x_crontab                  # Crontab manager
│   ├── x_git_amend_date           # Amend commit dates
│   ├── x_gradle_bootstrap         # Gradle/Spring Boot wizard
│   ├── x_install                  # Add ~/.local/bin to PATH
│   ├── x_mkdocs_init              # MkDocs + GitHub Pages setup
│   ├── x_monokit                  # TypeScript monorepo CLI
│   ├── x_monokit_menu             # Interactive menu for x_monokit
│   ├── x_nextjs_bootstrap         # Next.js + Prisma + Shadcn
│   ├── x_phoenix_create           # Create Phoenix app
│   ├── x_phoenix_enhance           # Enhance existing Phoenix project
│   ├── x_port                     # Port operations (list, kill, monitor)
│   ├── x_ramdisk                  # tmpfs/RAM disk manager
│   ├── x_spring_init              # Simple Spring Boot init
│   ├── x_ts_lib_create            # TypeScript library scaffold
│   ├── x_tunnel                   # SSH port forwarding
│   ├── x_yt                       # YouTube/video downloader
│   │
│   ├── x_archive                  # Compress dir to tar.gz/zip
│   ├── x_base64                   # Base64 encode/decode
│   ├── x_extract                  # Extract archives by extension
│   ├── x_json                     # Pretty-print JSON
│   ├── x_password                 # Generate random password
│   ├── x_docker_clean             # Prune Docker (images, containers, volumes)
│   ├── x_docker_compose           # Scaffold docker-compose
│   ├── x_docker_run               # Interactive docker run
│   ├── x_git_clean                # Delete merged branches, prune remotes
│   ├── x_git_repo_init            # Create repo, add remote, push
│   ├── x_git_submodule            # Init, update, add submodules
│   ├── x_git_worktree             # Add/list/remove worktrees
│   ├── x_ssh_config               # Add host to ~/.ssh/config
│   ├── x_ssh_key                  # Generate SSH key, add to agent
│   ├── x_py_project               # Scaffold pyproject.toml + venv
│   ├── x_py_venv                  # Create Python venv
│   ├── x_node_clean               # Remove node_modules, reinstall
│   ├── x_node_version             # Show Node/npm versions
│   ├── x_cert_check               # Check SSL cert expiry
│   ├── x_cert_self                # Generate self-signed cert
│   ├── x_go_init                  # Go mod init + scaffold
│   ├── x_rust_init                # Cargo init (optional --deps)
│   │
│   ├── _common.sh                 # Phoenix helpers (sourced)
│   ├── _phoenix.sh
│   ├── _oban.sh
│   ├── _nextjs_common.sh
│   │
│   └── code.json                  # Spring Boot starter metadata
│
├── .config/scripts/agemt/
│   └── secrets-agent.sh           # Sourced at login (SSH/GPG agent)
│
├── README.md
└── STRUCTURE.md                   # This file
```

## Rename Mapping (Completed)

| Old Name | New Name |
|----------|----------|
| backup_and_cleanup_repos | x_backup_repos |
| create_phoenix_app.sh | x_phoenix_create |
| enhance_phoenix_app.sh | x_phoenix_enhance |
| create-ts-lib.sh | x_ts_lib_create |
| nextjs-bootstrap.sh | x_nextjs_bootstrap |
| gradle-bootstrap | x_gradle_bootstrap |
| spring-init.sh | x_spring_init |
| git-amend-date | x_git_amend_date |
| git_mkdocs_init.sh | x_mkdocs_init |
| monokit | x_monokit |
| mmonokit | x_monokit_menu |
| yt.py | x_yt |
| crontab.sh | x_crontab |
| memory_disk.sh | x_ramdisk |
| port_monitor.sh | x_port |
| robust-backup.sh | x_backup |
| safe-file-manager.sh | *(removed – unsafe)* |
| tunnel.sh | x_tunnel |
| install.sh | x_install |

## Quick Start

```bash
# 1. Stow the scripts (from dotfiles root)
stow scripts

# 2. Add to PATH (if not already)
x_install

# 3. List all tools
x_

# 4. Get help for a tool
x_ x_phoenix_create
```
