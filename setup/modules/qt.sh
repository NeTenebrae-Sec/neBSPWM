setup_qt() {
    echo_msg "Configuring Qt environment"

    local kvantum_theme
    kvantum_theme=$(echo "$THEME_DEFAULT" | sed 's|-standard\+.*||' | sed 's|-hdpi||' | sed 's|-xhdpi||')
    echo_msg "GTK '$THEME_DEFAULT' -> Kvantum '$kvantum_theme'"

    if ! pgrep -f "xdg-desktop-portal" >/dev/null; then
        echo_msg "Starting portals..."
        /usr/lib/xdg-desktop-portal & disown
        /usr/lib/xdg-desktop-portal-gtk & disown
    fi

    echo_ok "Qt environment done"
}
