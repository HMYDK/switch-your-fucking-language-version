# DevManager

DevManager is a native macOS runtime manager for **Java / Node.js / Python / Go**.  
It gives you a single UI to discover installed runtimes, switch between them, and wire the selected version into your shell.

## Features

- **Native macOS UI**
  - Built with SwiftUI, using NavigationSplitView + Table.
  - Resizable window with a sidebar for languages and a detail pane with rich tables.

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

