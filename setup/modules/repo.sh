normalize_repo_slug() {
    local url="$1"
    echo "$url" | sed -E 's#(git@github.com:|https://github.com/)([^/]+/[^/.]+)(\.git)?#\2#'
}

is_system_repo() {
    local repo_root="$1"
    local remote_url
    remote_url=$(git -C "$repo_root" remote get-url origin 2>/dev/null || echo "")
    local repo_slug
    repo_slug=$(normalize_repo_slug "$remote_url" | tr '[:upper:]' '[:lower:]')

    if [[ "$repo_slug" == "netenebraes/nebspwm-dotfiles" || "$repo_slug" == "netenebraes/nebspwn-dotfiles" ]]; then
        return 0
    fi

    [[ -f "$repo_root/configuracion-del-sistema/setup.sh" && -d "$repo_root/configuracion-del-sistema/SDDM" ]]
}

ensure_repo() {
    echo_msg "Managing dotfiles repo..."
    local tmp_repo="/tmp/neBSPWN-dotfiles"
    local setup_root="${SETUP_ROOT:-}"

    if [[ -z "$setup_root" ]]; then
        local module_dir
        module_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
        setup_root=$(cd "$module_dir/../.." && pwd)
    fi

    local candidates=()
    candidates+=("$(pwd)")
    [[ -n "$setup_root" ]] && candidates+=("$setup_root")

    for candidate in "${candidates[@]}"; do
        if git -C "$candidate" rev-parse --is-inside-work-tree &>/dev/null; then
            local repo_root
            repo_root=$(git -C "$candidate" rev-parse --show-toplevel)
            if is_system_repo "$repo_root"; then
                echo_ok "Local repo detected: $repo_root"
                export NE_TMP_REPO="$repo_root"
                return 0
            fi
        fi
    done

    if [[ -d "$tmp_repo/.git" ]]; then
        if ! is_system_repo "$tmp_repo"; then
            echo_skip "Temp repo mismatch; re-cloning..."
            rm -rf "$tmp_repo"
        fi
    elif [[ -d "$tmp_repo" ]]; then
        echo_skip "Temp directory exists but is not a repo; cleaning..."
        rm -rf "$tmp_repo"
    fi

    if [[ -d "$tmp_repo/.git" ]]; then
        echo_skip "Temp repo already cloned; skipping update."
    else
        echo_msg "Cloning repo to temp..."
        git clone "$DOTFILES_REPO" "$tmp_repo"
    fi

    export NE_TMP_REPO="$tmp_repo"
    echo_ok "Working path: $NE_TMP_REPO"
}
