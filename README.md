# DevManager

DevManager is a native macOS runtime manager for **Java / Node.js / Python / Go**.  
It gives you a single UI to discover installed runtimes, switch between them, and wire the selected version into your shell.

## Features

- **Native macOS UI**
  - Built with SwiftUI, using NavigationSplitView + Table.
  - Resizable window with a sidebar for languages and a detail pane with rich tables.
  - Modern card-based version display with official language icons.

- **Version Install/Uninstall** (via Homebrew)
  - Install new versions directly from Homebrew without leaving the app.
  - **Dynamic version discovery**: Automatically queries Homebrew for all available versions using `brew search`.
  - Supported languages:
    - **Node.js**: `node`, `node@18`, `node@20`, `node@22`, `node@24`, etc.
    - **Java**: `openjdk`, `openjdk@8`, `openjdk@11`, `openjdk@17`, `openjdk@21`, etc.
    - **Python**: `python@3.9`, `python@3.10`, `python@3.11`, `python@3.12`, `python@3.13`, `python@3.14`, etc.
    - **Go**: `go`, `go@1.20`, `go@1.21`, `go@1.22`, `go@1.23`, `go@1.24`, etc.
  - New versions are automatically available when Homebrew adds them.
  - Real-time download progress display.
  - Uninstall installed Homebrew versions with one click.
  - Homebrew-installed versions are marked with a 🍺 badge in the list.

- **Java**
  - Discovers JDKs via `/usr/libexec/java_home -X`.
  - Writes `JAVA_HOME` and prepends `"$JAVA_HOME/bin"` to `PATH` via `java_env.sh`.

- **Node.js**
  - Scans Homebrew (`/opt/homebrew/Cellar/node`, `/usr/local/Cellar/node`) and NVM (`~/.nvm/versions/node`).
  - Uses `node_env.sh` to prepend the selected Node’s `bin` directory to `PATH`.

- **Python**
  - Supports Homebrew, pyenv (`~/.pyenv/versions`), and asdf (`~/.asdf/installs/python`).
  - Detects the current system `python3` via `/usr/bin/env python3`.
  - Writes `python_env.sh` that prepends the chosen Python’s `bin` to `PATH`.

- **Go**
  - Supports Homebrew, gvm (`~/.gvm/gos`), and asdf (`~/.asdf/installs/golang`).
  - Detects the current system `go` and `GOROOT` via `go version` and `go env GOROOT`.
  - Writes `go_env.sh` that sets `GOROOT` and prepends `"$GOROOT/bin"` to `PATH`.

- **Consistent interaction**
  - Sidebar to choose language; table lists all detected versions.
  - The active version is pinned to the top and marked as **Current**.
  - Each row exposes **Use** and **Open in Finder** actions, plus a context menu (copy path, reveal in Finder, etc.).

- **Shell integration**
  - DevManager never mutates your shell config directly.
  - For each language it generates a small `*_env.sh` script under `~/.config/devmanager/`.
  - Your shell just sources those files once; the app updates them when you switch versions.

## Requirements

- macOS 13.0 or later  
- Swift 5.9+
- Homebrew (optional, required for Install/Uninstall feature)

## How to Run

1. Build:

   ```bash
   swift build
   ```

2. Run:

   ```bash
   swift run
   ```

## Shell Setup (one‑time)

To make version selection effective in your terminal, add the following lines to your shell configuration file  
(for example `~/.zshrc` or `~/.bash_profile`):

```bash
# Java
[ -f ~/.config/devmanager/java_env.sh ] && source ~/.config/devmanager/java_env.sh

# Node.js
[ -f ~/.config/devmanager/node_env.sh ] && source ~/.config/devmanager/node_env.sh

# Python
[ -f ~/.config/devmanager/python_env.sh ] && source ~/.config/devmanager/python_env.sh

# Go
[ -f ~/.config/devmanager/go_env.sh ] && source ~/.config/devmanager/go_env.sh
```

Then reload your shell:

```bash
source ~/.zshrc
```

or simply open a new terminal window.

From then on, whenever you click **Use** for a version in DevManager, the corresponding `*_env.sh` file is updated and new shell sessions will use the selected version for `java`, `node`, `python3`, `go`, etc.

