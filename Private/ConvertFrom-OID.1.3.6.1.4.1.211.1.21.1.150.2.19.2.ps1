<#
.Synopsis
   Convert Fujitsu Eternus SAN Physical Disk status (FJDARY-E150.MIB)
.DESCRIPTION
   Convert Fujitsu Eternus SAN Physical Disk status (FJDARY-E150.MIB)
.EXAMPLE
   $SNMP | ConvertFrom-OID.1.3.6.1.4.1.211.1.21.1.150.2.19.2 | ft
.EXAMPLE
   ConvertFrom-OID.1.3.6.1.4.1.211.1.21.1.150.2.19.2 -SNMP $SNMP | ft
#>
function ConvertFrom-OID.1.3.6.1.4.1.211.1.21.1.150.2.19.2 {
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
            Source = $Entry.Source
            fjdaryDiskIndex = $entry.'1'.ToInt32()
            fjdaryDiskItemId = $entry.'2'.ToInt32()
            fjdaryDiskStatus = $entry.'3'.ToInt32()
            fjdaryDiskSubStatus = $entry.'4'.ToInt32()
            fjdaryDiskCompStatus = $entry.'5'.ToInt32()
            fjdaryDiskCompSubStatus = $entry.'6'.ToInt32()
            fjdaryDiskPlun = $entry.'7'.ToInt32()
            fjdaryDiskPurpose = $entry.'8'.ToInt32()
            fjdaryDiskType = $entry.'9'.ToInt32()
            fjdaryDiskWwn = $entry.'10'.ToHexString() 
            fjdaryDiskVendorId = $entry.'11'.ToString() -replace [char]0x0
            fjdaryDiskProductId = $entry.'12'.ToString() -replace [char]0x0
            fjdaryDiskFwRevision = $entry.'13'.ToString() -replace [char]0x0
            fjdaryDiskDateCode = $entry.'14'.ToString() -replace [char]0x0
            fjdaryDiskCfgRevision = $entry.'15'.ToString() -replace [char]0x0
            fjdaryDiskSize = $entry.'16'.ToInt32()
            fjdaryDiskHealth = $entry.'17'.ToInt32()
            }
        }

    } # End Process Block

End {
    }
}