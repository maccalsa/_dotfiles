curl --proto '=https' -sSf https://www.getada.dev/init.sh | sh

alr --version
gnat --version
gprbuild --version

alr toolchain --select
## check installed 
alr exec -- gnat --version
alr exec -- gprbuild --version

# Add the Alire shim bin dir
echo 'export PATH="$HOME/.local/share/alire/bin:$PATH"' >> ~/.zshrc
# some shells on Linux also read ~/.profile on login; good to add there too
echo 'export PATH="$HOME/.local/share/alire/bin:$PATH"' >> ~/.profile

# reload your shell config
source ~/.zshrc




alr init --bin hello_ada
cd hello_ada
alr build
./bin/hello_ada
