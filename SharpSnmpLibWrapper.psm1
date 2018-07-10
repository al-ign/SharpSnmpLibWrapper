#NEW SharpSnmpLibWrapper

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
    } # End function New-SharpSnmpAgent

function Get-SharpSnmp {
[CmdletBinding()]
param (
    [Parameter(
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ParameterSetName='AgentObject',
        Position=0
        )]
    [System.Collections.Hashtable[]]$Agent,

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'SNMP Agent IP address',
        ParameterSetName='DirectAddress',
        Position=0
        )]
    [string]$IP,

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'OID to request',
        Position=1
    )]
    [string[]]$OID,
    
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SNMP Agent Community',
        ParameterSetName='DirectAddress',
        Position=2
    )]
    [string]$Community = 'public', 
    
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SNMP Agent UDP Port',
        ParameterSetName='DirectAddress',
        Position=3
    )]
    [ValidateRange(0,65535)]
    [int]$Port = 161,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SNMP Agent Version',
        ParameterSetName='DirectAddress',
        Position=4
    )]
    [Lextm.SharpSnmpLib.VersionCode]$Version = 'V2',

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Time out value'
    )]
    [int]$TimeOut = 3000,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Add source address to output'
    )]
    [switch]$AddSource = $true

)
begin {

    if ($PSCmdlet.ParameterSetName -eq 'DirectAddress') {
        $Agent = @(New-SharpSnmpAgent -Agent $IP -Port $Port -Community $Community -Version $Version)
        }

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
    }#End begin block

process {
    foreach ($thisAgent in $Agent) {
    
        #try to parse IP, if unsuccessful try to resolve, else fail to next member of agent array
        try {
            $endpoint = New-Object Net.IpEndPoint ([Net.IPAddress]$thisAgent.IP), $thisAgent.Port
            }
        catch {
            try {
                #get the first resolved ip, it doesn't make sense to query multiple addresses of the same target
                $Resolve = @([System.Net.Dns]::GetHostAddresses( $thisAgent.IP ).IPAddressToString)[0]
                $endpoint = New-Object Net.IpEndPoint ([Net.IPAddress]$Resolve), $thisAgent.Port
                }
            catch {
                Write-Warning "Can't resolve host $($thisAgent.IP): $_"
                continue
                }
            
            if (-not $endpoint) {
                Write-Warning "Can't process ip $($thisAgent.IP): $_"
                continue
                }
            }
        

        try {
            $message = [Lextm.SharpSnmpLib.Messaging.Messenger]::Get(
                $thisAgent.Version, 
                $endpoint, 
                $thisAgent.Community, 
                $DataPayload, 
                $TimeOut
                )
            } 
        catch {
            Write-Warning "SNMP Get error accessing $($thisAgent.IP): $_"
            return
            }
        if ($AddSource) {
            $message | Add-Member  -Name Source -Value $thisAgent.ip -MemberType NoteProperty -PassThru
            }
        else {
            $message
            }
        }
    }#End process block

} # End function Get-SharpSnmp

function Get-SharpSnmpWalk {
[CmdletBinding()]
param (
    [Parameter(
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ParameterSetName='AgentObject',
        Position=0
        )]
    [System.Collections.Hashtable[]]$Agent,

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'SNMP Agent IP address',
        ParameterSetName='DirectAddress',
        Position=0
        )]
    [string]$IP,

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'OID to request',
        Position=1
    )]
    [string]$OID,
    
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SNMP Agent Community',
        ParameterSetName='DirectAddress',
        Position=2
    )]
    [string]$Community = 'public', 
    
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SNMP Agent UDP Port',
        ParameterSetName='DirectAddress',
        Position=3
    )]
    [ValidateRange(0,65535)]
    [int]$Port = 161,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SNMP Agent Version',
        ParameterSetName='DirectAddress',
        Position=4
    )]
    [Lextm.SharpSnmpLib.VersionCode]$Version = 'V2',


    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Time out value'
    )]
    [int]$TimeOut = 3000,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Max Repetitions (applicable for V2)'
    )]
    [int]$MaxRepetitions = 50,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Max Repetitions (applicable for V2)'
    )]
    [Lextm.SharpSnmpLib.Messaging.WalkMode]$WalkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Add source address to output'
    )]
    [switch]$AddSource = $true
)

