#!/bin/bash

# Script that is used to setup Git user configuration.

# These values should be replaced with the user configurations.
USERNAME="Your username"
EMAIL="your.email@example.com"

# We set the Git user name
# This is not meant for global set up, but in case we want this to setup as global,
# we can use the `--global` flag.
git config user.name "$USERNAME"

# We set the Git user email
# This is not meant for global set up, but in case we want this to setup as global,
# we can use the `--global` flag.
git config user.email "$EMAIL"

echo "Git user configuration set up successfully!"