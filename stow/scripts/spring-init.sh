#!/usr/bin/env bash

# ----- Common Spring Starters -----
declare -A STARTERS=(
  [1]="webflux"
  [2]="spring-data-r2dbc"
  [3]="r2dbc-postgresql"
  [4]="data-jpa"
  [5]="security"
  [6]="validation"
  [7]="configuration-processor"
  [8]="actuator"
  [9]="lombok"
  [10]="devtools"
)
declare -A STARTER_NAMES=(
  [1]="Spring WebFlux"
  [2]="Spring Data R2DBC"
  [3]="R2DBC PostgreSQL"
  [4]="Spring Data JPA"
  [5]="Spring Security"
  [6]="Validation"
  [7]="Configuration Processor"
  [8]="Actuator"
  [9]="Lombok"
  [10]="DevTools"
)

# ----- Project Name -----
while [[ -z "$PROJECT_NAME" ]]; do
  read -rp "Project name (required): " PROJECT_NAME
done

# Language
read -rp "Language [kotlin]: " LANGUAGE
LANGUAGE="${LANGUAGE:-kotlin}"

# Gradle build type (kotlin-dsl or groovy)
echo "Gradle build type:"
echo "  1. Kotlin DSL (.kts) [default]"
echo "  2. Groovy (.gradle)"
read -rp "Select build type [1]: " BUILD_TYPE_CHOICE
BUILD_TYPE_CHOICE="${BUILD_TYPE_CHOICE:-1}"

if [[ "$BUILD_TYPE_CHOICE" == "2" ]]; then
  GRADLE_TYPE="gradle-project"
else
  GRADLE_TYPE="gradle-project-kotlin"
fi

# ----- Dependency selection -----
echo "Select dependencies to include (comma-separated numbers, e.g. 1,2,5):"
for i in $(seq 1 ${#STARTERS[@]}); do
  printf "%2d. %s\n" "$i" "${STARTER_NAMES[$i]}"
done
read -rp "Selection [1]: " SELECTION
SELECTION="${SELECTION:-1}"

DEPENDENCIES=""
IFS=',' read -ra CHOICES <<< "$SELECTION"
for CHOICE in "${CHOICES[@]}"; do
  DEP="${STARTERS[${CHOICE// /}]}"
  [[ -n "$DEP" ]] && DEPENDENCIES+="${DEP},"
done

# ----- Custom dependencies -----
read -rp "Any custom dependencies (comma separated, press ENTER to skip): " CUSTOM_DEPS
CUSTOM_DEPS="${CUSTOM_DEPS// /}" # Remove spaces

if [[ -n "$CUSTOM_DEPS" ]]; then
  DEPENDENCIES+="${CUSTOM_DEPS},"
fi

DEPENDENCIES="${DEPENDENCIES%,}"  # Remove trailing comma

if [[ -z "$DEPENDENCIES" ]]; then
  DEPENDENCIES="webflux"
fi

# Boot version
read -rp "Spring Boot version [3.5.0]: " BOOT_VERSION
BOOT_VERSION="${BOOT_VERSION:-3.5.0}"

# Package name (default to com.example.${PROJECT_NAME// /})
DEFAULT_PACKAGE="com.example.${PROJECT_NAME// /}"
read -rp "Base package [$DEFAULT_PACKAGE]: " PACKAGE_NAME
PACKAGE_NAME="${PACKAGE_NAME:-$DEFAULT_PACKAGE}"

# ----- REVIEW -----
echo ""
echo "======================================"
echo "         Project Review"
echo "======================================"
echo "Project Name:       $PROJECT_NAME"
echo "Language:           $LANGUAGE"
echo "Spring Boot:        $BOOT_VERSION"
echo "Base Package:       $PACKAGE_NAME"
echo "Dependencies:       $DEPENDENCIES"
echo "======================================"
echo ""
read -rp "Proceed with project creation? [y/N]: " CONFIRM
CONFIRM="${CONFIRM:-N}"

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo "Generating Spring project..."
curl -s https://start.spring.io/starter.zip \
  -d "language=$LANGUAGE" \
  -d "dependencies=$DEPENDENCIES" \
  -d "type=$GRADLE_TYPE" \
  -d "bootVersion=$BOOT_VERSION" \
  -d "baseDir=$PROJECT_NAME" \
  -d "packageName=$PACKAGE_NAME" \
  -o "${PROJECT_NAME}.zip"

echo "Unzipping project..."
unzip -q "${PROJECT_NAME}.zip"
cd "$PROJECT_NAME" || exit 1

# Open in preferred editor
if command -v code &>/dev/null; then
  code .
elif command -v idea &>/dev/null; then
  idea .
elif command -v cursor &>/dev/null; then
  cursor .
elif command -v nvim &>/dev/null; then
  nvim .
else
  echo "Project ready in $(pwd). Open in your favorite editor!"
fi

