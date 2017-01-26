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

    sleep 2

    ## 2. Getting the keyboard and the mouse back

    # #http://rolandtapken.de/blog/2011-04/how-auto-hotplug-usb-devices-libvirt-vms-update-1
    echo "Doing the desactivation"
    virsh -c qemu:///system detach-device $KVMGUESTNAME $WIREDMOUSE || true 
    virsh -c qemu:///system detach-device $KVMGUESTNAME $M500KB || true
    virsh -c qemu:///system detach-device $KVMGUESTNAME $DUALSHOCK  || true

    ## 3. Killing synergy clients

    ## Wait a little bit to have time to switch synergy on the host
    sleep 5
    echo "Killing synergy"
    killall -9 synergys || true
    killall -9 synergyc || true
    killall -9 synergy  || true
    # wait 2 second before launching synergy
    sleep 2

    ## 4. Launching synergy back

    echo "Launching synergy"
    synergy -c $HOSTSYNERGYCONF &

    # exit
}


function second_computer {
    #### To make this computer the second one

    ## 1. Reset screen

    xrandr --output $SECONDSCREEN --primary --output $MAINSCREEN --off --output $THIRDSCREEN --off 
    sleep 2

    ## 2. Getting the keyboard and the mouse back

    #http://rolandtapken.de/blog/2011-04/how-auto-hotplug-usb-devices-libvirt-vms-update-1
    virsh -c qemu:///system attach-device $KVMGUESTNAME $WIREDMOUSE  || true
    virsh -c qemu:///system attach-device $KVMGUESTNAME $M500KB || true
    virsh -c qemu:///system attach-device $KVMGUESTNAME $DUALSHOCK  || true

    ## 2. Killing synergy clients

    killall -9 synergys  || true
    killall -9 synergyc  || true 
    killall -9 synergy  || true
    # Wait 2 sec before launching synergy
    sleep 2

    ## 3. Launching synergy back
    synergyc --name $HOSTSYNERGYNAME $GUESTIP &
    # exit
}

function test_func1 {
    echo "test_func1"
    echo $network_signal
    # exit
}

function test_func2 {
    echo "test_func2"
    echo $network_signal
    # exit
}


# Set up initial state to be sure the linux host is the main computer
mode='main'
test_func1

## Main loop. Keep listening to the specified port and if receives the appropriate key, launch the
## function to change between main and second computer 
while true; 
do
    # Using netcat to listen to the port. Close the connection as soon as getting a message
    # adding the option -k keeps it alive
    network_signal=`nc -l $PORT`
    if [ "$network_signal" == $KEYTOCHANGE ];
    then
        if [ "$mode" == 'main' ]; 
        then
            test_func1
            mode="second"
            
        elif [ "$mode" == 'second' ];
        then
            test_func2
            mode="main"

        fi
    fi
done
