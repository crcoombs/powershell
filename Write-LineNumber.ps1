Function Write-LineNumber
{
<#
.SYNOPSIS
Prints text to the screen with line numbers.

.DESCRIPTION
Takes a multiline string and prepends line numbers to each line.

.PARAMETER Object
The text to be displayed.

.PARAMETER Start
The number at which to start counting lines. Default is 0.

.INPUTS
System.String[].

.OUTPUTS
None.

.EXAMPLE
C:\PS> Write-LineNumber $foo

.EXAMPLE
C:\PS> Get-Content .\foo.txt | Write-LineNumber
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [Object]$Object,

        [Parameter(Mandatory=$False)]
        [Int]$Start = 0
    )

    Begin
    {
        $Counter = $Start
    }

    Process
    {
        ForEach($SubObject in $Object)
        {
            Write-Host "${Counter}: $SubObject"
            $Counter += 1
        }
    } 
}