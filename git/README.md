# Git set up & configurations

This directory contains all settings and configurations that are related to the whole Git process.

## Table of Contents

- [Git Configurations Setup](#git-configurations-setup)
- [Usage](#usage)

## Git Configurations Setup

To establish specific configurations such as name, email, and other Git-related parameters on a per-repository basis, without utilizing the `--global` flag, it is essential to recognize that this process can be cumbersome. Neglecting to undertake this configuration procedure may lead to Git prompting the user to amend the most recent commit subsequent to modifying their credentials.

To obviate such occurrences, a script named `git-setup.sh` has been devised to streamline this process automatically.

### `git-setup.sh` Script Details

The `git-setup.sh` script has been enhanced to:

- Conditionally Include Configurations: The script now dynamically includes configurations for `SIGNINGKEY` and `GPG_COMMIT` only if their respective environment variables are set in the `gitconfig.env` file.
- Remove Empty Lines: After processing, the script removes empty lines to ensure a clean and readable output.

## Usage

#### 1. Clone the Repository

Make sure that you cloned the `dotfiles` repo. If not, use the below commands for cloning. If yes, you can skip to [step 2](#2-configure-git-credentials) directly.

```
git clone https://github.com/sleepinzombie/dotfiles.git
cd dotfiles/git
```

#### 2. Configure Git Credentials

Copy the `gitconfig.env.example` file and create your own `gitconfig.env` file:

```
cp gitconfig.env.example gitconfig.env
```

Edit the `gitconfig.env` file with your Git credentials using a text editor of your choice:

```
nano gitconfig.env
```

Update the following keys with your details:

```
USERNAME="Your Name"
EMAIL="your.email@example.com"
SIGNINGKEY="Your signing key"  # Optional: Include if you use a signing key
GPG_COMMIT="true"  # Optional: Set to true or false if you want to enable/disable commit signing
```

Save and close the file.

#### 3. Run the Copy Script

The copy script is used to copy the git-setup.sh file to the home directory with the predefined variables you provided. This copied setup file can then be used in any repository on your local machine to set up Git credentials.

Ensure the script is executable and run it:

```
chmod +x copy-script.sh
./copy-script.sh
```

Note: On Windows, make sure you have [Git Bash](https://gitforwindows.org/) installed to execute the scripts.

#### 4. Set Up Git Credentials

Finally, run the git-setup.sh script in the home directory to set up your Git credentials. You can use this script in any repository on your local machine:

```
~/git-setup.sh
```

Once this setup is completed, you can simply run `git-setup.sh` from any repository to configure Git credentials quickly.
