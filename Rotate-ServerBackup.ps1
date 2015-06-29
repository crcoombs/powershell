Function Rotate-ServerBackup
{
<#
.SYNOPSIS
Rotates Windows Server backups.

.DESCRIPTION
Makes a backup to the oldest directory given by the user.
Only backs up to network locations via UNC paths.

.PARAMETER Paths
Specifies the list of possible backup target locations.

.PARAMETER Volumes
The list of disk volumes to be backed up.

.PARAMETER Retries
The number of times to restart the backup process in the event of failure.

.EXAMPLE
C:\PS> Rotate-ServerBackup -Paths \\server\share\1, \\server\share\2

.EXAMPLE
C:\PS> Rotate-ServerBackup \\server\share\1, \\server\share\2 C:, E:
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,Position=1)]
        [String[]]$Paths,

        [Parameter(Mandatory=$False,Position=2)]
        [String[]]$Volumes = 'C:',

        [Parameter(Mandatory=$False,Position=3)]
        [Int]$Retries = 3,      

        [Parameter(Mandatory=$False)]
        [String]$UserName,      

        [Parameter(Mandatory=$False)]
        [String]$Password      
    )

    #Function imports

    . ".\Send-AdminEmail.ps1"
    . ".\New-Directory.ps1"
    . ".\Select-Oldest.ps1"

    #Constants setup

    $ComputerName = [System.Environment]::MachineName
    $Sender = $ComputerName + "@nemosvd.cdema.org"
    $SubDirectory = "WindowsImageBackup\$ComputerName"
    ForEach($Directory in $Paths)
    {
	If($UserName -and $Password)
	{
            net use $Directory $Password /user:$Username
	}
        $Directory = "$Directory\$SubDirectory"
    }           

    #Sends email indicating start of backup

    Send-AdminEmail -Sender  $Sender `
                    -Subject "Backup Started" `
                    -Message "Backup in progress." `
                    -ComputerName `
                    -Time
           
    Try
    {   
        Write-Verbose "Retries remaining: $Retries"

        #Loads Server Backup cmdlets into PowerShell if not already loaded
        #Throws exception if snap-in is not registered

        $SnapIn = "windows.serverbackup"
        Write-Verbose "Testing for Server Backup snap-in..."
        If(Get-Pssnapin $SnapIn -ErrorAction SilentlyContinue)
        {
            Write-Verbose "Snap-in found."
        }
        Else 
        {
            If(Get-Pssnapin $SnapIn -Registered -ErrorAction SilentlyContinue)
            {
                Write-Verbose "Snap-in registered but not loaded, loading now..."
                Add-Pssnapin $SnapIn
            }
            Else
                {
                    Throw "Server Backup Snap-in not found."
                }
        } 
        
        #Tests existance of backup folders 
        #Creates them if not found

        Write-Verbose "Checking existance of backup folders..."
        New-Directory -Path $Paths -ErrorAction Stop

        #Finds the oldest backup folder

        Write-Verbose "Checking folder ages..."
        $Oldest = Select-Oldest -Paths $Paths
	    $BackupDirectory = $Oldest.Substring(0, $Oldest.IndexOf($SubDirectory))
        Write-Verbose "$BackupDirectory selected."
        
        #Creates backup policy and target objects

        Write-Verbose "Creating policy and objects..."
        $Policy = New-WBPolicy
        $DirectoryObject = New-WBBackupTarget -NetworkPath $BackupDirectory

        #Policy setup for recovering all data

        Write-Verbose "Adding objects to policy..."
        Add-WBBackupTarget -Policy $Policy -Target $DirectoryObject
        Add-WBSystemState $Policy
        Add-WBBareMetalRecovery -Policy $Policy
        ForEach($Volume in $Volumes)
        {
            Add-WBVolume -Policy $Policy -Volume (Get-WBVolume -VolumePath $Volume)
        }

        #Execution of backup process

        Write-Verbose "Starting backup..."
        Start-WBBackup -Policy $Policy
        
        #Sends success email

        Write-Verbose "Backup complete."
        Send-AdminEmail -Sender  $Sender `
                        -Subject "Backup Success" `
                        -Message "Backup to $BackupDirectory completed." `
                        -ComputerName `
                        -Time
    }

    #Catches exceptions thrown by New-Item
    #If folder could neither be found nor created, then link failure must be the issue

    Catch [System.Management.Automation.ActionPreferenceStopException]
    {
        If($Retries -gt 0)
        {
            Write-Verbose "$($Error[0].CategoryInfo.TargetName) could not be created, retrying in 60 secs..."
            Send-AdminEmail -Sender  $Sender `
                            -Subject "Backup Error" `
                            -Message "$($Error[0].CategoryInfo.TargetName) could not be created, retrying in 60 secs." `
                            -ComputerName `
                            -Time
            Start-Sleep -s 60
            Rotate-ServerBackup -Path $Paths -Retry ($Retries - 1)
        }
        Else
        {
            Write-Verbose "Backup Failure: $($Error[0].CategoryInfo.TargetName) is inaccessible; number of retries exceeded."
            Send-AdminEmail -Sender  $Sender `
                            -Subject "Backup Failure" `
                            -Message "Backup Failure: $($Error[0].CategoryInfo.TargetName) is inaccessible; number of retries exceeded." `
                            -ComputerName `
                            -Time
            Write-Error "Backup Failure: Folder could not be found; number of retries exceeded."
        }
    }

    #Catches any other exceptions

    Catch
    {
        #Sends failure email, out-string used to capture entire error message

        Write-Verbose "Backup Failure: $($Error[0])"
        Send-AdminEmail -Sender  $Sender `
                        -Subject "Backup Error" `
                        -Message ($Error[0] | out-string) `
                        -ComputerName `
                        -Time

        #Ensures error that triggered catch statement is in $Error[0]

        If($Error[0].CategoryInfo | Select-String 'WriteErrorException')
        {
            Write-Error $Error[2]
        }
        Else
        {
            Write-Error $Error[0]
        }
    }

    Finally
    {
        foreach($Directory in $Paths)
        {
            net use $Directory /delete
        }
    }
}
