<#
.SYNOPSIS
Retrives values from CSV data.

.DESCRIPTION
Retreives a given set of coulmn values from CSV data that match a given seach value.

.PARAMETER Path
The path to a CSV file.

.PARAMETER Object
A PSCustomObject containing CSV data.

.INPUTS
System.String, Object[].

.OUTPUTS
Object[]

.EXAMPLE
C:\PS> Search-CSV -Path list.csv -SearchColumn Name -SearchValue Steve -ResultColumns Address

.EXAMPLE
C:\PS> Search-CSV $data Name Mark Age,Address
#>
Function Search-CSV
{
    [CmdletBinding(DefaultParameterSetName="Path")]
    Param (
        [Parameter(ParameterSetName="Path", Mandatory=$True, Position=1)]
        [String]$Path,

        [Parameter(ParameterSetName="Object", Mandatory=$True, Position=1)]
        [Object[]]$Object,

        [Parameter(Mandatory=$True, Position=2)]
        [String]$SearchColumn,

        [Parameter(Mandatory=$True, Position=3)]
        [String]$SearchValue,

        [Parameter(Mandatory=$True, Position=4)]
        [String[]]$ResultColumns
    )

    If($PsCmdlet.ParameterSetName -eq "Path")
    {
        $Records = (Import-Csv $Path | Where-Object {$_.$SearchColumn -like $SearchValue})
    }

    ElseIf($PsCmdlet.ParameterSetName -eq "Object")
    {
        $Records = ($Object | Where-Object {$_.$SearchColumn -like $SearchValue})
    }

   Write-Output $Records
}
