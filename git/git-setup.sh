#!/bin/bash

# Script that is used to setup Git user configuration.

USERNAME="PLACEHOLDER_USERNAME"
EMAIL="PLACEHOLDER_EMAIL"

# Set the Git user name
# Use the `--global` flag if you want to set this configuration globally.
git config user.name "$USERNAME"

# Set the Git user email
# Use the `--global` flag if you want to set this configuration globally.
git config user.email "$EMAIL"

echo "Git user configuration set up successfully!"