begin {

    if ($PSCmdlet.ParameterSetName -eq 'DirectAddress') {
        $Agent = @(New-SharpSnmpAgent -Agent $IP -Port $Port -Community $Community -Version $Version)
        }
    
    #fail early
    try {
        $OID = [Lextm.SharpSnmpLib.ObjectIdentifier]$OID
        }
    catch {
        Write-Warning "SNMP Error initializing OID object $($OID): $_"
        break
        }

    }# End begin block

process {
    foreach ($thisAgent in $Agent) {
    
        #try to parse IP, if unsuccessful try to resolve, else fail to next member of agent array
        try {
            $endpoint = New-Object Net.IpEndPoint ([Net.IPAddress]$thisAgent.IP), $thisAgent.Port
            }
        catch {
            try {
                #get the first resolved ip, it doesn't make sense to query multiple addresses of the same target
                $Resolve = @([System.Net.Dns]::GetHostAddresses( $thisAgent.IP ).IPAddressToString)[0]
                $endpoint = New-Object Net.IpEndPoint ([Net.IPAddress]$Resolve), $thisAgent.Port
                }
            catch {
                Write-Warning "Can't resolve host $($thisAgent.IP): $_"
                continue
                }
            
            if (-not $endpoint) {
                Write-Warning "Can't process ip $($thisAgent.IP): $_"
                continue
                }
            }

    # Create list for results
    $Response = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'

    try {
        Switch ($Version) {
            $([Lextm.SharpSnmpLib.VersionCode]::V1) {
                
                $MethodResult = [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk(
                    [Lextm.SharpSnmpLib.VersionCode]::V1, 
                    $EndPoint, 
                    $thisAgent.Community,
                    $OID, 
                    $Response, 
                    $TimeOut, 
                    $WalkMode
                    )
                }
            
            $([Lextm.SharpSnmpLib.VersionCode]::V2) {

                $MethodResult = [Lextm.SharpSnmpLib.Messaging.Messenger]::BulkWalk(
                    [Lextm.SharpSnmpLib.VersionCode]::V2,
                    $EndPoint,
                    $thisAgent.Community,
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
        Write-Error "There was an error requesting $($thisAgent.IP):$($thisAgent.Port) with $thisAgent.Version for $($OID):$([System.Environment]::NewLine)$_"
        #"SNMP Walk error accessing $($IP): $_"
        Return $null
        }

    #Return result
    if ($AddSource) {
        if ($MethodResult -ne 0) {
            $MethodResult
            }
        $Response | Add-Member  -Name Source -Value $thisAgent.ip -MemberType NoteProperty -PassThru
        }
    else {
        if ($MethodResult -ne 0) {
            $MethodResult
            }
        $Response
        }
    } #End %
    }# End process block
} # End function Get-SharpSnmpWalk

function Get-SharpSnmpTable {
[CmdletBinding()]
param (
    [Parameter(
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ParameterSetName='AgentObject',
        Position=0
        )]
    [System.Collections.Hashtable[]]$Agent,

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'SNMP Agent IP address',
        ParameterSetName='DirectAddress',
        Position=0
        )]
    [string]$IP,

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'OID to request',
        Position=1
    )]
    [string]$OID,
    
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SNMP Agent Community',
        ParameterSetName='DirectAddress',
        Position=2
    )]
    [string]$Community = 'public', 
    
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SNMP Agent UDP Port',
        ParameterSetName='DirectAddress',
        Position=3
    )]
    [ValidateRange(0,65535)]
    [int]$Port = 161,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SNMP Agent Version',
        ParameterSetName='DirectAddress',
        Position=4
    )]
    [Lextm.SharpSnmpLib.VersionCode]$Version = 'V2',


    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Time out value'
    )]
    [int]$TimeOut = 3000,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Max Repetitions (applicable for V2)'
    )]
    [int]$MaxRepetitions = 50,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Max Repetitions (applicable for V2)'
    )]
    [Lextm.SharpSnmpLib.Messaging.WalkMode]$WalkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Add source address to output'
    )]
    [switch]$AddSource = $true
)

