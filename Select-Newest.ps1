Function Select-Newest
{
<#
.SYNOPSIS
Determines the newest file or directory.

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
C:\PS> Select-Newest C:\foo, C:\bar

.EXAMPLE
C:\PS> Select-Newest C:\foo.txt, C:\bar.txt

.EXAMPLE
C:\PS> Select-Newest C:\foo.txt, C:\bar
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [ValidateScript({Test-Path $_})] 
        [String[]]$Paths
    )

    $Newest = $Paths[0]
    ForEach($Path in $Paths)
    {
        If((Get-ItemProperty ${Path}).LastWriteTime `
        -gt (Get-ItemProperty ${Newest}).LastWriteTime)
        {
            $Newest = $Path
        }
    }

    Write-Output $Newest
}
