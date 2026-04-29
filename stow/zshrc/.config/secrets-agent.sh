#!/bin/bash
# Unified SSH + GPG agent script

SSH_ENV="$HOME/.config/agent.env"

start_ssh_agent() {
    echo "Starting ssh-agent..."
    /usr/bin/ssh-agent -s | sed 's/^echo/#echo/' > "$SSH_ENV"
    chmod 700 "$SSH_ENV"
    source "$SSH_ENV"
}

mkdir -p "$HOME/.config"

if [ -f "$SSH_ENV" ]; then
    source "$SSH_ENV" > /dev/null 2>&1
    if ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
        echo "Stale ssh-agent. Restarting..."
        start_ssh_agent
    fi
else
    start_ssh_agent
fi

gpgconf --launch gpg-agent

if [ -d "$HOME/.ssh" ]; then
    for key in "$HOME/.ssh/"*; do
        if [[ -f "$key" && "$key" != *.pub ]]; then
            fingerprint=$(ssh-keygen -lf "$key" | awk '{print $2}')
            if ! ssh-add -l | grep -q "$fingerprint"; then
                echo "Adding SSH key: $key"
                ssh-add "$key" > /dev/null
            fi
        fi
    done

    chmod 700 "$HOME/.ssh"
    find "$HOME/.ssh" -type f -name "id_*" -exec chmod 600 {} \;
    find "$HOME/.ssh" -type f -name "*.pub" -exec chmod 644 {} \;
fi

if [ -d "$HOME/.gnupg" ]; then
    chmod 700 "$HOME/.gnupg"
    find "$HOME/.gnupg" -type f -exec chmod 600 {} \;
fi
