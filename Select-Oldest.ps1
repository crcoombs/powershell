<#
.SYNOPSIS
Finds the oldest file or directory.

.DESCRIPTION
Takes a list of files and directories and determines which has not been written to the longest.
Takes any strings for the list.

.PARAMETER Paths
Specifies the list of paths.

.INPUTS
System.String[].

.OUTPUTS
System.String.

.EXAMPLE
C:\PS> Select-Oldest C:\foo, C:\bar

.EXAMPLE
C:\PS> Select-Oldest C:\foo.txt, C:\bar.txt

.EXAMPLE
C:\PS> Select-Oldest C:\foo.txt, C:\bar
#>
Function Select-Oldest
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [ValidateScript({Test-Path $_})]
        [String[]]$Paths
    )

    $Oldest = $Paths[0]
    foreach($Item in $Paths)
    {
        if((Get-ItemProperty ${Item}).LastWriteTime `
        -lt (Get-ItemProperty ${Oldest}).LastWriteTime)
        {
            $Oldest = $Item
        }
    }

    Write-Output $Oldest
}
