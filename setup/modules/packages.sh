install_pacman_packages() {
    echo_msg "Installing packages (pacman)..."
    sudo pacman -S --needed --noconfirm "${PKGS_PACMAN_ESSENTIALS[@]}"

    read -r -p "Install optional pacman packages? (${PKGS_PACMAN_OPTIONALS[*]}) (y/N): " resp_p || true
    if [[ "$resp_p" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        sudo pacman -S --needed --noconfirm "${PKGS_PACMAN_OPTIONALS[@]}"
    else
        echo_skip "Optional pacman packages skipped."
    fi
}

install_aur_packages() {
    echo_msg "Installing packages (AUR) with $AUR_HELPER..."
    "$AUR_HELPER" -S --needed --noconfirm "${PKGS_AUR[@]}"

    read -r -p "Install optional AUR packages? (${PKGS_AUR_OPTIONALS[*]}) (y/N): " resp_a || true
    if [[ "$resp_a" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        "$AUR_HELPER" -S --needed --noconfirm "${PKGS_AUR_OPTIONALS[@]}"
    else
        echo_skip "Optional AUR packages skipped."
    fi
}
