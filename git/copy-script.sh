#!/bin/bash

# Name of the environment variables file
ENV_FILE="gitconfig.env"
# Name of the script to copy
SCRIPT_NAME="git-setup.sh"

# Check if the environment file exists in the current directory
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE does not exist in the current directory."
  exit 1
fi

# Check if the script file exists in the current directory
if [ ! -f "$SCRIPT_NAME" ]; then
  echo "Error: $SCRIPT_NAME does not exist in the current directory."
  exit 1
fi

# Source the environment variables from gitconfig.env
source ./"$ENV_FILE"

# Check if variables are set
if [ -z "$USERNAME" ] || [ -z "$EMAIL" ]; then
  echo "Error: USERNAME and EMAIL must be set in $ENV_FILE"
  exit 1
fi

# Create a temporary script with environment variables set
TEMP_SCRIPT="temp_$SCRIPT_NAME"

# Copy the base script to the temporary file
cp "$SCRIPT_NAME" "$TEMP_SCRIPT"

# Function to apply sed commands with compatibility for both GNU and BSD sed
apply_sed() {
  local file="$1"
  local pattern="$2"
  local replacement="$3"
  if sed --version >/dev/null 2>&1; then
    # GNU sed
    sed -i "s/$pattern/$replacement/g" "$file"
  else
    # BSD sed (macOS)
    sed -i '' "s/$pattern/$replacement/g" "$file"
  fi
}

# Replace placeholders with environment variable values
apply_sed "$TEMP_SCRIPT" "PLACEHOLDER_USERNAME" "$USERNAME"
apply_sed "$TEMP_SCRIPT" "PLACEHOLDER_EMAIL" "$EMAIL"

# Conditionally add signing key configuration if set
if [ -n "$SIGNINGKEY" ]; then
  apply_sed "$TEMP_SCRIPT" "PLACEHOLDER_SIGNINGKEY" "$SIGNINGKEY"
else
  sed -i '' "/#SIGNINGKEY_CONFIG_START/,/#SIGNINGKEY_CONFIG_END/ d" "$TEMP_SCRIPT"
fi

# Conditionally add GPG commit signing configuration if set
if [ -n "$GPG_COMMIT" ]; then
  apply_sed "$TEMP_SCRIPT" "PLACEHOLDER_GPG_COMMIT" "$GPG_COMMIT"
else
  sed -i '' "/#GPG_COMMIT_CONFIG_START/,/#GPG_COMMIT_CONFIG_END/ d" "$TEMP_SCRIPT"
fi

# Determine the home directory (works for Unix-based systems)
HOME_DIR="$HOME"

# Copy the updated script to the home directory
cp "$TEMP_SCRIPT" "$HOME_DIR/$SCRIPT_NAME"

# Set execute permissions on the copied script
chmod +x "$HOME_DIR/$SCRIPT_NAME"

# Clean up the temporary script
rm "$TEMP_SCRIPT"

# Print success message
echo "Script $SCRIPT_NAME with environment variables set has been copied to the home directory."
