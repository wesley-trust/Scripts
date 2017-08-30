<#
#Script name: Script to create a scheduled task on remote computers
#Creator: Wesley Trust
#Date: 2017-08-30
#Revision: UNFINISHED
#References:

.Synopsis
    Script that calls a function that tests the connection to remote servers, then deploys a scheduled task.
.Description
    Script that calls a function that tests the connection to remote servers, then deploys a scheduled task,
    on successful servers after confirmation.
.Example
    Specify the fully qualified Domain Name (FQDN) and Organisational Unit (OU) by distinguished name (DN).
    Configure-Drive -Domain $Domain -OU $OU
.Example
    

#>

#Include Functions
. .\Test-Server.ps1

function Deploy-Task () {
    #Parameters
    Param(
        #Request Domain
        [Parameter(
            Mandatory=$true,
            Position=1,
            HelpMessage="Enter the FQDN",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        
        #Request OU
        [Parameter(
            Mandatory=$true,
            Position=2,
            HelpMessage="Enter in DN format",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $OU,

        #Task Parameters
        [Parameter(
            Mandatory=$true,
            HelpMessage="Name of scheduled task",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $TaskName,

        [Parameter(
            Mandatory=$true,
            HelpMessage="Time of task to trigger",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $TaskTriggerTime,

        [Parameter(
            Mandatory=$true,
            HelpMessage="Path to root of task working directories",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $TaskDirectory,

        [Parameter(
            Mandatory=$true,
            HelpMessage="Executable name (without file path)",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $TaskEXE,

        [Parameter(
            Mandatory=$true,
            HelpMessage="File path to source files",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $TaskSourceFiles
        )

    #Credentials
    #Prompt if no credentials stored
    if ($Credential -eq $null) {
        Write-Output "Enter credentials for remote computer"
        $Credential = Get-Credential
    }
    
    #Script Variables
    $TaskWorkingDirectory = "`"$Directory"+$TaskName+"\"
    $TaskExecute = $TaskWorkingDirectory+$TaskEXE+"`""

    #If there are no servers in array, get servers that can successfully be connected to
    if ($ServerSuccessGroup -eq $Null) {
        $ServerSuccessGroup = Get-SuccessServer -Domain $Domain -OU $OU
        
        #Display the servers returned for confirmation
        Write-Host ""
        Write-Host "Servers that can successfully be connected to:"
        Write-Host ""
        Write-Output $ServerSuccessGroup.name
        Write-Host ""
    }
    
    #Execute command
    if ($choice -eq "y"){
        Write-Host ""
        Write-Output "Configuring scheduled tasks on remote computers."
        Write-Output ""
        foreach ($Server in $ServerSuccessGroup) {
                $Session = New-PSSession -ComputerName $Server.name -Credential $Credential
                
                #Run command in remote session for server
                Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                    
                    #Create Task Object
                    $Task = New-Object psobject
                    
                    #Add member properties
                    $Task | Add-Member Name $Using:TaskName
                    $Task | Add-Member Directory $Using:TaskWorkingDirectory
                    $Task | Add-Member EXE $Using:TaskEXE
                    $Task | Add-Member Execute $Using:TaskExecute
                    $Task | Add-Member TriggerTime $Using:TaskTriggerTime
                    
                    #Check if folder exists

                    #Create folder

                    #Set permissions

                    #Copy files to folder
                    #Copy-Item -source $TaskSourceFiles -Path $env:USERPROFILE+"\Downloads\"+$Task.name

                    #Create scheduled task (ST)
                    #Create Task action
                    $STAction = New-ScheduledTaskAction –Execute $Task.Execute
                    #Create Task Trigger
                    $STTrigger = New-ScheduledTaskTrigger -Daily -At $Task.TriggerTime
                    #Create task security principal
                    $STPrincipal = New-ScheduledTaskPrincipal -UserId "LOCALSERVICE" -LogonType ServiceAccount
                    #Create Scheduled task settings
                    $STSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable
                    #Create scheduled task object
                    $STObject = New-ScheduledTask -Action $STAction -Principal $STPrincipal -Trigger $STTrigger -Settings $STSettings
                    #Register scheduled task
                    Register-ScheduledTask $Task.Name -InputObject $STObject
                    
            }
        }
    }
	else {  
        Write-Host ""
        write-Error "Operation cancelled" -ErrorAction Stop
        Write-Host ""
    }
}