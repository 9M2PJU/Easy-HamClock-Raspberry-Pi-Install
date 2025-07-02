#!/usr/bin/env bash
# 🕒 HamClock Installer & Uninstaller for Raspberry Pi 🍓
# Original script by Elwood Downey, WB0OEW
# Enhanced and beautified by 9M2PJU - for more smiles per install 😊

# Set up our mission log 📝
LOGFN=$PWD/$(basename $0).log

# 📢 Print blank line then $*
function inform () {
    echo "" >> $LOGFN
    echo "$*" >> $LOGFN
    echo ""
    echo -e "🔔 \033[1m$*\033[0m"
}

# 🤔 Ask "$1? [y/n]" and return 0 if yes
function ask () {
    echo "" >> $LOGFN
    echo "❓ asking: $1?" >> $LOGFN
    local ANS=x
    while [[ "$ANS" != "y" && "$ANS" != "n" ]]; do
        echo -en "❓ \033[1m$1?\033[0m [y/n] "
        read -r ANS
    done
    echo "answer: $ANS" >> $LOGFN
    [[ "$ANS" == "y" ]]
}

# 🎮 Show a progress bar
function show_progress {
    local width=50
    local percent=$1
    local num_chars=$((width * percent / 100))
    printf "["
    for ((i=0; i<width; i++)); do
        if (( i < num_chars )); then printf "="; else printf " "; fi
    done
    printf "] %3d%%\r" $percent
}

# 🎉 Success banner
function show_success {
    echo ""
    echo -e "\033[32m  _   _                  _____ _            _      \033[0m"
    echo -e "\033[32m | | | | __ _ _ __ ___  / ____| | ___   ___| | __  \033[0m"
    echo -e "\033[32m | |_| |/ _\` | '_ \` _ \| |    | |/ _ \ / __| |/ /  \033[0m"
    echo -e "\033[32m |  _  | (_| | | | | | | |____| | (_) | (__|   <   \033[0m"
    echo -e "\033[32m |_| |_|\__,_|_| |_| |_|\_____|_|\___/ \___|_|\_\\  \033[0m"
    echo -e "\033[32m                                                    \033[0m"
    echo -e "\033[32m         Successfully Installed! 🚀                \033[0m"
    echo ""
}

# 📐 Find largest supported hamclock build size
function largestsize () {
    read SW SH < <(xdpyinfo -display :0 | perl -ne '/dimensions: *(\d+)x(\d+)/ and print "$1 $2\n"')
    HCW=800; HCH=480
    HCWX=$((SW / HCW)); HCHX=$((SH / HCH))
    if (( HCWX >= HCHX )); then
        HCW=$((HCW * HCHX)); HCH=$((HCH * HCHX))
    else
        HCW=$((HCW * HCWX)); HCH=$((HCH * HCWX))
    fi
    echo $SW $SH $HCW $HCH
}

# 🎯 Entry Menu
clear
echo -e "\033[36m"
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃  🕒 HamClock Installer & Uninstaller for Raspberry Pi 🍓                        ┃"
echo "┃  Original by Elwood Downey, WB0OEW | Fun Version by 9M2PJU                     ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo -e "\033[0m"

PS3="🤔 What would you like to do? "
options=("Install HamClock" "Uninstall HamClock" "Exit")
select opt in "${options[@]}"; do
    case $opt in
        "Install HamClock") ACTION="install"; break ;;
        "Uninstall HamClock") ACTION="uninstall"; break ;;
        "Exit") echo "👋 Goodbye!"; exit 0 ;;
        *) echo "❌ Invalid option $REPLY" ;;
    esac
done

# 🔧 UNINSTALL MODE
if [[ "$ACTION" == "uninstall" ]]; then
    inform "🧹 Uninstalling HamClock..."

    BIN_PATH="/usr/local/bin/hamclock"
    MAN_PATH="/usr/local/share/man/man1/hamclock.1"
    AUTOSTART="$HOME/.config/autostart/hamclock.desktop"
    DESKTOP_ICON="$HOME/Desktop/hamclock.desktop"
    ICON_IMG="$HOME/.hamclock/hamclock.png"

    sudo rm -f "$BIN_PATH" && echo "✅ Removed $BIN_PATH"
    rm -f "$AUTOSTART" && echo "✅ Removed autostart file"
    rm -f "$DESKTOP_ICON" && echo "✅ Removed desktop icon"
    rm -f "$ICON_IMG" && echo "✅ Removed icon image"

    if [[ -f "$MAN_PATH" ]]; then
        if ask "Remove the manual page too"; then
            sudo rm -f "$MAN_PATH"
            echo "✅ Removed man page"
        fi
    fi

    inform "✅ HamClock has been fully uninstalled."
    echo -e "\n👋 Goodbye and 73's!\n"
    exit 0
