setup_sddm() {
    echo_msg "Setting up SDDM..."

    local THEME_DEST_NAME="netenebrae"
    local THEMES_DIR="/usr/share/sddm/themes"
    local TARGET_DIR="$THEMES_DIR/$THEME_DEST_NAME"
    local METADATA="$TARGET_DIR/metadata.desktop"
    local CLONE_DIR="${NE_TMP_REPO:-/tmp/neBSPWN-dotfiles}"

    # Locate SDDM theme in repo
    local source_path=""

    if [[ -f "$CLONE_DIR/configuracion-del-sistema/SDDM/metadata.desktop" ]]; then
        source_path="$CLONE_DIR/configuracion-del-sistema/SDDM"
    elif [[ -f "$CLONE_DIR/SDDM/metadata.desktop" ]]; then
        source_path="$CLONE_DIR/SDDM"
    else
        local found
        found=$(find "$CLONE_DIR" -type f -name "metadata.desktop" | grep "SDDM" | head -n 1)
        if [[ -n "$found" ]]; then
            source_path=$(dirname "$found")
        else
            echo_err "SDDM theme not found in $CLONE_DIR"
            return 1
        fi
    fi

    echo_ok "Source found: $source_path"

    # Clean install
    if [[ -d "$TARGET_DIR" ]]; then
        echo_msg "Removing previous theme..."
        sudo rm -fr "$TARGET_DIR"
    fi

    sudo mkdir -p "$TARGET_DIR"
    echo_msg "Copying files to $TARGET_DIR..."
    sudo cp -r "$source_path"/* "$TARGET_DIR"/

    # Install fonts
    if [[ -d "$TARGET_DIR/Fonts" ]]; then
        echo_msg "Installing fonts..."
        sudo cp -r "$TARGET_DIR/Fonts"/* /usr/share/fonts/
        fc-cache -f
    fi

    # SDDM base config
    sudo mkdir -p /etc/sddm.conf.d
    echo "[Theme]
Current=$THEME_DEST_NAME" | sudo tee /etc/sddm.conf >/dev/null

    echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf >/dev/null

    # Cursor config
    local cursor_index="[Icon Theme]
Inherits=$THEME_CURSOR_CLEAN"

    sudo tee /etc/sddm.conf.d/10-cursor.conf >/dev/null << EOF
[Theme]
CursorTheme=$THEME_CURSOR_CLEAN
CursorSize=$CURSOR_SIZE_CLEAN
EOF

    sudo mkdir -p /usr/share/icons/default
    echo "$cursor_index" | sudo tee /usr/share/icons/default/index.theme >/dev/null

    sudo mkdir -p /var/lib/sddm/.icons/default
    echo "$cursor_index" | sudo tee /var/lib/sddm/.icons/default/index.theme >/dev/null
    sudo chown -R sddm:sddm /var/lib/sddm/.icons

    # Theme variant selection
    if [[ ! -f "$METADATA" ]]; then
        echo_err "metadata.desktop not found after copy."
        return 1
    fi

    local theme_variant="${NE_THEME_VARIANT:-}"

    if [[ -z "$theme_variant" ]]; then
        echo ""
        echo "Select SDDM theme variant:"
        echo "  [1] rojo  (red)"
        echo "  [2] cyan  (gothic cyan)"
        echo ""
        read -r -p "Choice [1]: " choice
        case "$choice" in
            2|cyan) theme_variant="cyan" ;;
            *)      theme_variant="rojo" ;;
        esac
    fi

    local theme_conf="Themes/netenebrae.conf"
    [[ "$theme_variant" == "cyan" ]] && theme_conf="Themes/netenebrae-cyan.conf"

    if [[ ! -f "$TARGET_DIR/$theme_conf" ]]; then
        echo_err "Config not found: $theme_conf"
        return 1
    fi

    echo_msg "Setting theme: $theme_variant ($theme_conf)"
    sudo sed -i "s|^ConfigFile=.*|ConfigFile=$theme_conf|" "$METADATA"

    # QML compat patch
    local qml_file="$TARGET_DIR/Main.qml"
    if [[ -f "$qml_file" ]]; then
        if ! grep -q "QtQuick 2.15" "$qml_file"; then
             echo_msg "Patching QML imports..."
             sudo sed -i 's/^import QtQuick$/import QtQuick 2.15/' "$qml_file"
             sudo sed -i 's/^import QtQuick.Layouts$/import QtQuick.Layouts 1.15/' "$qml_file"
             sudo sed -i 's/^import QtQuick.Controls$/import QtQuick.Controls 2.15/' "$qml_file"
        fi
    fi

    # Enable service
    if ! systemctl is-enabled sddm &>/dev/null; then
        echo_msg "Enabling SDDM service..."
        sudo systemctl enable sddm
    fi

    echo_ok "SDDM ready"
}
