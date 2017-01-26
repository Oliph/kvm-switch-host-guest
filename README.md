# kvm-switch-main-linux

A collection of small scripts to be able to switch screens/keyboards-mouse and synergy between a guest os (windows) and a host (archlinux) through tcp. 
It open a tcp connection and when receive a signal, switch the screens, attach/detach some usb devices and kill/launch the appropriate synergy client/server. 
Written in Bash and powershell

## FILES


## REQUIREMENTS
  * [Synergy](https://github.com/symless/synergy) for sharing mouse and keyboard between computers:`sudo pacman -S synergy`
  * [Netcat](http://nc110.sourceforge.net/) for the tcp lstening on linux, should be installed by default: `sudo pacman -S openbsd-netcat`
  
  


## USAGE


## REFERENCES

### Ini Parser
* Use the following repository to parse the variables within the config file: [bash_ini_parser](https://github.com/rudimeier/bash_ini_parser/tree/8fb95e3b335823bc85604fd06c32b0d25f2854c5)
