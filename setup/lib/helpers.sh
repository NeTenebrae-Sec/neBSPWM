echo_msg()   { echo -e "\n\033[1;34m[INFO] $1\033[0m"; }
echo_ok()    { echo -e "\033[1;32m[ OK ] $1\033[0m"; }
echo_skip()  { echo -e "\033[1;33m[SKIP] $1\033[0m"; }
echo_err()   { echo -e "\033[0;31m[ ERR] $1\033[0m" >&2; }

dconf_write_if_needed() {
    local key="$1"
    local value="$2"

    local current_val
    current_val=$(dconf read "$key" 2>/dev/null | sed "s/^'//;s/'$//" || echo "")

    local clean_value
    clean_value=$(echo "$value" | sed "s/^'//;s/'$//")

    if [[ "$current_val" != "$clean_value" ]]; then
        dconf write "$key" "$value"
        echo_ok "dconf: $key -> $value"
    else
        echo_skip "dconf OK: $key"
    fi
}

check_internet() {
    echo_msg "Checking internet connection..."
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        echo_err "No internet connection. Aborting."
        exit 1
    fi
    echo_ok "Connection active"
    echo_msg "Updating system"
    sudo pacman -Syu --noconfirm
}

ensure_aur_helper() {
    local helpers=("yay-bin" "paru" "yay")
    AUR_HELPER=""

    for h in "paru" "yay"; do
        if command -v "$h" >/dev/null; then
            AUR_HELPER="$h"
            break
        fi
    done

    if [[ -n "$AUR_HELPER" ]]; then
        echo_ok "Detected '$AUR_HELPER' installed."
        read -r -p "Keep using $AUR_HELPER? [Y/n]: " keep_existing
        [[ "$keep_existing" =~ ^([nN][oO]|[nN])$ ]] && AUR_HELPER=""
    fi

    if [[ -z "$AUR_HELPER" ]]; then
        echo -e "\n--- AUR Helper Installation ---"
        PS3="Select AUR helper: "
        select opt in "${helpers[@]}" "Cancel"; do
            case $opt in
                "yay-bin"|"paru"|"yay")
                    for old in "paru" "yay"; do
                        if command -v "$old" >/dev/null; then
                            echo_msg "Removing old $old..."
                            sudo pacman -Rs --noconfirm "$old"
                        fi
                    done

                    echo_msg "Installing $opt..."
                    sudo pacman -S --needed --noconfirm base-devel git

                    local build_dir
                    build_dir=$(mktemp -d)
                    git clone "https://aur.archlinux.org/$opt.git" "$build_dir"
                    (cd "$build_dir" && makepkg -si --noconfirm)
                    rm -rf "$build_dir"

                    AUR_HELPER="${opt%-bin}"
                    break
                    ;;
                "Cancel")
                    echo_err "No AUR helper selected. Exiting..."
                    exit 1
                    ;;
                *) echo "Invalid option";;
            esac
        done
    fi

    export AUR_HELPER
    echo_ok "Using $AUR_HELPER for installation."
}

cleanup_temp_repo() {
    if [[ -n "${NE_TMP_REPO:-}" && -d "$NE_TMP_REPO" ]]; then
        echo -e "\nDelete temp repo? ($NE_TMP_REPO)"
        echo "   (y/N)"
        read -r -p " > " delete_repo
        if [[ "$delete_repo" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            rm -rf "$NE_TMP_REPO"
            echo_ok "Temp repo deleted"
        else
            echo_skip "Keeping temp repo: $NE_TMP_REPO"
        fi
    fi
}
