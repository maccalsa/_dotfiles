# Install SDKMAN
curl -s "https://get.sdkman.io" | bash

# Load SDKMAN (for this script session)
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Install Java 21 (Graal)
sdk install java 21.0.2-graalce
sdk default java 21.0.2-graalce

# Install Kotlin
sdk install kotlin