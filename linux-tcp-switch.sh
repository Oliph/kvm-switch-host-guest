#!/bin/bash          

## Variables

# Port to communicate
PORT=29800

# IP of the guest
GUESTIP=192.168.1.87

# IP of the host
HOSTIP=192.168.1.2

# KEY That is received through tcp to check it is the right one
KEYTOCHANGE='DfxcwRE202dk45'

# Screens to modify
MAINSCREEN=HDMI1
SECONDSCREEN=HDMI2
THIRDSCREEN=VGA1

# Name of the windows guest for kvm
KVMGUESTNAME=win-10

# Name of host  for synergy
HOSTSYNERGY=arch

# Name of guest for synergy
GUESTSYNERGY=win10

# Different usb devices to attach or detach 
M500KB=./usb_xml/m500.xml
WIREDMOUSE=./usb_xml/wired_mouse.xml
DUALSHOCK=./usb_xml/dual_shock.xml

# Synergy config file that has been configured separately
SYNERGYCONF = "./synergy_conf/linux_synergy_server.conf"


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
    synergy -c $SYNERGYCONF &

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
    synergyc --name $HOSTSYNERGY $GUESTIP &
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



mode='main'

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
