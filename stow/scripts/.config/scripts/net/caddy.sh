#!/bin/bash
set -e

# 1. Create the Caddyfile
cat <<'EOF' > Caddyfile
:80 {
    reverse_proxy 127.0.0.1:1234
}
EOF
echo "Caddyfile created with reverse_proxy 127.0.0.1:1234."

# 4. Start Caddy with Docker using host networking
echo "Starting Caddy in Docker with host networking..."
docker run -d \
  --name caddy \
  --network host \
  -v "$(pwd)/Caddyfile":/etc/caddy/Caddyfile \
  caddy:latest

# Final status
echo "Caddy started successfully."