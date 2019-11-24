<#
.Synopsis
   Convert lldpRemTable 1.0.8802.1.1.2.1.3.7 (LLDP-MIB.MIB)
.DESCRIPTION
   Convert lldpRemTable 1.0.8802.1.1.2.1.3.7 (LLDP-MIB.MIB)
.EXAMPLE
   $SNMP | ConvertFrom-OID.1.0.8802.1.1.2.1.3.7 | ft
.EXAMPLE
   ConvertFrom-OID.1.0.8802.1.1.2.1.3.7 -SNMP $SNMP | ft
#>
function ConvertFrom-OID.1.0.8802.1.1.2.1.3.7 {
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
        $Entry = [pscustomobject][ordered]@{
            Source = $Entry.Source
            lldpLocPortNum = $Entry.Index
            lldpLocPortId = $Entry.'3'.ToString()
            lldpLocPortIdSubtype = $Entry.'2'.ToInt32()
            lldpLocPortDesc = $Entry.'4'.ToString()
            } 
        #output
        $Entry
        }

    } # End Process Block

End {
    }
}