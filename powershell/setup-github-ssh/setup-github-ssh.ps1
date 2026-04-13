Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

param(
    [ValidatePattern('^[^@\s]+@[^@\s]+\.[^@\s]+$')]
    [string]$Email = "your_email@example.com",
    [ValidateNotNullOrEmpty()]
    [string]$Name = "Your Name",
    [ValidateNotNullOrEmpty()]
    [string]$KeyPath = (Join-Path $HOME ".ssh/id_ed25519"),
    [switch]$SkipGitIdentity
)

function Assert-CommandExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        throw "Required command '$CommandName' was not found in PATH."
    }
}

Assert-CommandExists -CommandName "git"
Assert-CommandExists -CommandName "ssh-keygen"
Assert-CommandExists -CommandName "ssh-add"

$sshDir = Split-Path -Path $KeyPath -Parent
$pubKeyPath = "${KeyPath}.pub"
$allowedSigners = Join-Path $sshDir "allowed_signers"

# Ensure .ssh exists
if (!(Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

# Generate key if missing, or recover missing .pub from private key
if (!(Test-Path $KeyPath)) {
    ssh-keygen -t ed25519 -C $Email -f $KeyPath
} elseif (!(Test-Path $pubKeyPath)) {
    ssh-keygen -y -f $KeyPath | Set-Content -Path $pubKeyPath -NoNewline
}

# Try to start ssh-agent
$sshAgentService = Get-Service -Name ssh-agent -ErrorAction SilentlyContinue
if ($null -ne $sshAgentService) {
    try {
        if ($sshAgentService.StartType -eq 'Disabled') {
            Set-Service -Name ssh-agent -StartupType Manual
        }

        if ($sshAgentService.Status -ne 'Running') {
            Start-Service ssh-agent
        }

        ssh-add $KeyPath | Out-Null
        ssh-add -l | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "ssh-agent is running and the key is loaded."
        } else {
            Write-Warning "ssh-agent is running, but the key could not be verified with 'ssh-add -l'."
        }
    } catch {
        Write-Warning "ssh-agent could not be fully configured automatically. Run: Start-Service ssh-agent; ssh-add $KeyPath"
    }
} else {
    Write-Warning "ssh-agent service was not found. You can still use the key directly."
}

# Git identity
if (-not $SkipGitIdentity) {
    git config --global user.name "$Name"
    git config --global user.email "$Email"
}

# SSH commit signing
git config --global gpg.format ssh
git config --global user.signingkey $pubKeyPath
git config --global commit.gpgsign true
git config --global gpg.ssh.allowedSignersFile $allowedSigners

# Ensure allowed_signers contains this signer entry
$pubKey = (Get-Content $pubKeyPath -Raw).Trim()
$allowedLine = "$Email $pubKey"

$existingSigners = @()
if (Test-Path $allowedSigners) {
    $existingSigners = Get-Content $allowedSigners | Where-Object { $_.Trim() -ne "" }
}

if ($existingSigners -notcontains $allowedLine) {
    Add-Content -Path $allowedSigners -Value $allowedLine
}

# Copy public key for GitHub
$clipboardMessage = ""
try {
    Get-Content $pubKeyPath | Set-Clipboard
    $clipboardMessage = "Public key copied to clipboard."
} catch {
    $clipboardMessage = "Public key could not be copied to clipboard in this session."
}

Write-Host ""
Write-Host "Setup complete."
Write-Host "$clipboardMessage Paste it into GitHub as an Authentication Key and/or Signing Key."
Write-Host "Public key: $pubKeyPath"
Write-Host "Allowed signers: $allowedSigners"
Write-Host "Test with: ssh -T git@github.com"