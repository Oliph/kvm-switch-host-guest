#!/bin/bash

# Source config reader

. ./bash_ini_parser/read_ini.sh
read_ini ./config.ini

# Set up the variables
PORT=${INI__CONNECTION__PORT}
HOSTIP=${INI__CONNECTION__HOSTIP}
GUESTIP=${INI__CONNECTION__GUESTIP}


MAINSCREEN=${INI__SCREENS__MAINSCREEN}
SECONDSCREEN=${INI__SCREENS__SECONDSCREEN}
THIRDSCREEN=${INI__SCREENS__THIRDSCREEN}


M500KB=${INI__USB__M500KB}
WIREDMOUSE=${INI__USB__WIREDMOUSE}
DUALSHOCK=${INI__USB__DUALSHOCK}

KVMGUESTNAME=${INI__NAMES__KVMGUESTNAME}
HOSTSYNERGYNAME=${INI__NAMES__HOSTSYNERGYNAME}
GUESTSYNERGYNAME=${INI__NAMES__GUESTSYNERGYNAME}

KEYTOCHANGE=${INI__KEY__KEYTOCHANGE}

HOSTSYNERGYCONF=${INI__SYNERGYCONF__HOSTSYNERGYCONF}




## Functions
function main_computer {
    ### To make the computer the main one


    ## 1. Reset screen

    xrandr --output $MAINSCREEN --auto --primary --output $SECONDSCREEN --auto --left-of $MAINSCREEN --output $THIRDSCREEN --off


    ## 2. Getting the keyboard and the mouse back

    # #http://rolandtapken.de/blog/2011-04/how-auto-hotplug-usb-devices-libvirt-vms-update-1
    echo "Doing the desactivation"
    virsh -c qemu:///system detach-device $KVMGUESTNAME $WIREDMOUSE || true 
    virsh -c qemu:///system detach-device $KVMGUESTNAME $M500KB || true
    virsh -c qemu:///system detach-device $KVMGUESTNAME $DUALSHOCK  || true

    ## 3. Killing synergy clients

    ## Wait a little bit to have time to switch synergy on the host
    echo "Killing synergy"
    killall -9 synergys || true
    killall -9 synergyc || true
    killall -9 synergy  || true
    # wait 2 second before launching synergy
    sleep 2

    ## 4. Launching synergy back

    echo "Launching synergy"
    /usr/bin/synergy -c $HOSTSYNERGYCONF &

    # exit
}


function second_computer {
    #### To make this computer the second one

    ## 1. Reset screen

    xrandr --output $SECONDSCREEN --primary --output $MAINSCREEN --off --output $THIRDSCREEN --off 

    ## 2. Getting the keyboard and the mouse back

    #http://rolandtapken.de/blog/2011-04/how-auto-hotplug-usb-devices-libvirt-vms-update-1
    virsh -c qemu:///system attach-device $KVMGUESTNAME $WIREDMOUSE  || true
    virsh -c qemu:///system attach-device $KVMGUESTNAME $M500KB || true
    virsh -c qemu:///system attach-device $KVMGUESTNAME $DUALSHOCK  || true

    ## 2. Killing synergy clients

    killall -5 synergys  || true
    killall -5 synergyc  || true 
    killall -5 synergy  || true
    # Wait 2 sec before launching synergy
    sleep 2

    ## 3. Launching synergy back
    /usr/bin/synergyc --name $HOSTSYNERGYNAME $GUESTIP &
    # exit
}



# Set up initial state to be sure the linux host is the main computer
mode='main'
main_computer
## Main loop. Keep listening to the specified port and if receives the appropriate key, launch the
## function to change between main and second computer 
while true; 
do
    # Using netcat to listen to the port. Close the connection as soon as getting a message
    # adding the option -k keeps it alive
    network_signal=`nc -l $PORT`
    # Remove the return carriage from windows message that is appended automatically
    network_signal=$(echo "$network_signal" | sed 's/\r//')

    if [ "${network_signal}" == $KEYTOCHANGE ];
    then
        if [ "$mode" == 'main' ]; 
        then
            echo "Swith to second"
            second_computer
            mode="second"

        elif [ "$mode" == 'second' ];
        then
            echo "Switch to main"
            main_computer
            mode="main"

        fi
    fi
done
