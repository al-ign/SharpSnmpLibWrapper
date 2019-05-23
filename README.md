# SharpSnmpLibWrapper
SharpSnmpLib Wrapper for PowerShell

This module was written because any other implementation of [#SNMP](https://github.com/lextm/sharpsnmplib) in PoSh just sucks.

Use `Get-SharpSnmp` and `Get-SharpSnmpWalk` for simple requests (parameters are self-explanatory).

If you want to get a MIB table (SEQUENCE OF something) use `Get-SharpSnmpTable`. 

Get* functions support direct specification of the SNMP agent address, community, port and version (fine for callin one device), but also support `AgentObject` which is useful if you have more than one SNMP device to query against.

AgentObject can be just a hashtable with all parameters:
```
@{ 
    Agent = '192.168.128.28'
    Community = 'Auto100133'
    Port = 161
    Version = 'V2'
    } | Get-SharpSnmp -OID .1.3.6.1.2.1.1.1.0
```
Or a just necessary fields if you still on a `public` community and 161 port, but should be passed through the help function `New-SharpSnmpAgent`
```
@{ 
    Agent = '192.168.128.28'
    Community = 'Auto100133'
    } | New-SharpSnmpAgent |  Get-SharpSnmp -OID .1.3.6.1.2.1.1.1.0
```
Or batch create the multiple objects if all parameters are the same:
```
$Devices = '192.168.128.28','192.168.128.20' | New-SharpSnmpAgent -Community 'SecureCommunity'
$Devices | Get-SharpSnmp -OID .1.3.6.1.2.1.1.1.0
```

If you are storing your agent configuration in CSV file, you can just pipe it to New-SharpSnmpAgent, example CSV:
```
"Agent";"Community";"Description";"Version";"Port"
"192.168.128.243";"Auto100133";"PowerConnect 5548";"V2";"161"
"192.168.128.249";"Auto100133";"PowerConnect 8024F";"V2";"161"
"192.168.128.28";"Auto100133";"Main Cisco Router";"V2";"161"
```
Loading this CSV:
```
$csvPath = 'C:\Shares\Scripts\SourceData\SNMP-Devices.csv'
$snmpDevices = ConvertFrom-Csv -Delimiter ';' -InputObject (Get-Content $csvpath) | New-SharpSnmpAgent
```
And just pass the the object to the Get-* functions:
```
$snmpDevices | Get-SharpSnmp -OID .1.3.6.1.2.1.1.1.0
#or
Get-SharpSnmp -OID .1.3.6.1.2.1.1.1.0 -AgentObject $snmpDevices
```

Before using this module in actual script, you need to load #SNMP .dll:
```
[system.reflection.assembly]::LoadFile('C:\Shares\Progs\sharpsnmp\v10.0.7\net452\SharpSnmpLib.dll')
```

If you need to workaround the ["truncation error for 32-bit integer coding" bug](https://github.com/lextm/sharpsnmplib/issues/30), use `[Lextm.SharpSnmpLib.Messaging.Messenger]::UseFullRange = $false` before accesing agent.
