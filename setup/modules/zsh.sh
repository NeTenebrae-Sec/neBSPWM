setup_zsh() {
    echo_msg "Setting up ZSH + Starship..."
    local zsh_path="/usr/bin/zsh"

    if ! command -v starship >/dev/null 2>&1; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
        echo_ok "Starship installed"
    else
        echo_skip "Starship already installed"
    fi

    if [[ "$SHELL" != "$zsh_path" ]]; then
        chsh -s "$zsh_path"
        echo_ok "ZSH set for $USER"
    fi

    local root_shell
    root_shell=$(getent passwd root | cut -d: -f7)
    if [[ "$root_shell" != "$zsh_path" ]]; then
        if grep -qx "$zsh_path" /etc/shells; then
            sudo chsh -s "$zsh_path" root || sudo usermod -s "$zsh_path" root
            echo_ok "ZSH set for root"
        else
            echo_err "ZSH not in /etc/shells: $zsh_path"
        fi
    else
        echo_skip "ZSH already set for root"
    fi

    echo 'export ZDOTDIR="$HOME/.config/zsh"' | sudo tee -a /etc/zsh/zshenv

    echo_ok "ZSH and Starship ready"
}
