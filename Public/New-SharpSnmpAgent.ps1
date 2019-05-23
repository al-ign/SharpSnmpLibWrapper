<#
.Synopsis
   Create an object representing the SNMP agent
.DESCRIPTION
   Create an object with all necessary properties to query SNMP agent through SharpSnmpWrapper module
.EXAMPLE
    New-SnmpAgent -Agent 'someagent.example' -Port 163
Call with parameters
.EXAMPLE
    #
    @{ 
        Agent = "192.0.2.15"
        Version = "V1"
        Port = 10161
        Community = "SecureCommunity" 
        Description = "MegaConnect PowerSwitch 1024"
        } | New-SnmpAgent
        
Use the hashtable to populate the properties
.Example
    'agent1.example', 'agent2.example' | New-SharpSnmpAgent -Community 'SecretCommunity' -Port 999 -Version V1
Use the pipeline to define agent names with common settings
#>
function New-SharpSnmpAgent {
[CmdletBinding(DefaultParameterSetName='Default')]
[Alias('New-SnmpAgent')]
param (
    # Agent DNS name
    [Parameter(
        ParameterSetName='Default',
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=0)]
    [string]$Agent = '127.0.0.1',

    # SNMP port
    [Parameter(
        ValueFromPipelineByPropertyName=$true
        )]
    [ValidateRange(0,65535)]
    [int]$Port = 161,

    # SNMP Community
    [Parameter(
        ValueFromPipelineByPropertyName=$true
        )]
    [string]$Community = 'public', 
    
    # SNMP Version
    [Parameter(
        ValueFromPipelineByPropertyName=$true
        )]
    [ValidateSet([Lextm.SharpSnmpLib.VersionCode]::V1, 
        [Lextm.SharpSnmpLib.VersionCode]::V2,
        [Lextm.SharpSnmpLib.VersionCode]::V2U
        )]
    $Version = [Lextm.SharpSnmpLib.VersionCode]::V2,
    
    # Device description (not parsed)
    [Parameter(
        ValueFromPipelineByPropertyName=$true
        )]
    [string]$Description
    )
    
    process {
    
        if ($input) {
            foreach ($object in $input) {
                switch ($object.GetType().Name) {
                    'String' {
                        #convert to hashtable if only the agent name is present
                        $object = @{Agent=$object}
                        }
                    }

                #add the default parameters

                if ([String]::IsNullOrEmpty($object.Port)) {
                    $object.Add('Port',$Port)
                    }

                if ([String]::IsNullOrEmpty($object.Version)) {
                    $object.Add('Version',$Version)
                    }

                if ([String]::IsNullOrEmpty($object.Community)) {
                    $object.Add('Community',$Community)
                    }

                [pscustomobject][ordered]@{
                    Agent = $object.Agent
                    Port = $object.Port
                    Version = $object.Version
                    Community = $object.Community
                    Description = $object.Description
                    }
                }
            }
        else {
            [pscustomobject][ordered]@{
                Agent = $Agent
                Port = $Port
                Version = $Version
                Community = $Community
                Description = $Description
                }
            }
        }
    } # End function New-SharpSnmpAgent
  