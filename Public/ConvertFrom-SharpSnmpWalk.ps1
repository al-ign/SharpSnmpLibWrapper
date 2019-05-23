function ConvertFrom-SharpSnmpWalk { 
[CmdletBinding()]
param (
    [Parameter(
        Mandatory=$true, 
        ValueFromPipeline=$true,
        HelpMessage = 'SNMP Data',
        ParameterSetName='Default',
        Position=0
        )]
    [psobject]$SNMP,

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'OID used for request',
        Position=1
    )]
    [string]$OID
)
begin {
        
    $OIDRegex  = '(?<Id>' + ( $OID -replace '^\.' -replace '\.','\.' ) + ')\.(?<Entry>\d+)\.(?<Column>\d+)\.?(?<Index>.+)?'
    $OIDRegex2 = '(?<Id>' + ( $OID -replace '^\.' -replace '\.','\.' ) + ')\.(?<Index>\d+)$'
    $DataTable = New-object system.data.datatable("ConvertFrom-SharpSnmpWalk")
    $new = $DataTable.columns.add("Source")
    $new = $DataTable.columns.add("Id")
    $new = $DataTable.columns.add("Index")

    } # End begin block

process {
    
    #'SNMP count: ' + $SNMP.count | Write-Debug
    #'Input count: ' + $input.Count | Write-Debug
    #"SNMP Object count: {0}" -f $snmp.count | Write-Verbose 
    foreach ($Entry in $Snmp) {
    
        if ($Entry.GetType().Name -eq 'Int32') {
            continue
            }
        
        if ($entry.Id.ToString() -match $OIDRegex) {
            if ($DataTable.Columns | ? {$_.ColumnName -eq $Matches.Column}) {
                #column exists
                }
            else {
                $new = $DataTable.columns.add([string]$Matches.Column,[Object])
                #'Column ' + $Matches.Column + ' was created' | Write-Debug
                }
            $dtRow = @($DataTable.Select("[Index] = '" + $Matches.index + "'"))[0]
                    
                if ($dtRow) {
                    $dtRow.BeginEdit()
                    $dtRow.$($Matches.Column) = $entry.Data
                    $dtRow.EndEdit()            
                    }
                else {       
                    $dtRow = $DataTable.NewRow()
                    $dtRow.Source = $entry.Source
                    $dtRow.Id = $Matches.Id
                    if ($Matches.Index) {
                        $dtRow.Index = $Matches.Index
                        }
                    else {
                        $dtRow.Index = $Matches.Entry
                        }
                    $dtRow.$($Matches.Column) = $entry.Data
                    $DataTable.Rows.Add($dtrow)
                    }
            }
        elseif ($entry.Id.ToString() -match $OIDRegex2) {
            #simple table with 1 column
            if ($DataTable.Columns | ? {$_.ColumnName -eq 'Data'}) {
                #column exists
                }
            else {
                $new = $DataTable.columns.add([string]'Data',[Object])
                #'Column ' + $Matches.Column + ' was created' | Write-Debug
                }
            $dtRow = @($DataTable.Select("[Index] = '" + $Matches.index + "'"))[0]
                    
                if ($dtRow) {
                    $dtRow.BeginEdit()
                    $dtRow.$($Matches.Column) = $entry.Data
                    $dtRow.EndEdit()            
                    }
                else {       
                    $dtRow = $DataTable.NewRow()
                    $dtRow.Source = $entry.Source
                    $dtRow.Id = $Matches.Id
                    if ($Matches.Index) {
                        $dtRow.Index = $Matches.Index
                        }
                    else {
                        $dtRow.Index = $Matches.Entry
                        }
                    $dtRow.'Data' = $entry.Data
                    $DataTable.Rows.Add($dtrow)
                    }

            }
        else {
            $Entry
            }
        } # End %    
    } # End process block

end {
    $DataTable
    $DataTable.Dispose()
    } # End end block
    
} # End function ConvertFrom-SharpSnmpWalk
