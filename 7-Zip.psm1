Function New-Archive
{
<#
.SYNOPSIS
Adds files to an archive.

.DESCRIPTION
Uses 7-zip to add files to an archive.
If the archive does not exist, it will be created.

.PARAMETER Archive
The path to the archive in which the files will be stored.

.PARAMETER Files
The files to be added to the archive.
Defaults to all files in the current folder.

.PARAMETER Type
The type of archive to be created.
Examples include 7z, split, zip, gzip, bzip2, tar.
If not specified, 7-Zip uses the extension of the archive filename to detect the type of archive.

.PARAMETER VolumeSize
Specifies volume size in bytes.
Kilobytes, megabytes, and gigabytes can be specified by placing a k, m, or g after the size.

.PARAMETER Recurse
Enables recursing subdirectories.

.EXAMPLE
New-Archive archive.zip foo.txt, bar.txt

Adds foo.txt and bar.txt to archive.zip.

.EXAMPLE
New-Archive archive.7z -VolumeSize 10m -Recurse

Adds all files in the the current folder and subfolders to archive.7z,
split into 10 megabyte volumes.
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True)]
        [String]$Archive,

        [Parameter(Mandatory=$False, ValueFromPipeline=$True)]
        [String[]]$Files = '*',

        [Parameter(Mandatory=$False)]
        [String]$Type,

        [Parameter(Mandatory=$False)]
        [String]$VolumeSize,

        [Parameter(Mandatory=$False)]
        [Switch]$Recurse
    )

    If(Test-Path "$env:ProgramFiles\7-Zip\7z.exe")
    {
        $Exe = "$env:ProgramFiles\7-Zip\7z.exe"
    }
    ElseIf(Test-Path "${env:ProgramFiles(x86)}\7-Zip\7z.exe")
    {
        $Exe = "$env:ProgramFiles\7-Zip\7z.exe"
    }
    Else
    {
        $Exe = "$PSScriptRoot\7z.exe"
    }

    $Arguments = 'a', $Archive, $Files
    If($Type) 
    {
        $Arguments += "-t$Type"
    }
    If($Recurse) 
    {
        $Arguments += '-r'
    }
    If($VolumeSize) 
    {
        $Arguments += "-v$VolumeSize"
    }

    & $Exe $Arguments | Process-Output
}


Function Extract-Archive
{
<#
.SYNOPSIS
Extracts files from an archive.

.DESCRIPTION
Uses 7-zip to extract files from an archive.

.PARAMETER Archive
The path to the archive from which the files will be extracted.

.PARAMETER Files
The files to be extracted from the archive.
Defaults to all files in the archive.

.PARAMETER Path
The folder where the files will be extracted to.
Defaults to the current folder.

.PARAMETER Recurse
Enables recursing subdirectories.

.EXAMPLE
Extract-Archive archive.zip

Extracts all files in archive.zip to the current folder.

.EXAMPLE
Extract-Archive archive.zip -Files '*.txt' -Path 'C:\Files'

Extracts all text files in the archive to C:\Files.
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String]$Archive,

        [Parameter(Mandatory=$False)]
        [String[]]$Files = '*',

        [Parameter(Mandatory=$False)]
        [String]$Path,

        [Parameter(Mandatory=$False)]
        [Switch]$Recurse
    )
    
    If(Test-Path "$env:ProgramFiles\7-Zip\7z.exe")
    {
        $Exe = "$env:ProgramFiles\7-Zip\7z.exe"
    }
    ElseIf(Test-Path "${env:ProgramFiles(x86)}\7-Zip\7z.exe")
    {
        $Exe = "$env:ProgramFiles\7-Zip\7z.exe"
    }
    Else
    {
        $Exe = "$PSScriptRoot\7z.exe"
    }

    $Arguments = 'e', $Archive, $Files
    If($Path)
    {
        $Arguments += "-o$Path"
    }
    If($Recurse) 
    {
        $Arguments += '-r'
    }
    

    & $Exe $Arguments | Process-Output
}


Function Get-Archive
{
<#
.SYNOPSIS
Lists files in an archive.

.DESCRIPTION
Provides detailed information about and archive and its contents.

.PARAMETER Archive
The path to the archive to check.

.EXAMPLE
Get-Archive archive.zip
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeLine=$True)]
        [String]$Archive
    )

    If(Test-Path "$env:ProgramFiles\7-Zip\7z.exe")
    {
        $Exe = "$env:ProgramFiles\7-Zip\7z.exe"
    }
    ElseIf(Test-Path "${env:ProgramFiles(x86)}\7-Zip\7z.exe")
    {
        $Exe = "$env:ProgramFiles\7-Zip\7z.exe"
    }
    Else
    {
        $Exe = "$PSScriptRoot\7z.exe"
    }
    
    $Arguments = 'l', $Archive

    & $Exe $Arguments | Process-Output
}


Function Test-Archive
{
<#
.SYNOPSIS
Tests files in an archive.

.DESCRIPTION
Uses 7-zip to verify the integrity of files in a given archive.

.PARAMETER Archive
The path to the archive to be checked.

.PARAMETER Files
The files to be checked.
Defaults to all files in the archive.

.PARAMETER Exclude
The files that are to be skipped.

.EXAMPLE
Test-Archive archive.zip

.EXAMPLE
Test-Archive archive.zip -Exclude '*.txt'
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeLine=$True)]
        [String]$Archive,

        [Parameter(Mandatory=$False)]
        [String[]]$Files = '*',

        [Parameter(Mandatory=$False)]
        [String]$Exclude
    )

    If(Test-Path "$env:ProgramFiles\7-Zip\7z.exe")
    {
        $Exe = "$env:ProgramFiles\7-Zip\7z.exe"
    }
    ElseIf(Test-Path "${env:ProgramFiles(x86)}\7-Zip\7z.exe")
    {
        $Exe = "$env:ProgramFiles\7-Zip\7z.exe"
    }
    Else
    {
        $Exe = "$PSScriptRoot\7z.exe"
    }

    $Arguments = 't', $Archive, $Files
    If($Exclude)
    {
        $Arguments += "-x!$Exclude"
    }

    & $Exe $Arguments | Process-Output
}


