function Get-SharpSnmpTable {
[CmdletBinding()]
[Alias('Get-SnmpTable')]
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
        Write-Progress -Activity $("Get SNMP{0} from {1}" -f $thisAgent.Version, $thisAgent.Agent.ToString()) -Status $('Get table for OID {0}' -f $OID.ToString())
        $SNMP = Get-SharpSnmpWalk -OID $OID -AgentObject $thisAgent
        if ($SNMP) {
            ConvertFrom-SharpSnmpWalk -OID $OID -SNMP $SNMP | Convert-SharpSnmpData
            }
        else {
            Write-Warning -Message ("Can't process SNMP response on {0} - no data!" -f $thisAgent.Agent)
            }
        } # End %    
    }# End process block
} # End function Get-SharpSnmpTable
