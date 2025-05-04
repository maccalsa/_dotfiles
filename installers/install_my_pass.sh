#!/bin/bash

set -e  # Exit if any command fails

echo "🔐 [1/5] Installing pass and GPG tools..."
sudo apt update
sudo apt install -y pass gnupg git

echo "🗂️ [2/5] Cloning password store..."
if [ ! -d "$HOME/.password-store" ]; then
    git clone git@github.com:maccalsa/pws-store.git "$HOME/.password-store"
else
    echo "✅ Password store already cloned."
fi

echo "🧠 [3/5] Setting up GPG agent caching..."
GPG_AGENT_CONF="$HOME/.gnupg/gpg-agent.conf"
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

# Write or update config with caching lines
grep -qxF "default-cache-ttl 3600" "$GPG_AGENT_CONF" 2>/dev/null || echo "default-cache-ttl 3600" >> "$GPG_AGENT_CONF"
grep -qxF "max-cache-ttl 86400" "$GPG_AGENT_CONF" 2>/dev/null || echo "max-cache-ttl 86400" >> "$GPG_AGENT_CONF"

echo "🔁 [4/5] Restarting GPG agent..."
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent

echo "✅ [5/5] Setup complete. Testing pass..."
pass ls || echo "Run 'pass init <GPG-ID>' if this is a fresh store."

echo "💡 Tip: Add this to your agent script if you haven't already:"
echo '  export GPG_TTY=$(tty)'