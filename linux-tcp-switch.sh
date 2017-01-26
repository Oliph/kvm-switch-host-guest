

## Variables

#Port to communicate
PORT=29800

# Screens to modify
MAINSCREEN=HDMI1
SECONDSCREEN=HDMI2
THIRDSCREEN=VGA1

# Name of the windows guest for kvm
KVMGUESTNAME=win-10
# Name of arch name for synergy
LINUXGUESTNAME=arch

# Different usb devices to attach or detach 
WIRELESSKEYBOARD=/home/olivier/config_files/kvm/wireless_keyboard.xml
WIRELESSMOUSE=/home/olivier/config_files/kvm/wireless_mouse.xml
M500KB=/home/olivier/config_files/kvm/m500.xml
WIREDMOUSE=/home/olivier/config_files/kvm/wired_mouse.xml
DUALSHOCK=/home/olivier/config_files/kvm/dual_shock.xml


## Functions
function main_computer {
    ### To make the computer the main one


    ## 1. Reset screen

    xrandr --output $MAINSCREEN --auto --primary --output $SECONDSCREEN --auto --left-of $MAINSCREEN --output $THIRDSCREEN --off

    sleep 2

    ## 2 Getting the keyboard and the mouse back
    # #http://rolandtapken.de/blog/2011-04/how-auto-hotplug-usb-devices-libvirt-vms-update-1
    echo "Doing the desactivation"
    virsh -c qemu:///system detach-device $KVMGUESTNAME $WIREDMOUSE || true 
    virsh -c qemu:///system detach-device $KVMGUESTNAME $M500KB || true

    # ## 4 Killing synergy clients
    ## Wait a little bit to have time to switch synergy on the host
    sleep 5
    echo "Killing synergy"
    killall -9 synergys || true
    killall -9 synergyc || true
    killall -9 synergy  || true
    # wait 2 second before launching synergy
    sleep 2
    # # 5 launching synergy back
    echo "Launching synergy"
    synergy -c /home/olivier/config_files/kvm/synergy_server.conf &

    exit
}


function second_computer {
    #### To make this computer the second one

    ## 1. Reset screen
    xrandr --output $SECONDSCREEN --primary --output $MAINSCREEN --off --output $THIRDSCREEN --off 
    sleep 2
    ## 3 Getting the keyboard and the mouse back
    #http://rolandtapken.de/blog/2011-04/how-auto-hotplug-usb-devices-libvirt-vms-update-1
    virsh -c qemu:///system attach-device $KVMGUESTNAME $WIREDMOUSE  || true
    virsh -c qemu:///system attach-device $KVMGUESTNAME $M500KB || true
    virsh -c qemu:///system attach-device $KVMGUESTNAME $DUALSHOCK  || true

    ## 4 Killing synergy clients
    killall -9 synergys  || true
    killall -9 synergyc  || true 
    killall -9 synergy  || true
    # Wait 2 sec before launching synergy
    sleep 2
    # 5 launching synergy back
    synergyc --name arch 192.168.1.87 &
    exit
}



mode='main'
while true; 
do
    # Using netcat to listen to the port. Close the connection as soon as getting a message
    # adding the option -k keeps it alive
    network_signal=`nc -l $PORT`
    echo $network_signal
    if [ "$mode" == 'main' ]; 
    then
        mode='second'

    elif [ "$mode" == 'second' ];
    then
        mode='main'
    fi
    echo $mode
done
