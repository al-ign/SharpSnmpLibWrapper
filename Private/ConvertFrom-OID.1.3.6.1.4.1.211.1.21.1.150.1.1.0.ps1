<#
.Synopsis
   Convert Fujitsu Eternus SAN Physical Disk status (FJDARY-E150.MIB)
.DESCRIPTION
   Convert Fujitsu Eternus SAN Physical Disk status (FJDARY-E150.MIB)
.EXAMPLE
   $SNMP | ConvertFrom-OID.1.3.6.1.4.1.211.1.21.1.150.1.1.0 | ft
.EXAMPLE
   ConvertFrom-OID.1.3.6.1.4.1.211.1.21.1.150.1.1.0 -SNMP $SNMP | ft
#>
function ConvertFrom-OID.1.3.6.1.4.1.211.1.21.1.150.1.1.0 {
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
        [pscustomobject][ordered]@{
            Source = $SNMP.Source
            TypeCode = $SNMP.Data.ToString().Substring(0,2)
            Series = $SNMP.Data.ToString().Substring(2,12)
            Model = $SNMP.Data.ToString().Substring(14,12) -replace '#'
            CheckCode = $SNMP.Data.ToString().Substring(26,2)
            Serial = $SNMP.Data.ToString().Substring(28,12) -replace '#'
            }
        }

    } # End Process Block

End {
    }
}