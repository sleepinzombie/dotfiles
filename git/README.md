# Git set up & configurations

This directory contains all settings and configurations that are related to the whole Git process.

## Table of Contents

- [Git Configurations Setup](#git-configurations-setup)

## Git Configurations Setup

To establish specific configurations such as name, email, and other Git-related parameters on a per-repository basis, without utilizing the `--global` flag, it is essential to recognize that this process can be cumbersome. Neglecting to undertake this configuration procedure may lead to Git prompting the user to amend the most recent commit subsequent to modifying their credentials.

To obviate such occurrences, a script named `git-setup.sh` has been devised to streamline this process automatically.

To execute the script, adhere to the following steps:

### Linux and macOS

1. Ensure the `git-setup.sh` file is downloaded onto your system, preferably within the `home/yourusername` directory.
2. Modify the credentials within the `git-setup.sh` file to align with your own.
3. Execute the following script to render it executable:
   ```
   chmod +x git-setup.sh
   ```
4. Subsequently, to establish your Git configuration, execute the script by entering:
   ```
   ./git-setup.sh
   ```

### Windows

1. Make sure you have Git for Windows installed on your system.
2. Ensure the `git-setup.sh` file is downloaded onto your system, preferably within the `C:\Users\YourUsername` directory.
3. Modify the credentials within the `git-setup.sh` file to align with your own.
4. Open Git Bash terminal.
5. Navigate to the directory where your script is located using the `cd` command.
6. Run the script by typing:
   ```
   ./git-setup.sh
   ```
