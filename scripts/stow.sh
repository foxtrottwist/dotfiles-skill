#!/bin/bash
# Dotfiles stow management script

set -e

DOTFILES_DIR="$HOME/dotfiles"

usage() {
    echo "Usage: $0 <command> [package]"
    echo ""
    echo "Commands:"
    echo "  status          Show stow status for all packages"
    echo "  stow <pkg>      Stow a package (create symlinks)"
    echo "  unstow <pkg>    Unstow a package (remove symlinks)"
    echo "  restow <pkg>    Restow a package (unstow then stow)"
    echo "  stow-all        Stow all packages"
    echo "  list            List available packages"
    echo "  fetch-skills    Fetch latest skills from GitHub releases"
    echo "  fetch-mcps      Fetch latest MCP servers from GitHub releases"
    exit 1
}

list_packages() {
    cd "$DOTFILES_DIR"
    for pkg in */; do
        echo "${pkg%/}"
    done
}

check_stowed() {
    local pkg="$1"
    local pkg_dir="$DOTFILES_DIR/$pkg"
    local stowed=true

    # Check each file/dir in package
    while IFS= read -r -d '' file; do
        rel="${file#$pkg_dir/}"
        target="$HOME/$rel"

        if [ -L "$target" ]; then
            link_target=$(readlink "$target")
            expected="../dotfiles/$pkg/$rel"
            if [[ "$link_target" != *"dotfiles/$pkg"* ]]; then
                stowed=false
                break
            fi
        elif [ -e "$target" ]; then
            # File exists but not a symlink - conflict
            stowed=false
            break
        else
            stowed=false
            break
        fi
    done < <(find "$pkg_dir" -type f -print0 2>/dev/null)

    echo "$stowed"
}

status_all() {
    echo "=== Dotfiles Status ==="
    echo "Location: $DOTFILES_DIR"
    echo ""

    cd "$DOTFILES_DIR"
    for pkg in */; do
        pkg="${pkg%/}"

        # Count files in package
        file_count=$(find "$DOTFILES_DIR/$pkg" -type f | wc -l | tr -d ' ')

        # Simple check: look for expected symlinks
        if [ "$(check_stowed "$pkg")" = "true" ]; then
            status="[stowed]"
        else
            status="[not stowed]"
        fi

        printf "%-15s %s (%s files)\n" "$pkg" "$status" "$file_count"
    done
}

stow_pkg() {
    local pkg="$1"
    if [ -z "$pkg" ]; then
        echo "Error: package name required"
        exit 1
    fi

    if [ ! -d "$DOTFILES_DIR/$pkg" ]; then
        echo "Error: package '$pkg' not found in $DOTFILES_DIR"
        exit 1
    fi

    cd "$DOTFILES_DIR"
    stow "$pkg"
    echo "Stowed: $pkg"
}

unstow_pkg() {
    local pkg="$1"
    if [ -z "$pkg" ]; then
        echo "Error: package name required"
        exit 1
    fi

    cd "$DOTFILES_DIR"
    stow -D "$pkg"
    echo "Unstowed: $pkg"
}

restow_pkg() {
    local pkg="$1"
    if [ -z "$pkg" ]; then
        echo "Error: package name required"
        exit 1
    fi

    cd "$DOTFILES_DIR"
    stow -R "$pkg"
    echo "Restowed: $pkg"
}

stow_all() {
    cd "$DOTFILES_DIR"
    for pkg in */; do
        pkg="${pkg%/}"
        stow "$pkg"
        echo "Stowed: $pkg"
    done
}

# Download latest release asset from GitHub
download_release_asset() {
    local repo="$1"
    local pattern="$2"
    local output_dir="$3"

    local api_url="https://api.github.com/repos/$repo/releases/latest"
    local release_json=$(curl -sf "$api_url" 2>/dev/null) || return 1

    local regex_pattern=$(echo "$pattern" | sed 's/\*/.*/g')
    local asset_url=$(echo "$release_json" | grep -o '"browser_download_url": *"[^"]*"' | \
        grep -E "$regex_pattern" | head -1 | sed 's/.*"browser_download_url": *"\([^"]*\)".*/\1/')

    [[ -z "$asset_url" ]] && return 1

    local filename=$(basename "$asset_url")
    curl -sfL "$asset_url" -o "$output_dir/$filename" 2>/dev/null || return 1
    echo "$output_dir/$filename"
}

fetch_skills() {
    echo "Fetching skills from GitHub releases..."

    local skills=(
        "foxtrottwist/iterative-development"
        "foxtrottwist/Iterative-work"
        "foxtrottwist/code-audit"
        "foxtrottwist/chat-migration"
        "foxtrottwist/dotfiles-skill"
        "foxtrottwist/prompt-dev"
        "foxtrottwist/submodule-sync"
        "foxtrottwist/job-apply"
        "foxtrottwist/write"
    )

    local tmp_dir=$(mktemp -d)
    local skills_dir="$HOME/.claude/skills"
    mkdir -p "$skills_dir"

    for repo in "${skills[@]}"; do
        local name=$(basename "$repo")
        local skill_file=$(download_release_asset "$repo" "*.skill" "$tmp_dir")
        if [[ -f "$skill_file" ]]; then
            unzip -o -q "$skill_file" -d "$skills_dir"
            rm -f "$skill_file"
            echo "[OK] Fetched: $name"
        else
            echo "[SKIP] No release: $name"
        fi
    done

    rm -rf "$tmp_dir"
}

fetch_mcps() {
    echo "Fetching MCP servers from GitHub releases..."

    local tmp_dir=$(mktemp -d)
    local mcp_dir="$HOME/.claude/mcps"
    mkdir -p "$mcp_dir"

    local mcpb_file=$(download_release_asset "foxtrottwist/shortcuts-mcp" "*.mcpb" "$tmp_dir")
    if [[ -f "$mcpb_file" ]]; then
        unzip -o -q "$mcpb_file" -d "$mcp_dir/shortcuts-mcp"
        echo "[OK] Fetched: shortcuts-mcp"

        if command -v claude &>/dev/null; then
            claude mcp add -s user --transport stdio shortcuts-mcp -- node "$mcp_dir/shortcuts-mcp/dist/server.js" 2>/dev/null || true
        fi
    else
        echo "[SKIP] No release: shortcuts-mcp"
    fi

    rm -rf "$tmp_dir"
}

case "${1:-}" in
    status) status_all ;;
    stow) stow_pkg "$2" ;;
    unstow) unstow_pkg "$2" ;;
    restow) restow_pkg "$2" ;;
    stow-all) stow_all ;;
    list) list_packages ;;
    fetch-skills) fetch_skills ;;
    fetch-mcps) fetch_mcps ;;
    *) usage ;;
esac