begin {

    if ($PSCmdlet.ParameterSetName -eq 'DirectAddress') {
        $Agent = @(New-SharpSnmpAgent -Agent $IP -Port $Port -Community $Community -Version $Version)
        }
    
    #fail early
    try {
        $OID = [Lextm.SharpSnmpLib.ObjectIdentifier]$OID
        }
    catch {
        Write-Warning "SNMP Error initializing OID object $($OID): $_"
        break
        }
        
    }# End begin block

process {
    foreach ($thisAgent in $Agent) {
        $thisAgent | Get-SharpSnmpWalk -OID $OID  | ConvertFrom-SharpSnmpWalk -OID $OID | Convert-SharpSnmpData
        } # End %    
    }# End process block
} # End function Get-SharpSnmpTable

function ConvertFrom-SharpSnmpWalk { 
[CmdletBinding()]
param (
    [Parameter(
        Mandatory=$true, 
        ValueFromPipeline=$true,
        HelpMessage = 'SNMP Data',
        ParameterSetName='Default',
        Position=0
        )]
    [psobject]$SNMP,

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'OID used for request',
        Position=1
    )]
    [string]$OID
)
begin {
        
    $OIDRegex = '(?<Id>' + ( $OID -replace '^\.' -replace '\.','\.' ) + ')\.?(?<Entry>\d+)\.(?<Column>\d+)\.?(?<Index>.+)?'
    $DataTable = New-object system.data.datatable("ConvertFrom-SharpSnmpWalk")
    $new = $DataTable.columns.add("Source")
    $new = $DataTable.columns.add("Id")
    $new = $DataTable.columns.add("Index")

    } # End begin block

process {
    
    #'SNMP count: ' + $SNMP.count | Write-Debug
    #'Input count: ' + $input.Count | Write-Debug

    foreach ($Entry in $Snmp) {
    
        if ($Entry.GetType().Name -eq 'Int32') {
            continue
            }
        
        if ($entry.Id.ToString() -match $OIDRegex) {
            if ($DataTable.Columns | ? {$_.ColumnName -eq $Matches.Column}) {
                #column exists
                }
            else {
                $new = $DataTable.columns.add([string]$Matches.Column,[Object])
                #'Column ' + $Matches.Column + ' was created' | Write-Debug
                }
            $dtRow = @($DataTable.Select("[Index] = '" + $Matches.index + "'"))[0]
                    
                if ($dtRow) {
                    $dtRow.BeginEdit()
                    $dtRow.$($Matches.Column) = $entry.Data
                    $dtRow.EndEdit()            
                    }
                else {       
                    $dtRow = $DataTable.NewRow()
                    $dtRow.Source = $entry.Source
                    $dtRow.Id = $Matches.Id
                    if ($Matches.Index) {
                        $dtRow.Index = $Matches.Index
                        }
                    else {
                        $dtRow.Index = $Matches.Entry
                        }
                    $dtRow.$($Matches.Column) = $entry.Data
                    $DataTable.Rows.Add($dtrow)
                    }
            }
        } # End %    
    } # End process block

end {
    $DataTable
    $DataTable.Dispose()
    } # End end block
    
} # End function ConvertFrom-SharpSnmpWalk

