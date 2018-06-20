function New-SharpSnmpAgent {
param (
    # Agent address
    $Agent = '127.0.0.1',

    # SNMP port
    [int]$Port = 161,

    # SNMP Community
    [string]$Community = 'public', 
    
    # SNMP Version
    [Lextm.SharpSnmpLib.VersionCode]$Version = 'V2'
    )
    
    @{
        IP = $Agent
        Port = $Port
        Version = $Version
        Community = $Community
        }
    }

function Get-SharpSnmpData {
[CmdletBinding()]
param (
    # Endpoint IP address.
    [Parameter(
        Mandatory = $true,
        HelpMessage = 'IP address'
    )]
    [Net.IPAddress]$IP,

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'OID to request'
    )]
    [string[]]$OID,
    
    # SNMP Community.
    [string]$Community = 'public', 
    
    # SNMP port.
    [int]$Port = 161,

    # SNMP version.
    [Lextm.SharpSnmpLib.VersionCode]$Version = 'V2',

    # Time out value. 
    [int]$TimeOut = 3000
)

   try {
        $DataPayload = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'
        foreach ($OIDString in $OID) {
 		    $OIDObject = New-Object Lextm.SharpSnmpLib.ObjectIdentifier ($OIDString)
		    $DataPayload.Add($OIDObject)
            }
 
       
        } 
   catch {
        Write-Warning "SNMP Error initializing OID object $($OID): $_"
        break
        }
    $endpoint = New-Object Net.IpEndPoint $IP, $Port
 
    try {
        $message = [Lextm.SharpSnmpLib.Messaging.Messenger]::Get(
            $Version, 
            $endpoint, 
            $Community, 
            $DataPayload, 
            $TimeOut
            )
        } 
    catch {
        Write-Warning "SNMP Get error accessing $($IP): $_"
        return
    }
    $message
    
}

function Invoke-SharpSnmpWalk {
[CmdletBinding()]
param (
    # Endpoint IP address.
    [Parameter(
        Mandatory = $true,
        HelpMessage = 'IP address of SNMP agent'
    )]
    [Net.IPAddress]$IP,

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'OID to request'
    )]
    [Lextm.SharpSnmpLib.ObjectIdentifier]$OID,
    
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Community name'
    )]
    [Lextm.SharpSnmpLib.OctetString]$Community = 'public', 
    
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'UDP port of SNMP agent'
    )]
    [int]$Port = 161,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SNMP Version to use'
    )]
    [Lextm.SharpSnmpLib.VersionCode]$Version = 'V2',

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Timeout to wait for response'
    )]
    [int]$TimeOut = 3000,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Max Repetitions (applicable for V2)'
    )]
    [int]$MaxRepetitions = 50,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Max Repetitions (applicable for V2)'
    )]
    [Lextm.SharpSnmpLib.Messaging.WalkMode]$WalkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree
)

    $EndPoint = New-Object Net.IpEndPoint $IP, $Port

    # Create list for results
    $Response = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'

    try {
        Switch ($Version) {
            $([Lextm.SharpSnmpLib.VersionCode]::V1) {
                [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk(
                    [Lextm.SharpSnmpLib.VersionCode]::V1, 
                    $EndPoint, 
                    $Community,
                    $OID, 
                    $Response, 
                    $TimeOut, 
                    $WalkMode
                    )
                }
            
            $([Lextm.SharpSnmpLib.VersionCode]::V2) {
                [Lextm.SharpSnmpLib.Messaging.Messenger]::BulkWalk(
                    [Lextm.SharpSnmpLib.VersionCode]::V2,
                    $EndPoint,
                    $Community,
                    $OID,
                    $Response,
                    $TimeOut,
                    $maxRepetitions,
                    $WalkMode,
                    $null,
                    $null
                    );
                }

            }#End Switch

        } 
    catch {
        Write-Error "There was an error requesting $($IP):$($Port) with $Version for $($OID):$([System.Environment]::NewLine)$_"
        #"SNMP Walk error accessing $($IP): $_"
        Return $null
        }
    #Return result
    $Response
} # End function Invoke-SharpSnmpWalk

