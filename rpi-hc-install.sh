#!/usr/bin/env bash
# script to install HamClock on RPi

# set log file
LOGFN=$PWD/$(basename $0).log

# find largest supported hamclock build size
function largestsize ()
{
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

# ask "$1? [y/n] " then return 0 if respond y or 1 if respond n
function ask ()
{
    echo "" >> $LOGFN
    echo "asking: $1?" >> $LOGFN

    ANS=x
    while [ "$ANS" != "y" ] && [ "$ANS" != "n" ]; do
        echo ""
        echo -n "$1? [y/n] "
        read ANS
    done

    echo "answer: $ANS" >> $LOGFN

    [ "$ANS" = "y" ]
}

# print blank line then $*
function inform ()
{
    echo "" >> $LOGFN
    echo $* >> $LOGFN

    echo ""
    echo $*
}

# dump rpi configuration
function dumpConfig ()
{
    echo os-release
    cat /etc/os-release

    echo uname
    uname -a

    echo free -m
    free -m

    echo df
    df

    echo ping home
    ping -c 3 clearskyinstitute.com
}

######################################################################################
#
# execution starts here
#
######################################################################################

# sudo?
if [ "$SUDO_USER" != "" ] ; then
    inform Do not run this with sudo
    exit 1
fi

# really a pi?
OSR=/etc/os-release
if ! egrep -qs 'bullseye|bookworm' $OSR ; then
    inform This script only works on Raspberry Pi OS bullseye or bookworm.
    exit 1
fi

# fresh log
rm -f $LOGFN

# really do it?
inform This script will install HamClock on Raspberry Pi OS.
if ! ask "Proceed" ; then exit 1; fi

# check for another instance
if sudo pkill -0 '^hamclock$' ; then
    inform Another hamclock seems to be running already.
    inform Please exit the existing hamclock then retry this script.
    exit 0
fi

# inform log file
inform A transcript of this installation may be found in $LOGFN
echo -n HamClock installation begins at " " >> $LOGFN
date -u >> $LOGFN
dumpConfig >> $LOGFN

# insure necessary helper packages are installed
inform Installing required helper packages ...
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
sudo apt-get -y update >> $LOGFN 2>&1
sudo apt-get -y install $PKGS >> $LOGFN 2>&1
if (( $? != 0 )) ; then echo error loading packages; exit 1; fi

# download fresh program source
TBALL=ESPHamClock.tgz
TBURL=https://clearskyinstitute.com/ham/HamClock/$TBALL
rm -f $TBALL
inform Downloading $TBURL ...
if ! curl --silent --show-error --output $TBALL $TBURL >> $LOGFN 2>&1 ; then
    inform Error downloading $TBURL -- see $LOGFN
    exit 1
fi

# explode
XDIR=ESPHamClock
rm -fr $XDIR
inform Exploding $TBALL into $XDIR ...
if ! tar xf $TBALL >> $LOGFN 2>&1 ; then inform Error exloding archive -- see $LOGFN; exit 1; fi
rm $TBALL

# cd inside for make
cd $XDIR

# ask desired size from ones that fit unless it can only be 800x480
read SW SH LHCW LHCH < <(largestsize)
inform Display size appears to be ${SW}x${SH}.
if (( $LHCW < 800 || $LHCH < 480 )) ; then
    inform HamClock requires at least 800x480.
    exit
elif (( $LHCW == 800 )) ; then
    size="800x480"
elif (( $LHCW == 1600 )) ; then
    PS3="Select desired HamClock size (1-2): "
    select size in "800x480" "1600x960"; do
        if (( $REPLY >= 1 && $REPLY <= 2 )) ; then break; fi
    done
elif (( $LHCW == 2400 )) ; then
    PS3="Select desired HamClock size (1-3): "
    select size in "800x480" "1600x960" "2400x1440" ; do
        if (( $REPLY >= 1 && $REPLY <= 3 )) ; then break; fi
    done
else
    PS3="Select desired HamClock size (1-4): "
    select size in "800x480" "1600x960" "2400x1440" "3200x1920"; do
        if (( $REPLY >= 1 && $REPLY <= 4 )) ; then break; fi
    done
fi
HC_BUILD="hamclock-$size"

# build with rough progress indication
let NLOGLINES=114
inform Building $HC_BUILD ...
WC0=$(wc -l < $LOGFN)
NPROC=$(getconf _NPROCESSORS_ONLN)                                              
let MAKEJ="$NPROC>1?$NPROC-1:1"
echo running make -j $MAKEJ $HC_BUILD >> $LOGFN
make -j $MAKEJ $HC_BUILD >> $LOGFN 2>&1 &
job=$!
while kill -0 $job 2>/dev/null; do
    sleep .5
    let percent="100 * ( $(wc -l < $LOGFN) - $WC0 ) / $NLOGLINES"
    printf "%2d%%\r" $percent
done
printf "\rfinished\n";
if ! wait %1 >> $LOGFN 2>&1 ; then inform Build failed -- see $LOGFN; exit 1; fi

# install
if ! sudo make install >> $LOGFN 2>&1 ; then inform Install failed -- see $LOGFN; exit 1; fi

# icon?
if [ -d $HOME/Desktop ] ; then
    HCDT=$HOME/Desktop/hamclock.desktop
    HCPNG=$HOME/.hamclock/hamclock.png
    if ask "install HamClock desktop icon" ; then
        mkdir -p $HOME/.hamclock
        rm -f $HCDT $HCPNG
        cp hamclock.png $HCPNG
        sed -e "s^Icon.*^Icon=$HOME/.hamclock/hamclock.png^" < hamclock.desktop > $HCDT
        chmod u+x $HCDT
    else
        rm -f $HCDT $HCPNG
    fi
fi

# man page?
MPATH=/usr/local/share/man/man1
if [ -d $MPATH ] && ask "install HamClock man page" ; then
    # name changed from .man to .1 as of 2.98
    if [ -r hamclock.man ] ; then
        sudo cp hamclock.man $MPATH/hamclock.1
    else
        sudo cp hamclock.1 $MPATH
    fi
fi

# start on boot?
if ask "start HamClock automatically each time Pi is booted" ; then
    # use desktop system
    DOTCFG=$HOME/.config
    if [ -d $DOTCFG ] ; then
        ASPATH=$DOTCFG/autostart
        mkdir -p $ASPATH
        cp -f hamclock.desktop $ASPATH
    else
        inform Error: $DOTCFG does not exist
    fi
else
    # undo autostarting
    rm -f $HOME/.config/autostart/hamclock.desktop
fi

inform HamClock installation is complete.
inform You may run now run HamClock by typing hamclock.
