<#
.Synopsis
   Get the MAC address table from SNMP capabale device
.DESCRIPTION
   Get the BRIDGE-MIB::dot1dTpFdbTable table listing all known MAC addressses.
   Supports weird Cisco way with community names per VLAN
.EXAMPLE
   $agent | Get-SharpSnmpTransparentBridgeForwardingTable
#>
function Get-SharpSnmpTransparentBridgeForwardingTable  {
    [CmdletBinding()]
    [Alias()]
    param (
    [Parameter(
        Mandatory=$true, 
        ValueFromPipeline=$true,
        HelpMessage = 'SNMP Agent object from New-SharpSnmpAgent',
        ParameterSetName='AgentObject',
        Position=0
        )]
    [PSObject[]]$AgentObject
    )

    Begin {
        #system.data.datatable will be much faster than usual Where-Object or .Where()
        $dtInterfaceNames = New-object system.data.datatable("InterfaceNames")
        $dtTpFdb = New-object system.data.datatable("TrasnparentBridgeForwardingTable")
        
        #precreate the columns
        $new = $dtTpFdb.Columns.Add("Source")
        $new = $dtTpFdb.Columns.Add("PortName")
        }

    Process {
        $TpFdb = foreach ($thisAgent in $AgentObject) {
            Write-Debug ('Processing thisAgent: {0}' -f $thisAgent.Agent)
            $TpDbType = 'Skip'

            #detect supported TpDb type
            
            # BRIDGE-MIB support
            $thisResponse = $thisAgent | Get-SharpSnmp -OID '.1.3.6.1.2.1.17.1.3.0'
            if ($thisResponse.Data.TypeCode -ne 'NoSuchObject') {
                $TpDbType = 'BRIDGE'
                }

            # Q-BRIDGE-MIB support
            $thisResponse = $thisAgent | Get-SharpSnmp -OID '.1.3.6.1.2.1.17.7.1.1.1.0'
            if ($thisResponse.Data.TypeCode -ne 'NoSuchObject') {
                $TpDbType = 'Q-BRIDGE'
                }
        
            switch ($TpDbType) {
                'Q-BRIDGE' {
                    $OID = '.1.3.6.1.2.1.17.7.1.2.2'
                    }
                'BRIDGE' {
                    $OID = '.1.3.6.1.2.1.17.4.3'
                    }
                'Skip' {
                    Write-Warning -Message $('TpFdb is not supported on {0}' -f $thisAgent.Agent)
                    }
                }

            #if TpDbType can't be determined - skip the agent altogether
            if ($TpDbType -eq 'Skip') {
                continue
                }

            #Get interface names from IF-MIB::ifTable

            $interfaceNames = $thisAgent | Get-SharpSnmpTable -OID '.1.3.6.1.2.1.2.2.1.2'

            ConvertTo-DataTable -DataTable $dtInterfaceNames -Array $interfaceNames -SuppressWarnings:$true

            #Get the TpDb
            $thisTpFdb = $thisAgent | Get-SharpSnmpTable -OID $OID

            #if table is empty
            if ($thisTpFdb.Count -eq 0) {

                #get device description
                $sysDescr = $thisAgent | Get-SharpSnmp -OID '.1.3.6.1.2.1.1.1.0' 

                switch -Regex ($sysDescr) {
                
                    'cisco' {
                        # CISCO-VTP-MIB::vtpVlanState
                        $vtpVlanState = $thisAgent | Get-SharpSnmpTable -OID '1.3.6.1.4.1.9.9.46.1.3.1.1.2.1'

                        foreach ($thisVLAN in $vtpVlanState) {
    
                            $tmpAgent = $thisAgent | New-SharpSnmpAgent
                            $tmpAgent.Community = '{0}@{1}' -f $tmpAgent.Community, $thisVLAN.Index
                            $ciscoVlan = $tmpAgent |  Get-SharpSnmpTable -OID $OID

                            foreach ($entry in $ciscoVlan) {
                                Select-Object -InputObject $entry -Property Source,
                                @{N='Address';E={$_.dot1dTpFdbAddress}},
                                @{N='Port';E={$_.dot1dTpFdbPort}},
                                @{N='Status';E={$_.dot1dTpFdbStatus}},
                                @{N='VLAN';E={$thisVLAN.Index}}
                                }
                            }
                        } # End cisco

                    default {
                        Write-Warning -Message $('BRIDGE-MIB::dot1dTpFdbTable is not supported or empty on {0}' -f $thisAgent.Agent)
                        }

                    } # End switch

                }
            else {
                # reformat the messages
                switch ($TpDbType) {
                    'Q-BRIDGE' {
                        foreach ($entry in $thisTpFdb) {
                            Select-Object -InputObject $entry -Property Source,
                            @{N='Address';E={$_.dot1qTpFdbAddress}},
                            @{N='Port';E={$_.dot1qTpFdbPort}},
                            @{N='Status';E={$_.dot1qTpFdbStatus}},
                            VLAN
                            }
                        }
                    'BRIDGE' {
                        foreach ($entry in $thisTpFdb) {
                            Select-Object -InputObject $entry -Property Source,
                            @{N='Address';E={$_.dot1dTpFdbAddress}},
                            @{N='Port';E={$_.dot1dTpFdbPort}},
                            @{N='Status';E={$_.dot1dTpFdbStatus}}
                            }
                        }
                    }
                
                }
            }

        # add the results to the datatable
        if ($TpFdb.Count -gt 0) {
            ConvertTo-DataTable -DataTable $dtTpFdb  -Array $TpFdb -SuppressWarnings:$true
            }

        } # End process

    End {
        # select *
        foreach ($Row in $dtTpFdb.Select()) {
            # search interface table for matching source and index
            $Query = "[Source] = '{0}' AND [Index] = '{1}'" -f $row.Source, $row.Port

            # select is always returning an array
            $select = ($dtInterfaceNames.Select($Query))[0]
            if ( $select ) {
                $Row.BeginEdit()
                $row.PortName = $select.Data
                $row.EndEdit()
                }
            }
        $dtTpFdb
        } # End End
}
