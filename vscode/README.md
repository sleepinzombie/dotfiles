# VS Code Extensions and Settings

This directory contains all extensions and settings that are configured in Visual Studio Code.
To be able to use the `settings.json`, make sure to install the prerequisites extensions and fonts first.

## Table of Contents

- [Extensions](#extensions)
- [Fonts](#fonts)
- [Installing Extensions](#installation-of-extensions)

## Extensions

Below is a list of the required extensions that have to be installed to prevent errors when using the `settings.json`.

Instructions on how to install these extensions directly using a command is shared [below](#installation-of-extensions).

- [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint) - Integrates ESLint JavaScript into VS Code.
- [Prettier for VS Code](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) - Code formatter using Prettier.
- [PHP Intelephense](https://marketplace.visualstudio.com/items?itemName=bmewburn.vscode-intelephense-client) - PHP code intelligence in VS Code.
- [Nasc VS Code Touchbar](https://marketplace.visualstudio.com/items?itemName=felipe.nasc-touchbar) - Adds useful tools and shortcuts to your MacBook Touchbar (necessary only if using a MacBook with Touchbar support).
- [Todo Tree](https://marketplace.visualstudio.com/items?itemName=Gruntfuggly.todo-tree) - Show TODO, FIXME, etc. comment tags in a tree view.
- [VS Code Intellicode](https://marketplace.visualstudio.com/items?itemName=VisualStudioExptTeam.vscodeintellicode) - AI-assisted development for Python, JavaScript/TypeScript and others.

## Fonts

Below is a list of the required fonts that have to be installed to prevent errors when using the `settings.json`.

- [Cascadia Code](https://github.com/microsoft/cascadia-code)
- [Fire Code](https://github.com/tonsky/FiraCode)

## Installation of Extensions

Make sure that we are in the right directory before running the below command.
The command will go through each extension in the list and install one by one.

### Linux and macOS

```
cat extensions.txt | xargs -n 1 code --install-extension
```

### Windows (using PowerShell)

```
Get-Content extensions.txt | ForEach-Object { code --install-extension $_ }
```
