# kvm-switch-main-linux

A collection of small scripts to be able to switch screens/keyboards-mouse and synergy between a guest os (windows) and a host (archlinux) through tcp.
It open a tcp connection and when receive a signal, switch the screens, attach/detach some usb devices and kill/launch the appropriate synergy client/server.
Written in Bash and powershell


## Table of content



## FILES


## REQUIREMENTS
  * [Synergy](https://github.com/symless/synergy) for sharing mouse and keyboard between computers:`sudo pacman -S synergy`
  * [Netcat](http://nc110.sourceforge.net/) for the tcp lstening on linux, should be installed by default: `sudo pacman -S openbsd-netcat`


## DEPLOYMENT

### Deployment on Linux

#### linux-sender.sh

The script only need to have a shortcut to be launched only when needed (when to switch).
Make the script execetubale in case it was not before: `chmod +x linux-tcp-sender.sh`.
A simple alias, or adding it in the keyboard shortcut in Gnome-Preference should suffice.

#### linux-switch.sh

To start the [linux-switch.sh](linux-switch.sh) at boot, under archlinux (and any distro using systemd), it is
possible to do so by creating a unit file.

`sudo nano /lib/systemd/system/tcp-switch.service`

Then enter the following:

```
    [Unit]
    Description= Receive signal over tcp to switch between main and second pc
    After= multi.user.target

    [Service]
    Type=idle
    ExecStart=/home/$USER/$PATHTOSCRIPT/kvm-switch-host-guest/linux-tcp-switch.sh

    [Install]
    WantedBy=multi-user.target
```
The path to the script need to be an absolute path, relative path does not work (replace $USER with your own user and $PATHTOSCRIPT with the location of the script folder)

Ensure the file has the permission sets on 644:
    `sudo chmod 644 /lib/systemd/system/tcp-switch.service`

Reload the systemd
`sudo systemctl daemon-reload`

Enable the service
`sudo systemctl enable tcp-switch.service`

Start the service
`sudo systemctl start tcp-switch.service`

### Deployment on Windows

First, to be able to receive the message through the port specified in [config.ini](config.ini), a rule in the windows firewall need to be added.
Right clic on the network icon next to the clock and select `Open Network and Sharing Centre`.
There, click on the option on the left side menu called `Windows Firewall` and in the next windows, still in the left menu, select `Advanced settings`.
This last opened windows is were you can add or remove the rules in the windows Firewall.
Only an inbound rules needs to be added. Selec `Inbound Rules` and then select `New Rules...` in the right menu.
Several options are possible. You can either select Port and enter the same port number as in [config.ini](config.ini), or select the program that is going to accept the connection.


#### windows-tcp-sender.ps1

To be able to use a shortcut with a powershell script, the easiest way is to create a shortcut from the powershell
and in the option of the shortcut (right click on the shortcut icon) filling the field `Shortcut key`.
However, for the script to launch a powershell script, the `Target` needs to be modified as follow:
`%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File  "C:\$PATHTOSCRIPT" `

The source of information can be found [here](http://www.sciosoft.com/blogs/post/2011/10/04/Launch-PowerShell-Script-from-Shortcut.aspx)
#### windows-tcp-switch.ps1

To add a program to start with windows several options are possible but it is easy to follow this [tutorial](http://tunecomp.net/add-app-to-startup/):

`Press Win+R`
Type: `shell:startup`

This is going to open a folder when you should put the shortcut create from the windows-tcp-switch.ps1. Check that you change the `Target` as stated for the previous shortcut but also adding
at the end the option `-WindowsStyle Hidden`.


## REFERENCES

### Ini Parser
* Use the following repository to parse the variables within the config file: [bash_ini_parser](https://github.com/rudimeier/bash_ini_parser/tree/8fb95e3b335823bc85604fd06c32b0d25f2854c5)
