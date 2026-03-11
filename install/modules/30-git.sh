#!/bin/bash
# Module 30: Git configuration
# Sets up git config and generates SSH key

log_header "30" "Git configuration..."

# Get current git config if exists
current_name=$(git config --global user.name 2>/dev/null || echo "")
current_email=$(git config --global user.email 2>/dev/null || echo "")

# Prompt for name
prompt git_name "Git name" "$current_name"
if [[ -n "$git_name" ]]; then
    git config --global user.name "$git_name"
    log_ok "Git name: $git_name"
fi

# Prompt for email
prompt git_email "Git email" "$current_email"
if [[ -n "$git_email" ]]; then
    git config --global user.email "$git_email"
    log_ok "Git email: $git_email"
fi

# Set useful defaults
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor nvim
log_ok "Git defaults configured"

# Generate SSH key if not exists
ssh_key="$HOME/.ssh/id_ed25519"
if [[ ! -f "$ssh_key" ]]; then
    log_info "Generating SSH key..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$git_email" -f "$ssh_key" -N ""
    log_ok "SSH key generated"

    # Display public key
    echo ""
    echo -e "  ${CYAN}Your public key (add to GitHub):${NC}"
    echo ""
    cat "${ssh_key}.pub"
    echo ""

    wait_enter "Press Enter after adding to GitHub..."
else
    log_ok "SSH key already exists"
fi

# Start ssh-agent and add key
eval "$(ssh-agent -s)" &>/dev/null
ssh-add "$ssh_key" &>/dev/null || true
log_ok "SSH agent configured"
