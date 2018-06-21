# SharpSnmpLibWrapper
SharpSnmpLib Wrapper for PowerShell

This module was written because any other implementation of [#SNMP](https://github.com/lextm/sharpsnmplib) in PoSh just sucks.

Use `Get-SharpSnmpData` and `Invoke-SharpSnmpWalk` for simple requests (arguments are self-explanatory).

If you want to get a MIB table (SEQUENCE OF something) use `Get-SharpSnmpTable`. This function does not accept plain IP, Community etc arguments, but uses a hash object for agent properties, made by New-SharpSnmpAgent.
Simple table request will look like 
```
Get-SharpSnmpTable -OID '.1.3.6.1.2.1.2.2' -Agent (New-SharpSnmpAgent -Agent '127.0.0.1')
```

Before using this module in actual script, you need to load #SNMP .dll:
```
[system.reflection.assembly]::LoadFile('C:\Shares\Progs\sharpsnmp\v10.0.7\net452\SharpSnmpLib.dll')
```

If you need to workaround the ["truncation error for 32-bit integer coding" bug](https://github.com/lextm/sharpsnmplib/issues/30), use `[Lextm.SharpSnmpLib.Messaging.Messenger]::UseFullRange = $false` before accesing agent.
