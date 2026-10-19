setup_dconf_themes() {
    local themes=(gnome cinnamon mate)
    local dconf_paths=(
        "/org/gnome/desktop/interface/"
        "/org/cinnamon/desktop/interface/"
        "/org/mate/interface/"
    )

    for i in "${!themes[@]}"; do
        local path="${dconf_paths[$i]}"
        dconf_write_if_needed "${path}gtk-theme" "'$THEME_DEFAULT'"
        dconf_write_if_needed "${path}icon-theme" "'$THEME_ICONS'"
        dconf_write_if_needed "${path}cursor-theme" "'$THEME_CURSOR'"
        dconf_write_if_needed "${path}gtk-key-theme" "'Default'"
    done

    dconf_write_if_needed "/org/cinnamon/desktop/wm/preferences/theme" "'$THEME_DEFAULT'"
    dconf_write_if_needed "/org/cinnamon/desktop/wm/preferences/theme-backup" "'$THEME_DEFAULT'"
    dconf_write_if_needed "/org/gnome/desktop/wm/preferences/theme" "'$THEME_DEFAULT'"
    dconf_write_if_needed "/org/gnome/desktop/interface/color-scheme" "'prefer-dark'"
}

setup_papirus_folders() {
    if command -v papirus-folders >/dev/null 2>&1; then
        echo_skip "Papirus-folders already installed"
    else
        wget -qO- https://git.io/papirus-folders-install | sh
    fi
    papirus-folders -C red --theme Papirus-Dark
}

setup_root_gtk_theme() {
    if [[ $EUID -ne 0 ]]; then
        sudo mkdir -p /root/.config/gtk-3.0
        sudo tee /root/.config/gtk-3.0/settings.ini >/dev/null << EOF
[Settings]
gtk-theme-name=$THEME_DEFAULT
gtk-application-prefer-dark-theme=1
EOF
    fi
}

setup_themes() {
    echo_msg "System themes..."

    setup_dconf_themes
    setup_papirus_folders
    setup_root_gtk_theme
    xdg-user-dirs-update

    echo_ok "System themes configured"
}
