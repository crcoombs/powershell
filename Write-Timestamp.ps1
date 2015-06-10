Function Write-Timestamp
{
<#
.SYNOPSIS
Prints text to the screen with a timestamp.

.DESCRIPTION
Prints text with either the current time or elapsed time.

.PARAMETER Object
The text to be displayed.

.PARAMETER StartTime
The time from which to start counting.

.EXAMPLE
C:\PS> Write-Timestamp $foo (Get-Date)

.EXAMPLE
C:\PS> Get-Content file.txt | Write-Timestamp
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [Object]$Object,

        [Parameter(Mandatory=$False)]
        [DateTime]$StartTime
    )

    Begin{}

    Process
    {
        If($StartTime)
        {
            Write-Host "$((Get-Date).Subtract($StartTime).ToString()): " -ForegroundColor Green -NoNewline
        }
        Else
        {
            Write-Host "$((Get-Date).TimeOfDay): " -ForegroundColor Green -NoNewline
        }

        Write-Host $Object
    }
}