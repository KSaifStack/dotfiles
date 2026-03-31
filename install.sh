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

# ── Symlink configs ───────────────────────────────────────────────────────────
log "Linking configs..."

link() {
  local src="$DOTFILES_DIR/$1"
  local dst="$HOME/.config/$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak"
    warn "Backed up existing $dst → $dst.bak"
  fi
  ln -sf "$src" "$dst"
  echo "  linked ~/.config/$2"
}

link "hypr"      "hypr"
link "waybar"    "waybar"
link "kitty"     "kitty"
link "fastfetch" "fastfetch"
link "gtk-3.0"   "gtk-3.0"
link "gtk-4.0"   "gtk-4.0"

# ── Link .bashrc ──────────────────────────────────────────────────────────────
log "Linking .bashrc..."
if [ -f "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ]; then
  mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
  warn "Backed up existing .bashrc → .bashrc.bak"
fi
ln -sf "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
echo "  linked ~/.bashrc"

# ── Copy wallpaper ────────────────────────────────────────────────────────────
log "Copying wallpaper..."
mkdir -p ~/.local/share/wallpapers
cp "$DOTFILES_DIR/wallpapers/content.png" ~/.local/share/wallpapers/
echo "  copied wallpaper"

# ── Install packages ──────────────────────────────────────────────────────────
log "Installing packages..."
sudo dnf install -y \
  hyprland \
  waybar \
  hypridle \
  hyprlock \
  hyprpaper \
  swww \
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
  polkit-gnome \
  nwg-look

# ── Intel-only packages ───────────────────────────────────────────────────────
if grep -q "GenuineIntel" /proc/cpuinfo; then
  log "Intel CPU detected — installing Intel-specific packages..."
  sudo dnf install -y \
    intel-lpmd \
    intel-media-driver \
    libva-intel-driver
else
  warn "Non-Intel CPU — skipping intel-lpmd, intel-media-driver"
fi

# ── Optional packages ─────────────────────────────────────────────────────────
log "Installing optional packages..."
sudo dnf install -y ollama code

# ── Set up fastfetch in .bashrc ───────────────────────────────────────────────
log "Setting up fastfetch in .bashrc..."
BASHRC="$DOTFILES_DIR/.bashrc"
if ! grep -q "^fastfetch" "$BASHRC" 2>/dev/null; then
  echo "" >> "$BASHRC"
  echo "# Show system info on terminal launch" >> "$BASHRC"
  echo "fastfetch" >> "$BASHRC"
  echo "  added fastfetch to .bashrc"
else
  echo "  fastfetch already in .bashrc, skipping"
fi

# ── Enable services ───────────────────────────────────────────────────────────
log "Enabling services..."
systemctl --user enable --now hypridle || warn "Could not enable hypridle"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
success "Done! Restart your terminal or run: source ~/.bashrc"
echo ""
echo "  Backed-up configs (if any) are at ~/.config/*.bak and ~/.bashrc.bak"
