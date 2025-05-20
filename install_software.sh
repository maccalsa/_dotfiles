# "${BASH_SOURCE[0]}": This variable holds the path to the current script as it was invoked. It could be a relative or absolute path.
# dirname "...": This command extracts the directory part of the path.
# cd "...": This changes the directory to the script's directory.
# &> /dev/null: This suppresses any output from the cd command.
# pwd: This prints the present working directory (which is now the script's actual directory, resolved to an absolute path).
# $(...): This is command substitution, capturing the output of the commands inside.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


### My Pass

 ${SCRIPT_DIR}/installers/install_my_pass.sh

### tmux 

${SCRIPT_DIR}/installers/install_tmux.sh

### Languages

${SCRIPT_DIR}/installers/install_languages.sh

### fzf-git

${SCRIPT_DIR}/installers/install_fzf-git.sh

### install docker

${SCRIPT_DIR}/installers/install_docker.sh

## Install neovim

${SCRIPT_DIR}/installers/install_neovim.sh

echo "💡 Installing your tools"
${SCRIPT_DIR}/installers/install_tools.sh

echo "💡 Installing nix"
${SCRIPT_DIR}/nix/install_nix.sh

echo "💡 Post installation configuration"
${SCRIPT_DIR}/post_install_software.sh



