function Convert-SharpSnmpData {
param (
<#
    [Parameter(
        Mandatory = $true,
        HelpMessage = 'OID used for request'
    )]
    [string]$OID,
    #>
    [Parameter(
        ValueFromPipeline=$true,
        Mandatory = $true,
        HelpMessage = 'Request data passed from Optimize-SharpSnmpWalkResult or Convert-SharpSnmpWalkToTable'
    )]
    [PSObject[]]$SNMP

    )

process {
    #Write-Debug $input.Count
    foreach ($Entry in $SNMP) {

        $MemberType = (Get-Member -InputObject $Entry).TypeName
        #'Entry.Count: ' + $Entry.Count | Write-Debug
        #'MemberType: ' + $MemberType | Write-Debug 
        #$PSCmdlet.MyInvocation.InvocationName  | Write-Debug
        switch -Regex ($Entry.Id.ToString()) {

            #START
            #RFC-1213, ipNetToMediaTable
            #.1.3.6.1.2.1.4.22            
            '^\.?1\.3\.6\.1\.2\.1\.4\.22' {
                if ($MemberType -eq 'Lextm.SharpSnmpLib.Variable') {$Entry = $Entry | ConvertFrom-SharpSnmpWalk -OID $Matches[0]
                    }
                $entry | select `
                    Source,
                    @{Name="ipNetToMediaIfIndex";	Expression={$_.1}},
                    @{Name="ipNetToMediaPhysAddress";	Expression={$_.'2'.ToPhysicalAddress()}},
                    @{Name="ipNetToMediaNetAddress";	Expression={$_.3}},
                    @{Name="ipNetToMediaType";	Expression={$_.4}}
                }

            #START
            #RFC-1213, ifTable
            #.1.3.6.1.2.1.2.2
            '^\.?1\.3\.6\.1\.2\.1\.2\.2$' {
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

            #START
            #LLDP 
            #1.0.8802.1.1.2.1.4.1
            '^\.?1\.0\.8802\.1\.1\.2\.1\.4\.1' {
                $Split = $Entry.Index -split '\.'
                $Entry = $Entry | select `
                    Source,
                    @{N = 'lldpRemTimeMark';	E = {$Split[0]}}, 
                    @{N = 'lldpRemLocalPortNum';	E = {$Split[1]}}, 
                    @{N = 'lldpRemIndex';	E = {$Split[2]}}, 
                    @{N = 'lldpRemChassisIdSubtype';	E = {$_.4}}, 
                    @{N = 'lldpRemChassisId';	E = {$_.5}}, 
                    @{N = 'lldpRemPortIdSubtype';	E = {$_.6}}, 
                    @{N = 'lldpRemPortId';	E = {$_.7}}, 
                    @{N = 'lldpRemPortDesc';	E = {$_.8}}, 
                    @{N = 'lldpRemSysName';	E = {$_.9}}, 
                    @{N = 'lldpRemSysDesc';	E = {$_.10}}, 
                    @{N = 'lldpRemSysCapSupported';	E = {$_.11}}, 
                    @{N = 'lldpRemSysCapEnabled';	E = {$_.12}}  
                    
                switch ($Entry.lldpRemPortIdSubtype) {
                    3 {
                        $Entry.lldpRemPortId = $Entry.lldpRemPortId.ToPhysicalAddress() -replace "\:|\."
                        }
                    } # End switch

                switch ($Entry.lldpRemChassisIdSubtype) {
                    4 {
                        if (($Entry.lldpRemChassisId -match "\:|\.") -and ($Entry.lldpRemChassisId.Length -ne 6)) {
                            $Entry.lldpRemChassisId = $Entry.lldpRemChassisId -replace "\:|\."
                            }
                        else {
                            $Entry.lldpRemChassisId = $Entry.lldpRemChassisId.ToPhysicalAddress() -replace "\:|\."
                            }
                        }
                    } # End switch
                #output
                $Entry
                }


            '^\.?1\.3\.6\.1\.2\.1\.1$' {
                if ($MemberType -eq 'Lextm.SharpSnmpLib.Variable') {$Entry = $Entry | ConvertFrom-SharpSnmpWalk -OID $Matches[0]
                    }
                switch ($Entry.Index) {
                    1 {$Entry.Id = 'sysDescr'}
                    2 {$Entry.Id = 'sysObjectID'}
                    3 {$Entry.Id = 'sysUpTime'}
                    4 {$Entry.Id = 'sysContact'}
                    5 {$Entry.Id = 'sysName'}
                    6 {$Entry.Id = 'sysLocation'}
                    7 {$Entry.Id = 'sysServices'}
                
                    } # End switch
                $Entry
                
                }
            default {
                $Entry
                }
            } # End switch
        #$SNMP
        }
    }



    } # End function
