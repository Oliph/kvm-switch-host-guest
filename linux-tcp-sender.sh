#!/bin/bash          

# Source config reader

. ./bash_ini_parser/read_ini.sh
read_ini ./config.ini

# Set up the variables
PORT=${INI__CONNECTION__PORT}
GUESTIP=${INI__CONNECTION__GUESTIP}
KEYTOCHANGE=${INI__KEY__KEYTOCHANGE}

# Sending the key to the localhost and the guest os with 3 sec of timeout 
echo -n $KEYTOCHANGE | nc  -w 3 127.0.0.1 $PORT
echo -n $KEYTOCHANGE | nc  -w 3 $GUESTIP $PORT
exit
