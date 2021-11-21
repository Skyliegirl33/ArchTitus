#!/usr/bin/env bash
#-------------------------------------------------------------------------
#   ██████╗ ██╗   ██╗ █████╗  ██████╗██╗  ██╗     ██████╗ ███████╗
#  ██╔═══██╗██║   ██║██╔══██╗██╔════╝██║ ██╔╝    ██╔═══██╗██╔════╝
#  ██║   ██║██║   ██║███████║██║     █████╔╝     ██║   ██║███████╗
#  ██║▄▄ ██║██║   ██║██╔══██║██║     ██╔═██╗     ██║   ██║╚════██║
#  ╚██████╔╝╚██████╔╝██║  ██║╚██████╗██║  ██╗    ╚██████╔╝███████║
#   ╚══▀▀═╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝     ╚═════╝ ╚══════╝ 
#-------------------------------------------------------------------------

echo -e "\nINSTALLING AUR SOFTWARE\n"
# You can solve users running this script as root with this and then doing the same for the next for statement. However I will leave this up to you.

echo "CLONING: YAY"
cd ~
git clone "https://aur.archlinux.org/yay.git"
cd ${HOME}/yay
makepkg -si --noconfirm

PKGS=(
'autojump'
'awesome-terminal-fonts'
'firefox'
'find-the-command'
'fish'
'discord'
'dxvk-bin' # DXVK DirectX to Vulcan
'github-desktop-bin' # Github Desktop sync
'heroic-games-launcher-bin'
'element-desktop'
'mangohud' # Gaming FPS Counter
'mangohud-common'
'keepassxc'
'noto-fonts-emoji'
'plasma-pa'
'proton-ge-custom-bin'
'protontricks-git'
'rpcs3-git'
'ocs-url' # install packages from websites
'sddm-nordic-theme-git'
'snapper-gui-git'
'steam-native-runtime'
'steamtinkerlaunch'
'starship'
'tela-icon-theme'
'inverse-icon-theme-git'
'vscodium'
'ttf-dejavu'
'ttf-fantasque-sans-mono'
'ttf-fira-code'
'ttf-fira-sans'
'ttf-inconsolata'
'ttf-liberation'
'ttf-opensans'
'ttf-droid'
'ttf-hack'
'ttf-meslo' # Nerdfont package
'ttf-roboto'
'yuzu-mainline-git'
'yakuake'
)

for PKG in "${PKGS[@]}"; do
    yay -S --noconfirm $PKG
done

export PATH=$PATH:~/.local/bin
cp -r $HOME/QuackOS/dotfiles/. $HOME
pip install konsave
konsave -i $HOME/QuackOS/quackos.knsv
sleep 1
konsave -a quackos

echo -e "\nDone!\n"
exit
