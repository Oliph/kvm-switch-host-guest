# This function is used to send a message throught TCP.
# All credits to: http://stackoverflow.com/documentation/powershell/5125/tcp-communication-with-powershell#t=20170126105250343293

Function Send-TCPMessage { 
    Param ( 
            [Parameter(Mandatory=$true, Position=0)]
            [ValidateNotNullOrEmpty()] 
            [string] 
            $EndPoint
        , 
            [Parameter(Mandatory=$true, Position=1)]
            [int]
            $Port
        , 
            [Parameter(Mandatory=$true, Position=2)]
            [string]
            $Message
    ) 
    Process {
        # Setup connection 
        $IP = [System.Net.Dns]::GetHostAddresses($EndPoint) 
        $Address = [System.Net.IPAddress]::Parse($IP) 
        $Socket = New-Object System.Net.Sockets.TCPClient($Address,$Port) 
    
        # Setup stream wrtier 
        $Stream = $Socket.GetStream() 
        $Writer = New-Object System.IO.StreamWriter($Stream)

        # Write message to stream
        $Message | % {
            $Writer.WriteLine($_)
            $Writer.Flush()
        }
    
        # Close connection and stream
        $Stream.Close()
        $Socket.Close()
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
$KEYNAME = $FILECONTENT['KEY']['KEYTOCHANGE']

Send-TCPMessage -Port $PORT -ENDPOINT 127.0.0.1 -message $KEYNAME
Send-TCPMessage -Port $PORT -ENDPOINT $HOSTIP -message $KEYNAME