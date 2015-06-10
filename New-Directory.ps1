<#
.SYNOPSIS
Creates a new directory.

.DESCRIPTION
Takes a list of paths and creates new directories for each if they do not already exist.
Takes any strings for the list.

.PARAMETER Paths
Specifies the list of paths.

.INPUTS
System.String[]

.OUTPUTS
None.

.EXAMPLE
C:\PS> New-Directory C:\foo

.EXAMPLE
C:\PS> New-Directory C:\foo, C:\bar
#>
Function New-Directory
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [String[]]$Paths
    )

    foreach($Item in $Paths)
    {
        if(-not (Test-Path $Item))
        {
            Write-Verbose "$Item does not exist, creating..."
            New-Item $Item -ItemType Directory
        }
        else
        {
            Write-Verbose "$Item already exists."
        }
    }
}
