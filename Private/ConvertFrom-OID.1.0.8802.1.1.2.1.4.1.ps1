<#
.Synopsis
   Convert lldpRemTable 1.0.8802.1.1.2.1.4.1 (LLDP-MIB.MIB)
.DESCRIPTION
   Convert lldpRemTable 1.0.8802.1.1.2.1.4.1 (LLDP-MIB.MIB)
.EXAMPLE
   $SNMP | ConvertFrom-OID.1.0.8802.1.1.2.1.4.1 | ft
.EXAMPLE
   ConvertFrom-OID.1.0.8802.1.1.2.1.4.1 -SNMP $SNMP | ft
#>
function ConvertFrom-OID.1.0.8802.1.1.2.1.4.1 {
[CmdletBinding()]
[OutputType([pscustomobject])]
Param (
    # Input Data
    [Parameter(Mandatory=$true,
                ValueFromPipeline=$true,
                Position=0)]
    $SNMP
)

Begin {
    }

Process {

    foreach ($Entry in $SNMP) {
        $Split = $Entry.Index -split '\.'
        $Entry = [pscustomobject][ordered]@{
            Source = $Entry.Source 
            lldpRemTimeMark = $Split[0] 
            lldpRemLocalPortNum = [int]$Split[1] 
            lldpRemIndex = $Split[2] 
            lldpRemChassisIdSubtype = $Entry.'4'.ToInt32()
            lldpRemChassisId = $Entry.5 
            lldpRemPortIdSubtype = $Entry.'6'.ToInt32() 
            lldpRemPortId = $Entry.7 
            lldpRemPortDesc = $Entry.8
            lldpRemSysName = $Entry.'9'.ToString()
            lldpRemSysDesc = $Entry.'10'.ToString() 
            lldpRemSysCapSupported = $Entry.11
            lldpRemSysCapEnabled = $Entry.12
            }

        # Mikrotik workaround...
        if ($entry.lldpRemPortDesc) {
            $entry.lldpRemPortDesc = $Entry.lldpRemPortDesc.ToString()
            }

        # And this too!
        switch ($Entry.lldpRemSysCapSupported.TypeCode) {
            'OctetString' {
                $Entry.lldpRemSysCapSupported = $Entry.lldpRemSysCapSupported.ToHexString()
                }
            'Integer32' {
                $Entry.lldpRemSysCapSupported = $Entry.lldpRemSysCapSupported.ToInt32()
                }
            }
        
        # and even this!
        switch ($Entry.lldpRemSysCapEnabled.TypeCode) {
            'OctetString' {
                $Entry.lldpRemSysCapEnabled = $Entry.lldpRemSysCapEnabled.ToHexString()
                }
            'Integer32' {
                $Entry.lldpRemSysCapEnabled = $Entry.lldpRemSysCapEnabled.ToInt32()
                }
            }

        switch ($Entry.lldpRemPortIdSubtype) {
            3 {
                $Entry.lldpRemPortId = $Entry.lldpRemPortId.ToPhysicalAddress() -replace "\:|\."
                }
            5 {
                $Entry.lldpRemPortId = $Entry.lldpRemPortId.ToString()
                }
            } # End switch

        switch ($Entry.lldpRemChassisIdSubtype) {
            4 {
                if (($Entry.lldpRemChassisId -match "\:|\.") -and ($Entry.lldpRemChassisId.Length -ne 6)) {
                    $Entry.lldpRemChassisId = $Entry.lldpRemChassisId.ToString() -replace "\:|\."
                    }
                else {
                    $Entry.lldpRemChassisId = $Entry.lldpRemChassisId.ToPhysicalAddress() -replace "\:|\."
                    }
                }
            6 {
                $Entry.lldpRemChassisId = $Entry.lldpRemChassisId.ToString()
                }
            } # End switch
        #output
        $Entry
        }

    } # End Process Block

End {
    }
}