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
sed "s/PLACEHOLDER_USERNAME/$USERNAME/; s/PLACEHOLDER_EMAIL/$EMAIL/" "$SCRIPT_NAME" > "$TEMP_SCRIPT"

# Determine the home directory based on the OS
if [ "$OS" == "Windows_NT" ]; then
  HOME_DIR="$HOME"
else
  HOME_DIR="$HOME"
fi

# Copy the updated script to the home directory
cp "$TEMP_SCRIPT" "$HOME_DIR/$SCRIPT_NAME"

# Set execute permissions on the copied script
chmod +x "$HOME_DIR/$SCRIPT_NAME"

# Clean up the temporary script
rm "$TEMP_SCRIPT"

# Print success message
echo "Script $SCRIPT_NAME with environment variables set has been copied to the home directory."
