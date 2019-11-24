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
                if ($MemberType -eq 'Lextm.SharpSnmpLib.Variable') {
                    $Entry = $Entry | ConvertFrom-SharpSnmpWalk -OID $Matches[0]
                    }
                    
                $entry | select `
                    Source,
                    @{Name="ipNetToMediaIfIndex";	Expression={$_.1}},
                    @{Name="ipNetToMediaPhysAddress";	Expression={$_.'2'.ToPhysicalAddress()}},
                    @{Name="ipNetToMediaNetAddress";	Expression={$_.3}},
                    @{Name="ipNetToMediaType";	Expression={$_.4}}
                    
                <#
                $obj = [pscustomobject][ordered]@{
                    Source = $entry.Source
                    ipNetToMediaIfIndex = $entry.'1'.ToInt32()
                    ipNetToMediaPhysAddress = [string]''
                    ipNetToMediaNetAddress = [string]''
                    ipNetToMediaType = $entry.'4'.ToInt32()
                    }#End pscustomobject

                try {
                    $obj.ipNetToMediaPhysAddress = $entry.'2'.ToPhysicalAddress().ToString()
                    }
                catch {
                    }
                try {
                    $obj.ipNetToMediaNetAddress = $entry.'3'.ToString()
                    }
                catch {
                    }
                $obj
                #>
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
                ConvertFrom-OID.1.0.8802.1.1.2.1.4.1 -SNMP $SNMP
                }

            #START
            #LLDP 
            #1.0.8802.1.1.2.1.3.7
            '^\.?1\.0\.8802\.1\.1\.2\.1\.3\.7' {
                ConvertFrom-OID.1.0.8802.1.1.2.1.3.7 -SNMP $SNMP
                }

            #START
            #BridgeMib
            #dot1qTpFdbTable
            #'.1.3.6.1.2.1.17.7.1.2.2'
            '^\.?1\.3\.6\.1\.2\.1\.17\.7\.1\.2\.2' {
                
                $Split = $entry.Index -match '(?:(?<vlan>\d+)\.)?(\d+)\.(\d+)\.(\d+)\.(\d+)\.(\d+)\.(\d+)$'
                $Address = ('{0:X2}' -f [int]$Matches[1] + '{0:X2}' -f [int]$Matches[2] + '{0:X2}' -f [int]$Matches[3] + '{0:X2}' -f [int]$Matches[4] + '{0:X2}' -f [int]$Matches[5] + '{0:X2}' -f [int]$Matches[6]) 
                if ($Matches.vlan) { 
                    [int]$VLAN = $Matches.vlan 
                    } 
                else {
                    $VLAN = 0
                    }

                $entry | select `
                    Source,
                    @{Name='dot1qTpFdbAddress';	Expression={$Address}},
                    @{Name='dot1qTpFdbPort'; Expression = {$entry.'2'.ToInt32()}},
                    @{Name='dot1qTpFdbStatus'; Expression = {$entry.'3'.ToInt32()}},
                    @{Name='VLAN'; Expression = {$VLAN}}
                        
                } #End '.1.3.6.1.2.1.17.7.1.2.2'

            #START
            #BridgeMib
            #dot1dTpFdbTable
            ##1.3.6.1.2.1.17.4.3
            '^\.?1\.3\.6\.1\.2\.1\.17\.4\.3' {
<#                
                $Split = $entry.Index -match '(?:(?<vlan>\d+)\.)?(\d+)\.(\d+)\.(\d+)\.(\d+)\.(\d+)\.(\d+)$'
                $Address = ('{0:X2}' -f [int]$Matches[1] + '{0:X2}' -f [int]$Matches[2] + '{0:X2}' -f [int]$Matches[3] + '{0:X2}' -f [int]$Matches[4] + '{0:X2}' -f [int]$Matches[5] + '{0:X2}' -f [int]$Matches[6]) 
                if ($Matches.vlan) { 
                    [int]$VLAN = $Matches.vlan 
                    } 
                else {
                    $VLAN = 0
                    }
#>
                $entry | select `
                    Source,
                    @{Name='dot1dTpFdbAddress';	Expression={$Entry.'1'.ToPhysicalAddress()}},
                    @{Name='dot1dTpFdbPort'; Expression = {$entry.'2'.ToInt32()}},
                    @{Name='dot1dTpFdbStatus'; Expression = {$entry.'3'.ToInt32()}}
                    
                        
                } #End '.1.3.6.1.2.1.17.4.3'  

            #'.1.3.6.1.2.1.1'
            '^\.?1\.3\.6\.1\.2\.1\.1$' {
                if ($MemberType -eq 'Lextm.SharpSnmpLib.Variable') {
                    $Entry = $Entry | ConvertFrom-SharpSnmpWalk -OID $Matches[0]
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

            #'.1.0.8802.1.1.2.1.3.2.0'
            '^\.?1\.0\.8802\.1\.1\.2\.1\.3\.2\.0' {
                try {
                    if ($Entry.Data.ToString().Length -eq 6) {
                        Select-Object -InputObject $Entry -Property Source,
                            Id,
                            @{Name='Data'; Expression = {$Entry.Data.ToPhysicalAddress()}}
                        }
                    else {
                        $Entry
                        }
                    }
                catch {
                    $Entry
                    }
                }

            #START
            #FJDARY-E150.MIB
            #fjdaryDiskTable
            #'.1.3.6.1.4.1.211.1.21.1.150.2.19.2'
            '^\.?1\.3\.6\.1\.4\.1\.211\.1\.21\.1\.150\.2\.19\.2' {
                ConvertFrom-OID.1.3.6.1.4.1.211.1.21.1.150.2.19.2 -SNMP $Entry
                }

            #START
            #FJDARY-E150.MIB
            #fjdarySspMachineId
            #'.1.3.6.1.4.1.211.1.21.1.150.1.1.0'
            '^\.?1\.3\.6\.1\.4\.1\.211\.1\.21\.1\.150\.1\.1\.0' {
                ConvertFrom-OID.1.3.6.1.4.1.211.1.21.1.150.1.1.0 -SNMP $Entry
                }


            default {
                $Entry
                }
            } # End switch
        #$SNMP
        }
    }



    } # End function
