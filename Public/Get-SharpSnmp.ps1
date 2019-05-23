function Get-SharpSnmp {
[CmdletBinding()]
[Alias('Get-Snmp')]
param (
    [Parameter(
        Mandatory=$true, 
        ValueFromPipeline=$true,
        HelpMessage = 'SNMP Agent object from New-SharpSnmpAgent',
        ParameterSetName='AgentObject',
        Position=0
        )]
    [PSObject[]]$AgentObject,

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'SNMP Agent address',
        ParameterSetName='DirectAddress',
        Position=0
        )]
    [string]$Agent,

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
        $splat = @{
            Agent = $Agent
            Version = $Version
            Port = $Port
            Community = $Community
            } 
        $AgentObject = @(New-SharpSnmpAgent @splat)
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
    foreach ($thisAgent in $AgentObject) {
    
        #try to parse IP, if unsuccessful try to resolve, else fail to next member of agent array
        try {
            $endpoint = New-Object Net.IpEndPoint ([Net.IPAddress]$thisAgent.Agent), $thisAgent.Port
            }
        catch {
            try {
                #get the first resolved ip, it doesn't make sense to query multiple addresses of the same target
                $Resolve = @([System.Net.Dns]::GetHostAddresses( $thisAgent.Agent ).IPAddressToString)[0]
                $endpoint = New-Object Net.IpEndPoint ([Net.IPAddress]$Resolve), $thisAgent.Port
                }
            catch {
                Write-Warning "Can't resolve host $($thisAgent.Agent): $_"
                continue
                }
            
            if (-not $endpoint) {
                Write-Warning "Can't process ip $($thisAgent.Agent): $_"
                continue
                }
            }
        

        try {
            #"try [Lextm.SharpSnmpLib.Messaging.Messenger]::Get" | Write-Verbose
            $message = [Lextm.SharpSnmpLib.Messaging.Messenger]::Get(
                $thisAgent.Version, 
                $endpoint, 
                $thisAgent.Community, 
                $DataPayload, 
                $TimeOut
                )
            } 
        catch {
            Write-Warning "SNMP Get error accessing $($thisAgent.Agent): $_"
            return
            }
        if ($AddSource) {
            $message | Add-Member  -Name Source -Value $thisAgent.Agent -MemberType NoteProperty -PassThru
            }
        else {
            $message
            }
        }
    }#End process block

} # End function Get-SharpSnmp
