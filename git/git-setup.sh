#!/bin/bash

# Script that is used to setup Git user configuration.

USERNAME="PLACEHOLDER_USERNAME"
EMAIL="PLACEHOLDER_EMAIL"

#SIGNINGKEY_CONFIG_START
SIGNINGKEY="PLACEHOLDER_SIGNINGKEY"
#SIGNINGKEY_CONFIG_END

#GPG_COMMIT_CONFIG_START
GPG_COMMIT="PLACEHOLDER_GPG_COMMIT"
#GPG_COMMIT_CONFIG_END

# Set the Git user name
# Use the `--global` flag if you want to set this configuration globally.
git config user.name "$USERNAME"

# Set the Git user email
# Use the `--global` flag if you want to set this configuration globally.
git config user.email "$EMAIL"

#SIGNINGKEY_CONFIG_START
# Set the GPG signing key if the variable is set
# Use the `--global` flag if you want to set this configuration globally.
git config user.signingkey "$SIGNINGKEY"
#SIGNINGKEY_CONFIG_START

#GPG_COMMIT_CONFIG_START
# Enable or disable GPG commit signing if the variable is set
# Use the `--global` flag if you want to set this configuration globally.
git config commit.gpgsign "$GPG_COMMIT"
#GPG_COMMIT_CONFIG_START

# Print the current Git configuration
echo "Git User Name: $(git config user.name)"
echo "Git User Email: $(git config user.email)"

#SIGNINGKEY_CONFIG_START
echo "Git Signing Key: $(git config user.signingkey)"
#SIGNINGKEY_CONFIG_END

#GPG_COMMIT_CONFIG_START
echo "GPG Commit Signing Enabled: $(git config commit.gpgsign)"
#GPG_COMMIT_CONFIG_END

echo "Git user configuration set up successfully!"
