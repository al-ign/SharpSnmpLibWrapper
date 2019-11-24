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
    $DataTable.PrimaryKey = $New
    $counter = 0

    # If SNMP object was passed through explicit parameter and match OIDRegex - add column names
    if (($SNMP.Count -gt 1) -and ($SNMP[0].GetType().Name -eq 'int32') -and ($SNMP[1].Id.ToString() -match $OIDRegex)) {
        $ColumnNames = foreach ($entry in $SNMP[1..$SNMP.GetUpperBound(0)]) { 
            if ($entry.id.Tostring() -match $OIDRegex) {
                $Matches.Column
                }
            }

        # Create columns
        foreach ($thisColumn in ($ColumnNames | Select-Object -Unique)) {
            $new = $DataTable.columns.add([string]$thisColumn,[Object])
            }
        
        # $SNMP[0] usually contains the number of rows in the result - makes sense to resize Datatable
        $DataTable.MinimumCapacity = $SNMP[0]
        }

    # if SNMP[0] is an int32, remove it from the dataset to avoid errors
    if (($SNMP.Count -gt 1) -and ($SNMP[0].GetType().Name -eq 'int32')) {
        $SNMP = $SNMP[1..$SNMP.GetUpperBound(0)]
        }

    # create a bool to indicate how SNMP data was received - through parameter or a pipeline
    $boolWasReceivedThrougPipeline = -not $PSBoundParameters.ContainsKey('SNMP') 

    } # End begin block

process {
    
    foreach ($Entry in $Snmp) {
        $counter++
        if ($counter.ToString() -match '00$') {
            Write-Progress -Activity ('Converting SNMP walk for OID {0} to a table' -f $OID) -Status ('Processed {0} records' -f $counter) 
            }

        # skip the first item with the row count if received from the pipeline
        if ($boolWasReceivedThrougPipeline) {
            if ($Entry.GetType().Name -eq 'Int32') {
                continue
                }
            }
        if ($entry.Id.ToString() -match $OIDRegex) {
            $OIDMatch = $Matches

            # this block is triggered if the data was passed throught the pipeline
            #if ($boolWasReceivedThrougPipeline) {
            if ($true) {
                 
                # Test for column name, create if absent
                if ($DataTable.Columns.Contains($OIDMatch.Column) -eq $false) {
                    $new = $DataTable.columns.add([string]$Matches.Column,[Object])
                    'Column ' + $OIDMatch.Column + ' was created' | Write-Debug
                    }
                }

            $dtRow = @($DataTable.Select("[Index] = '" + $OIDMatch.index + "'"))[0]
 
                if ($dtRow) {
                    $dtRow.BeginEdit()
                    $dtRow.$($OIDMatch.Column) = $entry.Data
                    $dtRow.EndEdit()            
                    }
                else {       
                    $dtRow = $DataTable.NewRow()
                    $dtRow.Source = $entry.Source
                    $dtRow.Id = $OIDMatch.Id
                    if ($OIDMatch.Index) {
                        $dtRow.Index = $OIDMatch.Index
                        }
                    else {
                        $dtRow.Index = $OIDMatch.Entry
                        }
                    $dtRow.$($OIDMatch.Column) = $entry.Data
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
    
}