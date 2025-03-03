#!/usr/bin/env bash
# 🕒 HamClock Installer for Raspberry Pi 🍓
# Original script by Elwood Downey, WB0OEW
# Fancy version by 9M2PJU - Just adding fun stuff! That's all.
# Makes installing HamClock more fun!

# Set up our mission log 📝
LOGFN=$PWD/$(basename $0).log

# 📐 Find largest supported hamclock build size
function largestsize ()
{
    echo "🔍 Detecting your screen dimensions..." >&2
    # get screen size
    read SW SH < <(xdpyinfo -display :0 | perl -ne '/dimensions: *(\d+)x(\d+)/ and print "$1 $2\n"')

    # find HC fractions in each dimension
    HCW=800
    HCH=480
    HCWX=$(($SW/$HCW))
    HCHX=$(($SH/$HCH))

    # use smaller fraction so both dimensions fit
    if (( $HCWX >= $HCHX )) ; then
        HCW=$(($HCW * $HCHX))
        HCH=$(($HCH * $HCHX))
    else
        HCW=$(($HCW * $HCWX))
        HCH=$(($HCH * $HCWX))
    fi

    echo $SW $SH $HCW $HCH
}

# 🤔 Ask "$1? [y/n] " then return 0 if respond y or 1 if respond n
function ask ()
{
    echo "" >> $LOGFN
    echo "❓ asking: $1?" >> $LOGFN

    ANS=x
    while [ "$ANS" != "y" ] && [ "$ANS" != "n" ]; do
        echo ""
        echo -en "❓ \033[1m$1?\033[0m [y/n] "
        read ANS
    done

    echo "answer: $ANS" >> $LOGFN

    [ "$ANS" = "y" ]
}

# 📢 Print blank line then $*
function inform ()
{
    echo "" >> $LOGFN
    echo $* >> $LOGFN

    echo ""
    echo -e "🔔 \033[1m$*\033[0m"
}

# 🖥️ Dump rpi configuration
function dumpConfig ()
{
    echo "📋 os-release"
    cat /etc/os-release

    echo "📋 uname"
    uname -a

    echo "📋 free -m"
    free -m

    echo "📋 df"
    df

    echo "📋 ping home"
    ping -c 3 clearskyinstitute.com
}

# 🎮 Show a progress bar
function show_progress {
    local width=50
    local percent=$1
    local num_chars=$(($width * $percent / 100))
    
    printf "["
    for ((i=0; i<$width; i++)); do
        if [ $i -lt $num_chars ]; then
            printf "="
        else
            printf " "
        fi
    done
    printf "] %3d%%\r" $percent
}

# 🎉 Show success message with ASCII art
function show_success {
    echo ""
    echo -e "\033[32m  _   _                  _____ _            _      \033[0m"
    echo -e "\033[32m | | | | __ _ _ __ ___  / ____| | ___   ___| | __  \033[0m"
    echo -e "\033[32m | |_| |/ _\` | '_ \` _ \| |    | |/ _ \ / __| |/ /  \033[0m"
    echo -e "\033[32m |  _  | (_| | | | | | | |____| | (_) | (__|   <   \033[0m"
    echo -e "\033[32m |_| |_|\__,_|_| |_| |_|\_____|_|\___/ \___|_|\_\\  \033[0m"
    echo -e "\033[32m                                                    \033[0m"
    echo -e "\033[32m          Successfully Installed! 🚀               \033[0m"
    echo ""
}

######################################################################################
#
# 🚀 Execution starts here
#
######################################################################################

# Clear screen for a clean start
clear

