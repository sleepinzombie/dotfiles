[CmdletBinding()]
param(
    [switch]$DryRun
)

# Bootstraps a Windows machine: installs git and the GitHub CLI via winget,
# makes sure gh is authenticated, and installs the dotfiles commands into
# ~/.local/bin. Safe to run multiple times.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$rootDir = $PSScriptRoot
$binDir = Join-Path $HOME ".local/bin"

function Test-CommandExists {
    param([Parameter(Mandatory = $true)][string]$CommandName)
    return [bool](Get-Command $CommandName -ErrorAction SilentlyContinue)
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [Parameter(Mandatory = $true)][string]$WingetId
    )

    if (Test-CommandExists $CommandName) {
        Write-Host "[ ok ] $CommandName already installed"
        return
    }

    Write-Host "[info] Installing $CommandName..."
    if ($DryRun) {
        Write-Host "[dry-run] winget install --id $WingetId -e"
        return
    }

    winget install --id $WingetId -e --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "winget failed to install $WingetId."
    }

    # winget updates the persisted PATH only; reload it so gh/git are usable
    # later in this same script without restarting the terminal.
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
        [Environment]::GetEnvironmentVariable("Path", "User")
}

if (-not (Test-CommandExists "winget")) {
    throw "winget was not found. Install 'App Installer' from the Microsoft Store and re-run."
}

Install-WingetPackage -CommandName "git" -WingetId "Git.Git"
Install-WingetPackage -CommandName "gh" -WingetId "GitHub.cli"

# Authentication is skipped on dry runs because gh auth login is interactive.
if (-not $DryRun -and (Test-CommandExists "gh")) {
    gh auth status *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[ ok ] gh is authenticated"
    } else {
        Write-Host "[info] gh is not authenticated, starting login..."
        gh auth login
    }
}

Write-Host "[info] Installing commands into $binDir"
# Copied without the .sh extension so Git for Windows exposes it as `git sync-fork`.
$source = Join-Path $rootDir "git/git-sync-fork.sh"
$target = Join-Path $binDir "git-sync-fork"

if ($DryRun) {
    Write-Host "[dry-run] copy $source -> $target"
} else {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
    Copy-Item -Path $source -Destination $target -Force
}
Write-Host "[ ok ] Installed git-sync-fork (also available as: git sync-fork, requires Git Bash)"

$pruneSource = Join-Path $rootDir "git/git-prune-branches.sh"
$pruneTarget = Join-Path $binDir "git-prune-branches"
if ($DryRun) {
    Write-Host "[dry-run] copy $pruneSource -> $pruneTarget"
} else {
    Copy-Item -Path $pruneSource -Destination $pruneTarget -Force
}
Write-Host "[ ok ] Installed git-prune-branches (also available as: git prune-branches, requires Git Bash)"

# Persist the bin directory on the user PATH (takes effect in new terminals).
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (($userPath -split ";") -notcontains $binDir) {
    if ($DryRun) {
        Write-Host "[dry-run] add $binDir to user PATH"
    } else {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$binDir", "User")
        Write-Host "[ ok ] Added $binDir to your user PATH. Restart your terminal to use it."
    }
}

Write-Host "[ ok ] Setup complete"
