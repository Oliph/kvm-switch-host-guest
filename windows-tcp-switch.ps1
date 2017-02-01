## This script is use to switch sreen off and to launch the appropriate synergy instance (client or server) when Windows is used
## as a VM inside linux and to switch quickly between the two. Suppose a command in the host that (de)attach the keyboard/mouse
## and launch the appropriate synergy instance (client or server)
## To create a shortcut to launch the script use the following command
### %SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File "C:\Users\Feadurn\Desktop\main_gaming.ps1"
#### found at http://www.sciosoft.com/blogs/post/2011/10/04/Launch-PowerShell-Script-from-Shortcut.aspx

# Powershell script to switch the screen/synergy/kb+mouse between the host os (linux) and guest os (windows) using a signal sent throught TCP




## Functions
Function Receive-TCPMessage {
    Param ( 
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()] 
        [int] $Port
    ) 
    Process {
        Try { 
            # Set up endpoint and start listening
            $endpoint = new-object System.Net.IPEndPoint([ipaddress]::any,$port) 
            $listener = new-object System.Net.Sockets.TcpListener $EndPoint
            $listener.start() 
 
            # Wait for an incoming connection 
            $data = $listener.AcceptTcpClient() 
        
            # Stream setup
            $stream = $data.GetStream() 
            $bytes = New-Object System.Byte[] 1024

            # Read data from stream and write it to host
            while (($i = $stream.Read($bytes,0,$bytes.Length)) -ne 0){
                $EncodedText = New-Object System.Text.ASCIIEncoding
                $data = $EncodedText.GetString($bytes,0, $i)
                Write-Output $data
            }
         
            # Close TCP connection and stop listening
            $stream.close()
            $listener.stop()
        }
        Catch {
            "Receive Message failed with: `n" + $Error[0]
        }
    }
}


Function Main-Computer {
    Param (
        $GUESTSYNERGYNAME,
        $GUESTIP,
        $GUESTSYNERGYCONF
    )
    Process {
        # Extend the display to the second screen options are /extend /external /clond /internal
        DisplaySwitch.exe /extend

        ## Kill the synergy client process
        Stop-Process -processname synergyc -ErrorAction SilentlyContinue
        ## Kill the synergy server process if they exists
        Stop-Process -processname synergys -ErrorAction SilentlyContinue

        ## Pause a little bit for leaving it the time to terminate synergy properly
        Start-Sleep 2
        ## Launch Synergy server
        
        Start-Process -FilePath "C:\Program Files\Synergy\synergys.exe" -ArgumentList "-f --debug ERROR --name $GUESTSYNERGYNAME  --log c:\windows\synergy.log -c $GUESTSYNERGYCONF --address $GUESTIP" -WindowStyle Minimized
    }
}

Function Second-Computer {
    Param (
        $HOSTIP
    )
    Process {
        # Remove the second display
        DisplaySwitch.exe /internal

        # Pause 10 second before killing the synergy server to have time to switch on the linux screen and launch the synergy server there
        ## No Need it is the time needed for the main screen to reactivate
        Start-Sleep 2

        ## Kill the synergy server process 
        Stop-Process -processname synergys -ErrorAction SilentlyContinue
        ## Pause a little bit for leaving it the time to terminate synergy properly
        Start-Sleep 2
        ## Launch the Synergy client
        Start-Process -FilePath "C:\Program Files\Synergy\synergyc.exe"  -ArgumentList $HOSTIP -WindowStyle Minimized
    }
}

## Read config file
Import-Module $PSScriptRoot\PsIni\PsIni
$CONFIGFILE = '.\config.ini'

$FILECONTENT = Get-IniContent $CONFIGFILE
$FILECONTENT
### Set up variables

$PORT = $FILECONTENT['CONNECTION']['PORT']
$HOSTIP = $FILECONTENT['CONNECTION']['HOSTIP']
$GUESTIP = $FILECONTENT['CONNECTION']['GUESTIP']
$KEYNAME = $FILECONTENT['KEY']['KEYTOCHANGE']
## Removing the ' that are added to the string 
$KEYNAME = $KEYNAME.Substring(1, $KEYNAME.Length-2)
echo $KEYNAME

$GUESTSYNERGYNAME = $FILECONTENT['NAMES']['GUESTSYNERGYNAME']
$GUESTSYNERGYCONF = $FILECONTENT['SYNERGYCONF']['GUESTSYNERGYCONF']

## Set up initial state to be sure the guest is the second computer
$mode = 'second'
Second-Computer $HOSTIP
## Main loop

while($true)
{
   $network_signal = Receive-TCPMessage $PORT
   echo $network_signal
   if ($network_signal -match $KEYNAME) {
        if ($mode -match 'second') {
            echo "Received the key and was on $mode"
            echo $GUESTSYNERGYNAME 
            echo $GUESTIP 
            echo $GUESTSYNERGYCONF
            Main-Computer $GUESTSYNERGYNAME $GUESTIP $GUESTSYNERGYCONF
            $mode = 'main'
        }
        elseif ($mode -match 'main') {
            echo "Received the key and was on $mode"
            echo $HOSTIP
            Second-Computer $HOSTIP
            $mode = 'second'
        }
        }
}