# Display welcome banner
echo -e "\033[36m"
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃  🕒 HamClock Installer for Raspberry Pi 🍓                                       ┃"
echo "┃  Original script by Elwood Downey, WB0OEW                                       ┃"
echo "┃  Fancy version by 9M2PJU - Adding some fun and color to your installation!      ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo -e "\033[0m"

# sudo check 🔒
if [ "$SUDO_USER" != "" ] ; then
    inform "⛔ Do not run this with sudo! We'll ask for permissions when needed."
    exit 1
fi

# Really a pi? 🍓
OSR=/etc/os-release
if ! egrep -qs 'bullseye|bookworm' $OSR ; then
    inform "⛔ This script only works on Raspberry Pi OS bullseye or bookworm."
    exit 1
fi

# Fresh log 📝
rm -f $LOGFN

# Really do it? 🤔
inform "🍓 This magical script will install HamClock on your Raspberry Pi!"
if ! ask "Ready for liftoff" ; then 
    echo -e "\n👋 Maybe next time! Goodbye!"
    exit 1
fi

# Check for another instance 🕵️
if sudo pkill -0 '^hamclock$' ; then
    inform "⚠️ Another hamclock seems to be running already."
    inform "Please exit the existing hamclock then retry this script."
    exit 0
fi

# Inform log file 📋
inform "📝 A transcript of this installation will be saved in $LOGFN"
echo -n "🕒 HamClock installation begins at " >> $LOGFN
date -u >> $LOGFN
echo "🔍 Gathering system information..." >&2
dumpConfig >> $LOGFN

# Insure necessary helper packages are installed 📦
inform "📦 Installing required helper packages..."
PKGS="\
    make \
    g++ \
    libx11-dev \
    x11-utils \
    xserver-xorg \
    linux-libc-dev \
    gpiod \
    libgpiod-dev \
    curl \
    openssl \
    xdg-utils"
echo "🔄 Updating package lists..." >&2
sudo apt-get -y update >> $LOGFN 2>&1
echo "📥 Installing packages..." >&2
sudo apt-get -y install $PKGS >> $LOGFN 2>&1
if (( $? != 0 )) ; then echo "❌ Error loading packages"; exit 1; fi
echo "✅ Packages installed successfully!" >&2

# Download fresh program source 📥
TBALL=ESPHamClock.tgz
TBURL=https://clearskyinstitute.com/ham/HamClock/$TBALL
rm -f $TBALL
inform "📥 Downloading $TBURL..."
echo "🌐 Contacting server..." >&2
if ! curl --silent --show-error --output $TBALL $TBURL >> $LOGFN 2>&1 ; then
    inform "❌ Error downloading $TBURL -- see $LOGFN"
    exit 1
fi
echo "✅ Download complete!" >&2

# Explode 💥
XDIR=ESPHamClock
rm -fr $XDIR
inform "📂 Unpacking $TBALL into $XDIR..."
if ! tar xf $TBALL >> $LOGFN 2>&1 ; then inform "❌ Error unpacking archive -- see $LOGFN"; exit 1; fi
rm $TBALL
echo "✅ Unpacked successfully!" >&2

# cd inside for make
cd $XDIR

# Ask desired size from ones that fit unless it can only be 800x480 📏
read SW SH LHCW LHCH < <(largestsize)
inform "🖥️ Your display size appears to be ${SW}x${SH}."
if (( $LHCW < 800 || $LHCH < 480 )) ; then
    inform "⛔ HamClock requires at least 800x480 display."
    exit
elif (( $LHCW == 800 )) ; then
    size="800x480"
    echo "🎯 Your display can fit HamClock at 800x480" >&2
elif (( $LHCW == 1600 )) ; then
    echo -e "\n🎛️ \033[1mSize Selection\033[0m - Pick your preferred display size:" >&2
    PS3="🔢 Enter your choice (1-2): "
    select size in "800x480 (Standard)" "1600x960 (Large)"; do
        if (( $REPLY >= 1 && $REPLY <= 2 )) ; then break; fi
    done
elif (( $LHCW == 2400 )) ; then
    echo -e "\n🎛️ \033[1mSize Selection\033[0m - Pick your preferred display size:" >&2
    PS3="🔢 Enter your choice (1-3): "
    select size in "800x480 (Standard)" "1600x960 (Large)" "2400x1440 (Extra Large)" ; do
        if (( $REPLY >= 1 && $REPLY <= 3 )) ; then break; fi
    done
else
    echo -e "\n🎛️ \033[1mSize Selection\033[0m - Pick your preferred display size:" >&2
    PS3="🔢 Enter your choice (1-4): "
    select size in "800x480 (Standard)" "1600x960 (Large)" "2400x1440 (Extra Large)" "3200x1920 (Massive)"; do
        if (( $REPLY >= 1 && $REPLY <= 4 )) ; then break; fi
    done
fi
size=$(echo $size | cut -d' ' -f1)
HC_BUILD="hamclock-$size"
echo -e "✅ Selected size: \033[1m$size\033[0m" >&2

# Build with fancy progress indication 🏗️
let NLOGLINES=114
inform "🏗️ Building $HC_BUILD..."
WC0=$(wc -l < $LOGFN)
NPROC=$(getconf _NPROCESSORS_ONLN)                                              
let MAKEJ="$NPROC>1?$NPROC-1:1"
echo "🔨 Running make -j $MAKEJ $HC_BUILD" >> $LOGFN
make -j $MAKEJ $HC_BUILD >> $LOGFN 2>&1 &
job=$!

echo -e "⚙️ Building with $MAKEJ processor(s)..." >&2
while kill -0 $job 2>/dev/null; do
    sleep .5
    let percent="100 * ( $(wc -l < $LOGFN) - $WC0 ) / $NLOGLINES"
    show_progress $percent
done
echo -e "\n✅ Build complete!" >&2
if ! wait %1 >> $LOGFN 2>&1 ; then inform "❌ Build failed -- see $LOGFN"; exit 1; fi

# Install 🔧
inform "📥 Installing HamClock..."
if ! sudo make install >> $LOGFN 2>&1 ; then inform "❌ Install failed -- see $LOGFN"; exit 1; fi
echo "✅ Installation successful!" >&2

# Icon? 🖼️
if [ -d $HOME/Desktop ] ; then
    HCDT=$HOME/Desktop/hamclock.desktop
    HCPNG=$HOME/.hamclock/hamclock.png
    if ask "Add a shiny HamClock desktop icon" ; then
        echo "🖼️ Creating desktop icon..." >&2
        mkdir -p $HOME/.hamclock
        rm -f $HCDT $HCPNG
        cp hamclock.png $HCPNG
        sed -e "s^Icon.*^Icon=$HOME/.hamclock/hamclock.png^" < hamclock.desktop > $HCDT
        chmod u+x $HCDT
        echo "✅ Desktop icon created!" >&2
    else
        rm -f $HCDT $HCPNG
    fi
fi

# Man page? 📚
MPATH=/usr/local/share/man/man1
if [ -d $MPATH ] && ask "Install the helpful HamClock manual page" ; then
    echo "📚 Installing manual page..." >&2
    # name changed from .man to .1 as of 2.98
    if [ -r hamclock.man ] ; then
        sudo cp hamclock.man $MPATH/hamclock.1
    else
        sudo cp hamclock.1 $MPATH
    fi
    echo "✅ Manual page installed!" >&2
fi

# Start on boot? 🚀
if ask "Start HamClock automatically when your Pi boots up" ; then
    echo "🚀 Setting up autostart..." >&2
    # use desktop system
    DOTCFG=$HOME/.config
    if [ -d $DOTCFG ] ; then
        ASPATH=$DOTCFG/autostart
        mkdir -p $ASPATH
        cp -f hamclock.desktop $ASPATH
        echo "✅ Autostart configured!" >&2
    else
        inform "❌ Error: $DOTCFG does not exist"
    fi
else
    # undo autostarting
    echo "🛑 Removing any existing autostart configuration..." >&2
    rm -f $HOME/.config/autostart/hamclock.desktop
fi

# Success! 🎉
show_success
inform "🎊 HamClock installation is complete! 🎊"
inform "⏰ You may now run HamClock by typing 'hamclock' or using the desktop icon."
echo -e "\n📡 All credits for the original script go to Elwood Downey, WB0OEW"
echo -e "📻 9M2PJU just made it fancy. That's all!"
echo -e "\n👋 Happy ham radio clocking! 73's!\n"