fi

# 🔐 Sudo check
if [[ "$SUDO_USER" != "" ]]; then
    inform "⛔ Do not run this with sudo! We'll ask for permissions when needed."
    exit 1
fi

# 🧠 Sanity check for Pi OS
if ! egrep -qs 'bullseye|bookworm' /etc/os-release ; then
    inform "⛔ This script only works on Raspberry Pi OS bullseye or bookworm."
    exit 1
fi

# 📥 Install packages
inform "📦 Installing required packages..."
sudo apt-get update -y
sudo apt-get install -y make g++ libx11-dev x11-utils xserver-xorg linux-libc-dev gpiod libgpiod-dev curl openssl xdg-utils

# 🔽 Download HamClock
TBALL=ESPHamClock.tgz
TBURL=https://clearskyinstitute.com/ham/HamClock/$TBALL
rm -f $TBALL
inform "🌐 Downloading HamClock..."
curl --silent --show-error --output $TBALL $TBURL || { inform "❌ Download failed!"; exit 1; }

# 📂 Extract
XDIR=ESPHamClock
rm -rf $XDIR
inform "📂 Unpacking HamClock..."
tar xf $TBALL || { inform "❌ Failed to unpack!"; exit 1; }
rm -f $TBALL
cd $XDIR

# 📏 Determine size
read SW SH LHCW LHCH < <(largestsize)
inform "🖥️ Detected screen size: ${SW}x${SH}"
if (( LHCW < 800 || LHCH < 480 )); then
    inform "⛔ HamClock requires minimum 800x480 resolution."
    exit 1
fi

# 🧠 Choose size
if (( LHCW == 800 )); then
    size="800x480"
elif (( LHCW == 1600 )); then
    PS3="🔢 Choose display size: "
    select size in "800x480" "1600x960"; do [[ $REPLY =~ ^[1-2]$ ]] && break; done
elif (( LHCW == 2400 )); then
    PS3="🔢 Choose display size: "
    select size in "800x480" "1600x960" "2400x1440"; do [[ $REPLY =~ ^[1-3]$ ]] && break; done
else
    PS3="🔢 Choose display size: "
    select size in "800x480" "1600x960" "2400x1440" "3200x1920"; do [[ $REPLY =~ ^[1-4]$ ]] && break; done
fi
size=$(echo $size | cut -d' ' -f1)
HC_BUILD="hamclock-$size"
inform "✅ Selected build size: $size"

# 🔨 Build
NLOGLINES=114
inform "🏗️ Building $HC_BUILD..."
WC0=$(wc -l < $LOGFN)
NPROC=$(getconf _NPROCESSORS_ONLN)
MAKEJ=$((NPROC > 1 ? NPROC - 1 : 1))
make -j $MAKEJ $HC_BUILD >> $LOGFN 2>&1 &
job=$!
while kill -0 $job 2>/dev/null; do
    sleep .5
    percent=$((100 * ($(wc -l < $LOGFN) - WC0) / NLOGLINES))
    show_progress $percent
done
wait $job || { inform "❌ Build failed"; exit 1; }
echo -e "\n✅ Build complete!"

# 📥 Install
inform "📥 Installing HamClock..."
sudo make install

# 🖼️ Optional desktop icon
if [[ -d $HOME/Desktop && -f hamclock.desktop ]]; then
    if ask "Add a shiny HamClock desktop icon"; then
        mkdir -p "$HOME/.hamclock"
        cp hamclock.png "$HOME/.hamclock/hamclock.png"
        sed "s^Icon=.*^Icon=$HOME/.hamclock/hamclock.png^" hamclock.desktop > "$HOME/Desktop/hamclock.desktop"
        chmod +x "$HOME/Desktop/hamclock.desktop"
    fi
fi

# 📚 Optional man page
if [[ -d /usr/local/share/man/man1 ]]; then
    if ask "Install HamClock manual page"; then
        [[ -f hamclock.man ]] && sudo cp hamclock.man /usr/local/share/man/man1/hamclock.1 || sudo cp hamclock.1 /usr/local/share/man/man1/
    fi
fi

# 🚀 Autostart option
if ask "Start HamClock on boot"; then
    mkdir -p "$HOME/.config/autostart"
    cp -f hamclock.desktop "$HOME/.config/autostart/"
else
    rm -f "$HOME/.config/autostart/hamclock.desktop"
fi

# 🎉 Done
show_success
inform "⏰ You may now run HamClock by typing 'hamclock' or using the desktop icon."
echo -e "\n👋 Happy ham radio clocking! 73's from 9M2PJU\n"
