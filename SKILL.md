---
name: dotfiles
description: Manage GNU Stow-based dotfiles at ~/dotfiles. Use when user asks to stow/unstow packages, check dotfiles status, add new config packages, fetch skills/MCPs, edit dotfiles, or mentions "/dotfiles". Handles symlink management for configs (claude, ghostty, mise, nvim, starship, zellij, zsh).
---

# Dotfiles

Manage development environment configs via GNU Stow at `~/dotfiles`.

## Commands

Run `scripts/stow.sh` from skill directory:

```bash
./skills/dotfiles/scripts/stow.sh <command> [package]
```

| Command | Purpose |
|---------|---------|
| `status` | Show stow status for all packages |
| `stow <pkg>` | Create symlinks for a package |
| `unstow <pkg>` | Remove symlinks for a package |
| `restow <pkg>` | Refresh symlinks (unstow + stow) |
| `stow-all` | Stow all packages |
| `list` | List available packages |
| `fetch-skills` | Fetch latest skills from GitHub releases |
| `fetch-mcps` | Fetch latest MCP servers from GitHub releases |

## Package Structure

Each package mirrors home directory structure:

```
~/dotfiles/
├── claude/
│   └── .claude/
│       ├── settings.json   → symlinked to ~/.claude/settings.json
│       └── skills/         → symlinked to ~/.claude/skills
├── nvim/
│   └── .config/
│       └── nvim/           → symlinked to ~/.config/nvim
└── zsh/
    ├── .zshenv             → symlinked to ~/.zshenv
    └── .zprofile           → symlinked to ~/.zprofile
```

## Adding a New Package

1. Create package directory: `mkdir -p ~/dotfiles/newpkg/.config/newpkg`
2. Add config files mirroring their home location
3. Stow: `./skills/dotfiles/scripts/stow.sh stow newpkg`
4. Commit: `cd ~/dotfiles && git add . && git commit -m "add newpkg"`

## Editing Configs

Edit files directly in `~/dotfiles/<package>/` - symlinks mean changes apply immediately.

After editing:
```bash
cd ~/dotfiles
git add . && git commit -m "update <package> config"
git push
```

## Fetching Skills and MCPs

Skills and MCP servers are fetched from GitHub releases (not submodules). This keeps dotfiles simple and ensures latest versions.

```bash
# Fetch latest skills
./skills/dotfiles/scripts/stow.sh fetch-skills

# Fetch latest MCP servers
./skills/dotfiles/scripts/stow.sh fetch-mcps
```

Skills without releases use embedded versions from the `claude` package. As repos add release workflows, fetch automatically picks them up.