Function Process-Output
{
<#
.SYNOPSIS
Processes 7-zip output.

.DESCRIPTION
Converts 7-zip text output into objects.

.PARAMETER Input
The output from a 7-zip command.
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [AllowEmptyString()]
        [String[]]$Input
    )

    Begin
    {
        $Output = New-Object PSObject
        Add-Member -InputObject $Output -MemberType NoteProperty -Name Files -Value @()
        $ErrorFlag = $False
    }

    Process
    {
        Write-Verbose $_

        If ($ErrorFlag)
        {
            $ErrorFlag = $False
            Throw "$_`n"       #Newline separates error message from rest of error details
        }

        Switch -Regex ($_)
        {
            '^(Process|Creat|List)ing archive:?\s'
            {
                Add-Member -InputObject $Output -MemberType NoteProperty -Name Name -Value ($_ -Replace '^(Process|Creat|List)ing archive:?\s', '')
                Continue
            }

            '^Path\s=\s'
            {
                Add-Member -InputObject $Output -MemberType NoteProperty -Name Path -Value ($_ -Replace '^Path\s=\s', '')
                Continue
            }

            '^Type\s=\s'
            {
                Add-Member -InputObject $Output -MemberType NoteProperty -Name Type -Value ($_ -Replace '^Type\s=\s', '')
                Continue
            }

            '^Method\s=\s'
            {
                Add-Member -InputObject $Output -MemberType NoteProperty -Name Method -Value ($_ -Replace '^Method\s=\s', '')
                Continue
            }

            '^Blocks\s=\s'
            {
                Add-Member -InputObject $Output -MemberType NoteProperty -Name Blocks -Value ($_ -Replace '^Blocks\s=\s', '')
                Continue
            }

            '^Physical Size\s=\s'
            {
                Add-Member -InputObject $Output -MemberType NoteProperty -Name PhysicalSize -Value ($_ -Replace '^Physical Size\s=\s', '')
                Continue
            }

            '^Headers Size\s=\s'
            {
                Add-Member -InputObject $Output -MemberType NoteProperty -Name HeadersSize -Value ($_ -Replace '^Headers Size\s=\s', '')
                Continue
            }

            '^\d{4}-\d{2}-\d{2}'
            {
                $FileProperties = $_.Split(' ',[System.StringSplitOptions]::RemoveEmptyEntries)
                $FileInfo = [PSCustomObject]@{
                    Date = [System.DateTime]::ParseExact($FileProperties[0] + $FileProperties[1], "yyyy-MM-ddHH:mm:ss", $null)
                    Attributes = $FileProperties[2]
                    UncompressedSize = $FileProperties[3]
                    CompressedSize = $FileProperties[4]
                    Name = $FileProperties[5]
                }
                <#Alternate Method
                $_ -Match '(?<Date>\d{4}-\d{2}-\d{2})\s(?<Time>\d{2}:\d{2}:\d{2})\s(?<Attr>.{5})\s+(?<Size>\w+)\s+(?<Compressed>\w+)?\s+(?<Name>.+\.?.*)' | Out-Null
                $FileInfo = [PSCustomObject]@{
                    Date = [System.DateTime]::ParseExact($Matches['Date'] + $Matches['Time'], "yyyy-MM-ddHH:mm:ss", $null)
                    Attributes = $Matches['Attr']
                    UncompressedSize = $Matches['Size']
                    CompressedSize = $Matches['Compressed']
                    Name = $Matches['Name']
            
                }
                #>
                $Output.Files += $FileInfo
                Continue
            }

            '^(Extract|Compress)ing\s+'
            {
                $Output.Files += $_ -Replace '^(Extract|Compress)ing\s+', ''
                Continue
            }

            '^Testing\s+'
            {                    
                $_ = $_ -Replace '^Testing\s+', ''

                If(Select-String -InputObject $_ -Pattern '\s+Data Error$')
                {
                    $_ = $_ -Replace('\s+Data Error$', '')
                    $Result = 'Data Error'
                }
                Else
                {
                    $Result = $null
                }
                    
                $Output.Files += [PSCustomObject]@{
                    Name = $_
                    Result = $Result
                }
                Continue
            }

            '^Size:\s+'
            {
                Add-Member -InputObject $Output -MemberType NoteProperty -Name UncompressedSize -Value ($_ -Replace '^Size:\s+', '')
                Continue
            }

            '^Compressed:\s+'
            {
                Add-Member -InputObject $Output -MemberType NoteProperty -Name CompressedSize -Value ($_ -Replace '^Compressed:\s+', '')
                Continue
            }

            '^Error:'
            {
                $_ = $_ -Replace '^Error:', ''
                If ($_)                       #Covers the error message being on the same line, i.e. most errors
                {
                    Throw "$_`n"                  #Newline separates error message from rest of error details
                }
                Else                          #Covers the error message being on the next line, e.g. 'cannot find archive'
                {
                    $ErrorFlag = $True
                    Continue
                }
            }
        }    
    }

    End
    {
        Write-Output $Output
    }
}


Export-ModuleMember -Function New-Archive, Extract-Archive, Get-Archive, Test-Archive
