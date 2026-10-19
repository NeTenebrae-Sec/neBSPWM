#!/bin/bash

# =============================================================================
# neBSPWN System Setup
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$SCRIPT_DIR/setup"
export SETUP_ROOT="$SCRIPT_DIR"

source "$SETUP_DIR/lib/helpers.sh"

source "$SETUP_DIR/config/themes.sh"
source "$SETUP_DIR/config/packages.sh"

source "$SETUP_DIR/modules/packages.sh"
source "$SETUP_DIR/modules/repo.sh"
source "$SETUP_DIR/modules/defaults.sh"
source "$SETUP_DIR/modules/themes.sh"
source "$SETUP_DIR/modules/zsh.sh"
source "$SETUP_DIR/modules/qt.sh"
source "$SETUP_DIR/modules/sddm.sh"
source "$SETUP_DIR/modules/fonts.sh"

main() {
    [ "$EUID" -eq 0 ] && { echo "[ERR] Do not run as root"; exit 1; }

    echo_msg "neBSPWN System Setup $(date +'%H:%M')"

    check_internet
    ensure_aur_helper
    install_pacman_packages
    install_aur_packages

    ensure_repo

    setup_themes
    setup_defaults
    setup_zsh
    setup_qt
    setup_sddm
    setup_fonts_locale
    cleanup_temp_repo

    echo_ok "DONE! Reboot: systemctl reboot"
}

main "$@"