#Converts to final data
function Convert-SharpSnmpData {
param (
    [Parameter(
        Mandatory = $true,
        HelpMessage = 'OID used for request'
    )]
    [string]$OID,

    [Parameter(
        ValueFromPipeline=$true,
        Mandatory = $true,
        HelpMessage = 'Request data passed from Optimize-SharpSnmpWalkResult or Convert-SharpSnmpWalkToTable'
    )]
    [PSObject]$Data,
    
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'IP of device returned data, if not supplied defaults to 0.0.0.0'
    )]
    [string]$Source = '0.0.0.0'


    )
#    end {
    switch -Regex ($OID) {
        
        #START
        #qBridgeMib
        #dot1qTpFdbTable
        #'1.3.6.1.2.1.17.7.1.2.2.1.2'
        '^\.?1\.3\.6\.1\.2\.1\.17\.7\.1\.2\.2\.1\.2' {
            
            #$OIDRegex = '^\.?(?<OID>' + ( $OID -replace '\.','\.' ) + ')\.(?<VLAN>\d+)\.(?<DecimalMAC>.+)'

            foreach ($entry in $data) {
                if ($entry -eq 0) {continue}
                $Out = $entry.cOID -split '\.' | % { '{0:X2}' -f [int]$_} 
                $MAC = $Out[0] + $Out[1]+ $Out[2]+ $Out[3]+ $Out[4]+ $Out[5]
                    
                New-Object PSObject -Property @{
                    Source = $Source
                    dot1qTpFdbAddress = $MAC
                    VLAN = [int]($entry.Entry)
                    dot1dTpFdbPort = $entry.Data.ToString()

                    } | select Source, dot1qTpFdbAddress, VLAN, dot1dTpFdbPort
                #$PortName = $DataTablePorts.Select("Source = '" + $Source + "' AND Port = '" + $entry.Data.ToString() +"'" )
                }#End %


            } #End '1.3.6.1.2.1.17.7.1.2.2.1.2'    

        #START
        #BridgeMib
        #dot1qTpFdbTable
        #'.1.3.6.1.2.1.17.4.3'
        '^\.?1\.3\.6\.1\.2\.1\.17\.4\.3' {
            
            foreach ($entry in $data) {
                if ($entry -eq 0) {continue}
                
                New-Object PSObject -Property @{
                    Source = $Source
                    dot1qTpFdbAddress = $( 
                        if ($entry.'1'.GetType().Name -eq 'OctetString')  
                            {
                            $Entry.'1'.ToPhysicalAddress()
                            } 
                        else {
                            $Out = $entry.cOID -split '\.' | % { '{0:X2}' -f [int]$_} 
                            $Out[0] + $Out[1]+ $Out[2]+ $Out[3]+ $Out[4]+ $Out[5]
                            }
                        )
                    dot1dTpFdbPort = $entry.'2'.ToString()
                    dot1dTpFdbStatus = $entry.'3'.ToString()
                    } | select Source, dot1qTpFdbAddress, dot1dTpFdbPort, dot1dTpFdbStatus
                }#End %

            } #End '.1.3.6.1.2.1.17.4.3'  


        #START
        #LLDP 
        #1.0.8802.1.1.2.1.4.1
        '^\.?1\.0\.8802\.1\.1\.2\.1\.4\.1' {
            
            #$Array = @()
            
            foreach ($entry in $data) {
                #ugly hacks, as always
                if ($entry.cOID -match '(\d+)\.(\d+)\.(\d+)') {
                    $entry | Add-Member  -Name '1' -Value $Matches[1] -MemberType NoteProperty
                    $entry | Add-Member  -Name '2' -Value $Matches[2] -MemberType NoteProperty
                    $entry | Add-Member  -Name '3' -Value $Matches[3] -MemberType NoteProperty
                    }
                elseif ($entry.cOID -match '\d+') {
                    $entry | Add-Member  -Name '2' -Value $Matches[0] -MemberType NoteProperty
                    }

                $entryProperties = (Get-Member -InputObject $entry -MemberType Property | Select-Object Name) | % {$_.name}
                foreach ($DataCol in $entryProperties) { 

                    Switch ($DataCol) {
                        5 {
                            if (($entry.$DataCol.ToString()).Length -eq 6) {
                                $Entry.$DataCol = $entry.$DataCol.ToHexString()
                                }
                            elseif ($entry.$DataCol.ToString() -match "\:|\.") {
                                $Entry.$DataCol = $entry.$DataCol.ToString() -replace "\:|\."
                                }
                            else {
                                $Entry.$DataCol = $entry.$DataCol.ToHexString()    
                                }
                            }
                        7 {
                            if ($Entry.'6' -eq 3) {
                                $Entry.$DataCol = $entry.$DataCol.ToPhysicalAddress()
                                }
                            else {
                                $Entry.$DataCol = $entry.$DataCol.ToString()
                                }
                            }
                        12 {
                            $Entry.$DataCol = $entry.$DataCol.ToString()
                            }
                        default {
                            $Entry.$DataCol = $entry.$DataCol.ToString()
                            }
                        }#end Switch
                    }#End  %
                $entry | select `
                    Source,
                    @{N = 'lldpRemTimeMark';	E = {$_.1}}, 
                    @{N = 'lldpRemLocalPortNum';	E = {$_.2}}, 
                    @{N = 'lldpRemIndex';	E = {$_.3}}, 
                    @{N = 'lldpRemChassisIdSubtype';	E = {$_.4}}, 
                    @{N = 'lldpRemChassisId';	E = {$_.5}}, 
                    @{N = 'lldpRemPortIdSubtype';	E = {$_.6}}, 
                    @{N = 'lldpRemPortId';	E = {$_.7}}, 
                    @{N = 'lldpRemPortDesc';	E = {$_.8}}, 
                    @{N = 'lldpRemSysName';	E = {$_.9}}, 
                    @{N = 'lldpRemSysDesc';	E = {$_.10}}, 
                    @{N = 'lldpRemSysCapSupported';	E = {$_.11}}, 
                    @{N = 'lldpRemSysCapEnabled';	E = {$_.12}}  
                } #End %           
                
            #$Array | ft
            } #End '1.0.8802.1.1.2.1.4.1'
        
        #START
        #lldpLocPortTable
        #.1.0.8802.1.1.2.1.3.7.1.3
        '^\.?1\.0\.8802\.1\.1\.2\.1\.3\.7\.1\.3' {
            
            foreach ($entry in $data) {
                if ($entry -eq 0) {continue}
                
                New-Object PSObject -Property @{
                    Source = $entry.Source
                    Port = $entry.Entry
                    PortName = $entry.Data.ToString()
                    } | select Source, Port, PortName
                #$PortName = $DataTablePorts.Select("Source = '" + $Source + "' AND Port = '" + $entry.Data.ToString() +"'" )
                }#End %


            } #End lldpLocPortTable
        
        #START
        #RFC-1213, ifTable
        #.1.3.6.1.2.1.2.2

        '^\.?1\.3\.6\.1\.2\.1\.2\.2$' {
            foreach ($entry in $data) {
            $entry | select `
                Source,
                @{Name="ifIndex";	Expression={$_.1}},
                @{Name="ifDescr";	Expression={$_.2}},
                @{Name="ifType";	Expression={$_.3}},
                @{Name="ifMtu";	Expression={$_.4}},
                @{Name="ifSpeed";	Expression={$_.5}},
                @{Name="ifPhysAddress";	Expression={($_.'6').ToPhysicalAddress()}},
                @{Name="ifAdminStatus";	Expression={$_.7}},
                @{Name="ifOperStatus";	Expression={$_.8}},
                @{Name="ifLastChange";	Expression={$_.9}},
                @{Name="ifInOctets";	Expression={$_.10}},
                @{Name="ifInUcastPkts";	Expression={$_.11}},
                @{Name="ifInNUcastPkts";	Expression={$_.12}},
                @{Name="ifInDiscards";	Expression={$_.13}},
                @{Name="ifInErrors";	Expression={$_.14}},
                @{Name="ifInUnknownProtos";	Expression={$_.15}},
                @{Name="ifOutOctets";	Expression={$_.16}},
                @{Name="ifOutUcastPkts";	Expression={$_.17}},
                @{Name="ifOutNUcastPkts";	Expression={$_.18}},
                @{Name="ifOutDiscards";	Expression={$_.19}},
                @{Name="ifOutErrors";	Expression={$_.20}},
                @{Name="ifOutQLen";	Expression={$_.21}},
                @{Name="ifSpecific";	Expression={$_.22}}
                }

            } #End #RFC-1213, ifTable

        #START
        #RFC-1213, ifTable ONLY INTERFACE NAME
        #.1.3.6.1.2.1.2.2.1.2
        
        '^\.?1\.3\.6\.1\.2\.1\.2\.2\.1\.2$' {
            foreach ($entry in $data) {
            $entry | select `
                Source,
                @{Name="ifIndex";	Expression={$_.Entry}},
                @{Name="ifDescr";	Expression={$_.Data}}
                }

            } #End #RFC-1213, ifTable ONLY INTERFACE NAME


        #START
        #RFC-1213, ipAddrTable
        #.1.3.6.1.2.1.4.20

        '^\.?1\.3\.6\.1\.2\.1\.4\.20$' {
            foreach ($entry in $data) {
            $entry | select `
                Source,
                @{Name="ipAdEntAddr";	Expression={$_.1}},
                @{Name="ipAdEntIfIndex";	Expression={$_.2}},
                @{Name="ipAdEntNetMask";	Expression={$_.3}},
                @{Name="ipAdEntBcastAddr";	Expression={$_.4}},
                @{Name="ipAdEntReasmMaxSize";	Expression={$_.5}}
                
                }

            } 
        #END
        #RFC-1213, ipAddrTable
        #.1.3.6.1.2.1.4.20

        #START
        #RFC-1213,  ipNetToMediaTable
        #.1.3.6.1.2.1.4.22

        '^\.?1\.3\.6\.1\.2\.1\.4\.22$' {
            foreach ($entry in $data) {
            $entry | select `
                Source,
                @{Name="ipNetToMediaIfIndex";	Expression={$_.1}},
                @{Name="ipNetToMediaPhysAddress";	Expression={$_.'2'.ToPhysicalAddress()}},
                @{Name="ipNetToMediaNetAddress";	Expression={$_.3}},
                @{Name="ipNetToMediaType";	Expression={$_.4}}
                
                }

            } 
        #END
        #RFC-1213,  ipNetToMediaTable
        #.1.3.6.1.2.1.4.22

        default {
            "Unknown OID! Can't process, dumping as is" | Write-Warning
            $Data
            }
        }#End switch

 #   } #end process
    }

#Helper for Converts walk result to table
function Optimize-SharpSnmpWalkResult {
[CmdletBinding()]
param (
    [Parameter(
        Mandatory = $true,
        HelpMessage = 'OID used for request'
    )]
    [string]$OID,

    [Parameter(
        ValueFromPipeline=$true,
        Mandatory = $true,
        HelpMessage = 'Request data'
    )]
    $Data,
    
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'IP of device returned data, if not supplied defaults to 0.0.0.0'
    )]
    [string]$Source = '0.0.0.0',

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Regex to parse "Entry" part of OID, defaults to "\d+"'
    )]
    [string]$EntryRegex = '\d+'
    ,
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Regex to parse "cOID" part of OID, defaults to ".+"'
    )]
    [string]$cOIDRegex = '.+'


    )

    begin {
        $OIDRegex = '(?<OID>' + ( $OID -replace '^\.' -replace '\.','\.' ) + ')\.?(?<Entry>'+$EntryRegex+')?\.?(?<cOID>'+$cOIDRegex+')?'
        }

    process {
        
        foreach ($entry in $data) {
            if ($entry.GetType().Name -eq 'Int32') {
                #this is value returned by sharpsnmplib, *sometimes* indicating number of records in a table
                #but usually its just a zero
                #but we ignore it anyway, its of no use for us here
                Continue
                }
            else {
                if ($entry.Id.ToString() -match $OIDRegex) {
                    $Object = New-Object PSObject -Property @{
                        Source = $Source
                        OID = $OID
                        Entry = $Matches['Entry']
                        cOID = $Matches['cOID']
                        Data = $entry.Data
                        }
                    $Object | select Source, OID, Entry, cOID, Data
                    }
                }   
            } #End %           

        }

    } #End function Optimize-SNMPWalkResult

#Converts Walk to Table
function Convert-SharpSnmpWalkToTable {
<#
.Synopsis
   Converts result of snmp walk on MIB table to table
.DESCRIPTION
   Convert result of sharpsnmplib Walk method to table
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>

[CmdletBinding()]
param (
    [Parameter(
        Mandatory = $true,
        HelpMessage = 'OID used for request'
    )]
    [string]$OID,

    [Parameter(
        ValueFromPipeline=$false,
        Mandatory = $true,
        HelpMessage = 'Request data'
    )]
    [PSObject]$Data,
    
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'IP of device returned data, if not supplied defaults to 0.0.0.0'
    )]
    [string]$Source = '0.0.0.0',

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'This is additional part at the end of OID, usually ".1", indicating record in table. '
    )]

    [string]$OIDRecordSelector = '.1'
    )
    

    if ($Data[0] -eq 0) {
        #if this is not a real table - no need to process further
        #totally relies on integer passed in $data[0]
        Optimize-SharpSnmpWalkResult -OID ($OID) -Source $Source -Data $Data
        }
    else {
        $TempTable = Optimize-SharpSnmpWalkResult -OID ($OID + $OIDRecordSelector) -Source $Source -Data $Data
        $dataColumns = $TempTable.entry | select -Unique
        $dataRowCount = @($TempTable | ? {$_.entry -eq $DataColumns[0]}).Count

        $DataTable = New-object system.data.datatable("DataTable")
        $new = $DataTable.columns.add("Source")
        $new = $DataTable.columns.add("OID")
        $new = $DataTable.columns.add("cOID")

        foreach ($Column in $dataColumns) {
            $new = $DataTable.columns.add([string]$Column)
            $new.DataType = [Object]
            }

        foreach ($Column in $dataColumns) {
            foreach ($row in @($TempTable | ? {$_.entry -eq $Column})) {
                if ($row.cOID) {
                    $dtRow = @($DataTable.Select("cOID = '" + $row.cOID + "'"))[0]
                    }
                if ($dtRow) {
                    $dtRow.BeginEdit()
                    $dtRow.$($row.Entry) = $row.Data
                    $dtRow.EndEdit()            
                    }
                else {       
                    $dtRow = $DataTable.NewRow()
                    $dtRow.Source = $row.Source
                    $dtRow.OID = $row.OID
                    $dtRow.cOID = $row.cOID
                    $dtRow.$($row.Entry) = $row.Data
                    $DataTable.Rows.Add($dtrow)
                    }
                }
            }
        $DataTable
        }
} #end function Convert-SharpSnmpWalkToTable


###
<#
function Get-SnmpIpAddrTable { 
[CmdletBinding()]
param (
    #SNMP agent address
    [Parameter(
        Mandatory=$true, 
        ValueFromPipeline=$true)]
    [psobject[]]$Agent,

    #Timeout for agent response
    [int]$TimeOut = 3000
    )

begin {
    $OID = '.1.3.6.1.2.1.4.20'
    [int]$AgentsProcessed = 0
    }

process {
    foreach ($thisAgent in $Agent) {
        write-progress -activity 'Get ipAddrTable' -status "Processing $($thisAgent.IP) $($Agent.count)" -PercentComplete ($AgentsProcessed / $Agent.count * 100) -Id 1 
        $Data = Invoke-SnmpWalk -OID $OID -TimeOut $TimeOut @thisAgent
        if ($Data) {
            $ConvertedData = Convert-SharpSnmpWalkToTable -OID $OID -Data $Data -Source $thisAgent.IP
            Process-SharpSnmpData -OID $OID -Data $ConvertedData
            }
        $AgentsProcessed++
        }
    }
 
} #End function Get-SnmpIpAddrTable
#>

function Get-SharpSnmpTable { 
[CmdletBinding()]
param (
    #SNMP agent address
    [Parameter(
        Mandatory=$true, 
        ValueFromPipeline=$true)]
    [psobject[]]$Agent,

    #OID to request
    [Parameter(
        Mandatory=$true)]
    [string]$OID,

    #Process response with Convert-SharpSnmpData
    [switch]$Process = $true,

    #Timeout for agent response
    [int]$TimeOut = 3000
    )

begin {
    [int]$AgentsProcessed = 0
    }

process {
    foreach ($thisAgent in $Agent) {
        write-progress -activity 'Get SNMP Table' -status "Processing $($thisAgent.IP)" -PercentComplete ($AgentsProcessed / $Agent.count * 100) -Id 1 
        $Data = Invoke-SharpSnmpWalk -OID $OID -TimeOut $TimeOut @thisAgent
        if ($Data) {
            $SharpSnmpTable = Convert-SharpSnmpWalkToTable -OID $OID -Data $Data -Source $thisAgent.IP
            if ($Process) {
                Convert-SharpSnmpData -OID $OID -Data $SharpSnmpTable -Source $thisAgent.IP
                }
                else {
                $SharpSnmpTable
                }
            }
        $AgentsProcessed++
        }
    }
 
} #End function Get-SharpSnmpTable

