# GitHub SSH Bootstrap for Windows

This directory contains a PowerShell script to quickly set up GitHub SSH access and SSH-based commit signing on a new Windows machine.

---

## Overview

Setting up SSH and commit signing on Windows can be repetitive and error-prone.  
This script automates the full process so you can get up and running quickly on a new machine.

It is especially useful when:

- Setting up a new development laptop
- Reinstalling Windows
- Standardizing developer onboarding

---

## What the script does

The script performs the following steps:

### SSH Setup

- Creates an SSH key (`ed25519`) if one does not already exist
- Ensures the `.ssh` directory exists
- Recovers a missing public key (`.pub`) from an existing private key
- Attempts to start and configure the `ssh-agent` service
- Adds the SSH key to the agent and verifies it is loaded (when agent is available)

### Git Configuration

- Validates required commands (`git`, `ssh-keygen`, `ssh-add`) before proceeding
- Sets Git user identity (`user.name`, `user.email`) unless `-SkipGitIdentity` is provided
- Configures Git to use SSH for commit signing:
  - `gpg.format ssh`
  - `commit.gpgsign true`
- Sets the SSH public key as the signing key

### Commit Signing Support

- Ensures an `allowed_signers` file exists
- Registers it with Git (`gpg.ssh.allowedSignersFile`)
- Adds signer entries idempotently (does not duplicate the same signer line)
- Ensures commits can be verified locally

### Developer Convenience

- Tries to copy the public SSH key to the clipboard with a safe fallback message if clipboard access is unavailable
- Reduces manual setup steps

---

## Prerequisites

Make sure the following are installed:

- **Git for Windows**
- **OpenSSH (comes with Windows 11)**
- **PowerShell (default on Windows 11)**

Optional:

- **VS Code** (for editing scripts)

---

## How to use it

### 1. Clone the repository

```powershell
git clone git@github.com:your-username/your-repo.git
cd your-repo
```

### 2. Navigate to the script directory

```powershell
cd path\to\this\directory
```

### 3. Run the script

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-github-ssh.ps1 -Email "you@example.com" -Name "Your Name"
```

### 4. Optional parameters

#### Script parameters

| Parameter          | Type     | Default                  | Description                                                                                |
| ------------------ | -------- | ------------------------ | ------------------------------------------------------------------------------------------ |
| `-Email`           | `string` | `your_email@example.com` | Email used for SSH key comment and signer entry. Must look like a valid email format.      |
| `-Name`            | `string` | `Your Name`              | Git global `user.name` (unless `-SkipGitIdentity` is used).                                |
| `-KeyPath`         | `string` | `$HOME\.ssh\id_ed25519`  | Full path to the private SSH key to create/use. Public key is expected at `<KeyPath>.pub`. |
| `-SkipGitIdentity` | `switch` | `false`                  | Skip setting global `user.name` and `user.email`.                                          |

Examples:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-github-ssh.ps1 -Email "you@example.com" -Name "Your Name" -KeyPath "$HOME\.ssh\id_work_ed25519"
```

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-github-ssh.ps1 -Email "you@example.com" -Name "Your Name" -SkipGitIdentity
```

---

## After running the script

### 1. Add your SSH key to GitHub

Go to:  
https://github.com/settings/keys

Add your key:

- As an **Authentication key** → required for cloning/pushing
- As a **Signing key** → enables commit verification (recommended)

The script attempts to copy your public key to your clipboard. If clipboard access is unavailable, it still prints the key path so you can copy it manually.

---

### 2. Test SSH authentication

```powershell
ssh -T git@github.com
```

Expected output:

```
Hi username! You've successfully authenticated...
```

---

### 3. Test commit signing

Create a test commit:

```powershell
git commit -m "Test signed commit"
```

Verify the signature:

```powershell
git log --show-signature -1
```

Expected output:

```
Good "git" signature with ED25519 key
```

---

### 4. Verify on GitHub

Push your commit and check it on GitHub:

- Your commit should display: **Verified ✅**

---

## Expected files

After running the script, the following files should exist:

```
C:\Users\<YourUser>\.ssh
```

- `id_ed25519` → private SSH key
- `id_ed25519.pub` → public SSH key
- `allowed_signers` → trusted signers file

---

## What can be improved

Future improvements for this script:

- Support multiple SSH identities (work vs personal)
- Add interactive prompts instead of CLI arguments
- Add automated validation:
  - SSH connectivity test
  - Signing verification test
- Add a cleanup/reset script
- Add logging for troubleshooting

---

## Notes & Troubleshooting

### SSH issues

If this fails:

```powershell
ssh -T git@github.com
```

Check:

- SSH key is added to GitHub
- You are using SSH URLs (not HTTPS)
- Network/firewall restrictions

---

### ssh-agent issues (Windows)

- The `ssh-agent` service may fail to start
- The script checks for the `ssh-agent` service and continues with a warning if it is unavailable
- This is not critical unless you use a passphrase
- The script continues even if the agent is unavailable

---

### Commit signing not working

If commits are not marked as **Verified**:

- Ensure key is added as a **Signing key** in GitHub
- Check `allowed_signers` file exists and is valid
- Verify Git config:

```powershell
git config --global gpg.format ssh
git config --global commit.gpgsign true
```

---

### Security note

- **Never share your private key (`id_ed25519`)**
- Only share your public key (`id_ed25519.pub`)

---

## Summary

This script helps you go from a fresh Windows machine to:

- Working SSH access to GitHub
- Signed and verified commits
- Minimal manual setup

Ideal for quickly bootstrapping a development environment.
