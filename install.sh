#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()     { echo -e "${GREEN}→${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }

# ── Check Fedora ──────────────────────────────────────────────────────────────
if ! grep -q "Fedora" /etc/os-release 2>/dev/null; then
  warn "This script is designed for Fedora. Proceed with caution."
fi

# ── Symlink Config Directories Perfectly ──────────────────────────────────────
log "Linking target configurations..."

link() {
  local src="$DOTFILES_DIR/$1"
  local dst="$HOME/.config/$2"
  
  mkdir -p "$(dirname "$dst")"
  
  if [ -L "$dst" ] || [ -e "$dst" ]; then
    if [ ! -L "$dst" ] && [ -d "$dst" ]; then
      mv "$dst" "$dst.bak"
      warn "Backed up existing physical directory $dst → $dst.bak"
    else
      rm -rf "$dst"
    fi
  fi
  
  ln -sf "$src" "$dst"
  echo "  linked ~/.config/$2"
}

# Explicit mapping based directly on your repo's directory tree
link "hypr"      "hypr"
link "waybar"    "waybar"
link "kitty"     "kitty"
link "fastfetch" "fastfetch"
link "gtk-3.0"   "gtk-3.0"
link "gtk-4.0"   "gtk-4.0"

# ── Link System Profiles (.bashrc) ──────────────────────────────────────────
log "Linking .bashrc configuration profile..."
if [ -L "$HOME/.bashrc" ] || [ -f "$HOME/.bashrc" ]; then
  if [ ! -L "$HOME/.bashrc" ]; then
    mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
    warn "Backed up existing profile .bashrc → .bashrc.bak"
  else
    rm -f "$HOME/.bashrc"
  fi
fi

if [ -f "$DOTFILES_DIR/.bashrc" ]; then
  ln -sf "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
else
  touch "$DOTFILES_DIR/.bashrc"
  ln -sf "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
fi
echo "  linked ~/.bashrc"

# ── Handle Desktop Wallpaper Persistence ──────────────────────────────────────
log "Deploying wallpaper system assets..."
mkdir -p "$HOME/.local/share/wallpapers"
if [ -f "$DOTFILES_DIR/wallpapers/content.png" ]; then
  cp "$DOTFILES_DIR/wallpapers/content.png" "$HOME/.local/share/wallpapers/"
  echo "  copied wallpaper target asset"
else
  warn "Target file missing at wallpapers/content.png, skipping asset copy."
fi

# Make your custom setup wallpaper script executable
if [ -f "$DOTFILES_DIR/hypr/set-wallpaper.sh" ]; then
  chmod +x "$DOTFILES_DIR/hypr/set-wallpaper.sh"
fi

# ── Prepare Ext Repositories (VS Code & Copr) ─────────────────────────────────
log "Adding VS Code and Copr repositories..."
if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
  sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
fi

# Enable copr for grimblast if it isn't in native streams
sudo dnf copr enable -y erikreider/grimblast

# ── Core Component Setup Execution ────────────────────────────────────────────
log "Verifying Core Window Manager Environment..."
if ! command -v hyprland &> /dev/null; then
  log "Hyprland base missing. Direct fetching via DNF channels..."
  sudo dnf install -y hyprland xorg-x11-server-Xwayland
  success "Hyprland display engine framework active!"
else
  echo "  Hyprland base engine already running."
fi

# ── System Wide Dependencies Setup ────────────────────────────────────────────
log "Installing packages required by your hyprland.conf bindings..."
sudo dnf install -y \
  waybar \
  hypridle \
  hyprlock \
  hyprpaper \
  swww \
  hyprsunset \
  swayosd \
  swayosd-libinput \
  grimblast \
  xdg-desktop-portal-hyprland \
  xdg-desktop-portal-gtk \
  kitty \
  neovim \
  kvantum \
  qt5-qtstyleplugins \
  sassc \
  cmake \
  extra-cmake-modules \
  powertop \
  fastfetch \
  brightnessctl \
  playerctl \
  grim \
  slurp \
  wl-clipboard \
  cliphist \
  network-manager-applet \
  blueman \
  pavucontrol \
  polkit-kde \
  nwg-look \
  python3 \
  rofi-wayland \
  pulseaudio-utils \
  flatpak

# ── Secondary Packages Handling ───────────────────────────────────────────────
log "Deploying supplementary components..."
sudo dnf install -y code

if ! sudo dnf install -y ollama 2>/dev/null; then
  warn "Ollama not in primary repository listings. Running standard distribution channel pull..."
  curl -fsSL https://ollama.com/install.sh | sh || warn "External engine pull failed."
fi

# ── Flatpak App Deliveries ────────────────────────────────────────────────────
log "Setting up Flatpak remotes and applications..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub app.zen_browser.zen
flatpak install -y flathub org.equicord.equibop

# ── Sync Inject Runtime Shell Scripts ─────────────────────────────────────────
log "Enforcing execution permissions across runtime scripts..."
find "$DOTFILES_DIR/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
find "$DOTFILES_DIR/waybar/scripts" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true

log "Setting up fastfetch inside user shell profiles..."
BASHRC="$DOTFILES_DIR/.bashrc"
if ! grep -q "^fastfetch" "$BASHRC" 2>/dev/null; then
  echo "" >> "$BASHRC"
  echo "# System monitoring banner initialization" >> "$BASHRC"
  echo "fastfetch" >> "$BASHRC"
  echo "  fastfetch hook injected into .bashrc"
else
  echo "  fastfetch engine flag active, skipping."
fi

# ── Enable System Daemons ─────────────────────────────────────────────────────
log "Enabling system/user daemons..."
systemctl --user enable --now hypridle || warn "Could not link hypridle process tracker."
sudo systemctl enable --now swayosd-libinput-backend.service || warn "Could not enable swayosd backend daemon."

# Fire your wallpaper script right now so it initializes instantly
if [ -f "$HOME/.config/hypr/set-wallpaper.sh" ]; then
  log "Triggering active wallpaper layer..."
  bash "$HOME/.config/hypr/set-wallpaper.sh" || warn "Wallpaper script ran but couldn't attach to a live display server session."
fi

# ── Finalized ─────────────────────────────────────────────────────────────────
echo ""
success "Deployment complete! Reload your shell environment or run: source ~/.bashrc"
echo ""