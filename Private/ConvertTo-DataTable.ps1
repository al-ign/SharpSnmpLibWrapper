function ConvertTo-DataTable {
<#
.Synopsis
    Convert array to System.Data.Datatable object
.DESCRIPTION
    Convert array to System.Data.Datatable object automatically converting property names.
    Datatable should be created before invoking function
.EXAMPLE
    $dataTable = New-object system.data.datatable('SomeTable')
    ConvertTo-DataTable -Array $array -DataTable $dataTable
.INPUTS
   [System.Data.Datatable], mandatory
   [Array], mandatory
.OUTPUTS
   None
#>
[cmdletbinding()]
param (
    [Parameter(Mandatory=$true)]
    [system.data.datatable]
    $DataTable,

    [Parameter(Mandatory=$true, 
        ValueFromPipeline=$true)]
    $Array,
    [Parameter(Mandatory=$false)]
    $SuppressWarnings = $false 
    )
    begin {
        if ($Array) {
            $local:colNames = @($Array[0]  | Get-Member -MemberType Properties | Select-Object name )
            foreach ($thisColName in $colNames) {
                try {
                    $new = $DataTable.Columns.Add($thisColName.Name)
                    }
                catch { 
                    if ($local:SuppressWarnings -eq $false) {
                        Write-Warning -Message $("Couldn't add the column {0} to the DataTable {1}, already exists?" -f $thisColName.Name, $DataTable.TableName)
                        }
                    }
                }
            }#End if
        }#End begin

    process {
        if (-not $local:colNames) {
            $local:colNames = @($input  | Get-Member -MemberType Properties | Select-Object name )
            foreach ($thisColName in $local:colNames) {
                $new = $DataTable.Columns.Add($thisColName.Name)
                }
            }
            
        if ($input) {
            $Array = $input
            }

        foreach ($entry in $Array) {
            $Row = $DataTable.NewRow()
            foreach ($col in $local:colNames) {
                $Row.($col.Name) = $entry.($col.Name)
                }
            $DataTable.Rows.Add($Row)
            }
        }#End process
    }#End function ConvertTo-DataTable
