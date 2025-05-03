DEFAULT_PYTHON_VERSION="3.12.2"

read -p "Enter the version of python you want to install (default: $DEFAULT_PYTHON_VERSION): " PYTHON_VERSION
if [ -z "$PYTHON_VERSION" ]; then
  PYTHON_VERSION=$DEFAULT_PYTHON_VERSION
fi

# Install dependencies (needed for building Python)
sudo apt install -y make build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# Install pyenv
curl https://pyenv.run | bash

# Add to your shell
cat >> ~/.zshrc <<'EOF'
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF

# Reload shell config
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Install Python 3.12 (latest)
echo "Installing Python, this may take sometime"
pyenv install $PYTHON_VERSION
pyenv global $PYTHON_VERSION

# Make sure pip is up to date
python -m ensurepip --upgrade
python -m pip install --upgrade pip

# ✅ Install pipx
python -m pip install --user pipx
python -m pipx ensurepath

# Reload path (if needed in current shell)
export PATH="$HOME/.local/bin:$PATH"

# ✅ Use pipx to install virtualenv & poetry
pipx install virtualenv
pipx install poetry

# 🧪 Test
python --version
pipx list
poetry --version
virtualenv --version