function Get-SharpSnmpWalk {
[CmdletBinding()]
[Alias('Get-SnmpWalk','Walk-Snmp')]
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
        HelpMessage = 'Walk Mode'
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
        $splat = @{
            Agent = $Agent
            Version = $Version
            Port = $Port
            Community = $Community
            } 
        $AgentObject = @(New-SharpSnmpAgent @splat)
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

    # Create list for results
    $Response = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'

    try {
        Write-Progress -Activity $("Get SNMP{0} from {1}" -f $thisAgent.Version, $thisAgent.Agent.ToString()) -Status $('Walk for OID {0}' -f $OID.ToString())
        Switch ($Version) {
            $([Lextm.SharpSnmpLib.VersionCode]::V1) {
                #"try [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk" | Write-Debug
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
                #"try [Lextm.SharpSnmpLib.Messaging.Messenger]::BulkWalk" | Write-Debug
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
        Write-Error ('There was an error performing {2} request to {0}:{1} for OID {3}:{4}{5}' -f $thisAgent.Agent, $thisAgent.Port, $thisAgent.Version, $OID, [System.Environment]::NewLine, $_)
        #"SNMP Walk error accessing $($IP): $_"
        Return $null
        }

    #Return result
    if ($AddSource) {
        if ($MethodResult -ne 0) {
            $MethodResult
            }
        $Response | Add-Member  -Name Source -Value $thisAgent.Agent -MemberType NoteProperty -PassThru
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
