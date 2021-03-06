Function Start-Computer
{
<#
.SYNOPSIS
Starts a remote computer.

.DESCRIPTION
Uses Wake-On-LAN to boot a computer on the local network.
If supplied with a MAC address, it will start the computer directly.
If supplied with only a computer name, it will search the local computer's ARP cache for a MAC address.
If supplied with a computer name and CSV file, it will retrieve the MAC address from the file.

.PARAMETER Address
The MAC address of the target computer.

.PARAMETER ComputerName
The name of the target computer.

.PARAMETER File
The location of a CSV file containing computernames and MAC addresses.

.EXAMPLE
C:\PS> Start-Computer -Address 11:22:33:44:55:66

.EXAMPLE
C:\PS> Start-Computer Client

.EXAMPLE
C:\PS> Start-Computer Client maclist.csv
#>
    [CmdletBinding(DefaultParameterSetName="MAC")]
    Param (
        [Parameter(ParameterSetName="MAC",Mandatory=$True)]
        [String]$Address,

        [Parameter(ParameterSetName="CSV", Mandatory=$True, Position=1)]
        [Parameter(ParameterSetName="ARP", Mandatory=$True, Position=1)]
        [String]$ComputerName, 

        [Parameter(ParameterSetName="CSV", Mandatory=$True, Position=2)]
        [String]$File
    )
    
    Switch ($PsCmdlet.ParameterSetName)
    {
        #MAC address given

        "MAC"
        {
            #Splits address into array of individual values

            If($Address -like "??:??:??:??:??:??")
            {
                $MACAddrSplit = $Address.Split(':')

            }
            ElseIf($Address -like "??-??-??-??-??-??") 
            {
                $MACAddrSplit = $Address.Split('-')
            }
            Else
            {
                Throw "Invalid MAC address format."
            }

            Break
        }

        #Hostname only given

        "ARP"
        {
            #Converts hostname to IP addresses
            Try
            {
		       $IPList = [System.Net.Dns]::GetHostAddresses($ComputerName)
            }
            Catch [System.Management.Automation.MethodInvocationException]
            {
                Throw "No DNS record found for $ComputerName."
            }
            
            #Searches local ARP cache for the MAC address corresponding to the IP address

            ForEach($IPAddress in $IPList)
            {
                If($IPAddress.AddressFamily -eq 'InterNetwork') #IPv4 address
                {
                    $ARPOutput = arp $IPAddress -a
                    $ARPLine = ($ARPOutput | Select-String "^\s{2}$($IPAddress.IPAddressToString)")
                    If($ARPLine)
                    {
                        $MACAddrString = $ARPLine.ToString().Split(' ',[System.StringSplitOptions]::RemoveEmptyEntries)[1]
                        $MACAddrSplit = $MACAddrString.Split('-')
                    }
                }
            }

            If($MACAddrSplit)
            {
                Break
            }
            Else
            {
                Throw "No ARP Entries Found."
            }
        }

        #Hostname & file given

        "CSV"
        {
            #Searches given file for hostname matching given value

            $MACAddrString = Import-Csv $File | `
                             Where-Object {$_.Hostname -like $ComputerName} | `
                             Select-Object -ExpandProperty MAC

            If($MACAddrString -like "??:??:??:??:??:??")
            {
                $MACAddrSplit = $MACAddrString.Split(':')

            }
            ElseIf($MACAddrString -like "??-??-??-??-??-??") 
            {
                $MACAddrSplit = $MACAddrString.Split('-')
            }
            Else
            {
                Throw "Host has no record in file."
            }

            Break
        }
    }
    
    #Convert MAC address String array to Byte array

    [Byte[]]$MACAddrByte = @()
    ForEach ($Octet in $MACAddrSplit)
    {
        $MACAddrByte += [Byte]('0x' + $Octet)
    }
    
    #Form magic packet

    $Packet = [Byte[]](,0xFF * 6)
    $Packet += $MACAddrByte * 16

    #Create UDP client and send magic packet

    $UDPclient = New-Object System.Net.Sockets.UdpClient
    If ($UDPclient.Send($packet, $packet.Length, "255.255.255.255", 4000) `
        -eq $packet.Length)
    {
        Write-Host "Magic packet sent."
    }
    Else
    {
        Throw "Error sending magic packet."
    }

}
