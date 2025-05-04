DEFAULT_GO_VERSION="1.22.2"

# What version of go? ask user if none supplied use GO_VERSION
read -p "Enter the version of go you want to install (default: $DEFAULT_GO_VERSION): " GO_VERSION   
if [ -z "$GO_VERSION" ]; then
  GO_VERSION=$DEFAULT_GO_VERSION
fi

curl -OL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"

# Add to PATH (you can add this in ~/.zshrc too)
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.zshrc
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Make sure Go is working
go version

# Wire (from Google)
go install github.com/google/wire/cmd/wire@latest

# Templ (fast templating engine)
go install github.com/a-h/templ/cmd/templ@latest

# Air (live-reload for Go projects)
go install github.com/cosmtrek/air@latest

wire help
templ version
air --version