# SharpSnmpLibWrapper
SharpSnmpLib Wrapper for PowerShell

This module was written because any other implementation of [#SNMP](https://github.com/lextm/sharpsnmplib) in PoSh just sucks.

Use `Get-SharpSnmpData` and `Invoke-SharpSnmpWalk` for simple requests (parameters are self-explanatory).

If you want to get a MIB table (SEQUENCE OF something) use `Get-SharpSnmpTable`. This function does not accept plain IP, Community etc parameters, but uses a hash object for agent properties, made by helper function `New-SharpSnmpAgent`.
Simple table request will look like this:
```
Get-SharpSnmpTable -OID '.1.3.6.1.2.1.2.2' -Agent (New-SharpSnmpAgent -Agent '127.0.0.1')
```
If you are storing your agent configuration in CSV file, you can load it like this:
```
#load agent info
$Agents = @(Import-Csv -Path 'C:\Shares\Scripts\Devices\SNMP.csv') | % {
        New-SharpSnmpAgent -Agent $_.IP -Port $_.Port -Community $_.Community -Version $_.Version
        }
```
And just pass the whole array to Get-SharpSnmpTable: `Get-SharpSnmpTable -OID '.1.3.6.1.2.1.2.2' -Agent $Agents`

Before using this module in actual script, you need to load #SNMP .dll:
```
[system.reflection.assembly]::LoadFile('C:\Shares\Progs\sharpsnmp\v10.0.7\net452\SharpSnmpLib.dll')
```

If you need to workaround the ["truncation error for 32-bit integer coding" bug](https://github.com/lextm/sharpsnmplib/issues/30), use `[Lextm.SharpSnmpLib.Messaging.Messenger]::UseFullRange = $false` before accesing agent.
