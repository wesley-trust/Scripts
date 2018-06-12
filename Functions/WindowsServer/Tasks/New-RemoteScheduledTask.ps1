<#
#Script name: Function to create a scheduled task on remote computers
#Creator: Wesley Trust
#Date: 2017-08-30
#Revision: 2
#References:

.Synopsis
    Function that deploys a scheduled task.
.Description
    Function that deploys a scheduled task, from files previously deployed.
.Example

.Example
    
#>

function New-RemoteScheduledTask {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Specify a computer name, multiple computers can be in array format or comma separated",
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [string[]]
        $ComputerName,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $Credential,
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Name of scheduled task",
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $TaskName,
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Time of task to trigger",
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $TaskTriggerTime,
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Path to root of task working directories",
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $TaskDirectory,
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Executable name (without file path)",
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $TaskEXE
    )
    Begin {
        try {    
            # If no credentials, request them
            if (!$Credential) {
                $Credential = Get-Credential -Message "Enter credential for remote computer"
            }
        }
        catch {
            Write-Error -Message $_.Exception
        }
    }
    Process {
        try {
            # Task Variables
            $TaskWorkingDirectory = "`"$Directory" + $TaskName + "\"
            $TaskExecute = $TaskWorkingDirectory + $TaskEXE + "`""
                        
            # Split and trim input
            $ComputerName = $ComputerName.Split(",")
            $ComputerName = $ComputerName.Trim()
            
            # For each computer, create new task
            foreach ($Computer in $ComputerName) {
                $Session = New-PSSession -ComputerName $Computer -Credential $Credential
            
                # Run command in remote computer session
                Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                
                    # Create Task Object
                    $Task = [pscustomobject]@{
                        Name        = $Using:TaskName
                        Directory   = $Using:TaskWorkingDirectory
                        EXE         = $Using:TaskEXE
                        Execute     = $Using:TaskExecute
                        TriggerTime = $Using:TaskTriggerTime
                    }
                    
                    # Create Task action
                    $STAction = New-ScheduledTaskAction –Execute $Task.Execute
                   
                    # Create Task Trigger
                    $STTrigger = New-ScheduledTaskTrigger -Daily -At $Task.TriggerTime
                    
                    # Create task security principal
                    $STPrincipal = New-ScheduledTaskPrincipal -UserId "LOCALSERVICE" -LogonType ServiceAccount
                    
                    # Create Scheduled task settings
                    $STSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable
                    
                    # Create scheduled task object
                    $STObject = New-ScheduledTask -Action $STAction -Principal $STPrincipal -Trigger $STTrigger -Settings $STSettings
                    
                    # Register scheduled task
                    Register-ScheduledTask $Task.Name -InputObject $STObject
                }
            }
        }
        catch {
            Write-Error -Message $_.Exception
        }
    }
    End {
        try {

        }
        catch {
            Write-Error -Message $_.Exception
        }
    }
}