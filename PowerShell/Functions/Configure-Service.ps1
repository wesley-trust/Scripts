<#
#Script name: Configure service
#Creator: Wesley Trust
#Date: 2017-09-05
#Revision: 2
#References:
#ToDo
    .Write error logging to file
    .Pipeline input for servers
    .Force parameter for install
    .Ability to override server connection checks?

.Synopsis
    Function that calls a function that tests servers, within an OU, can be connected to remotely, and installs a service.
.Description
    Function that calls a function that tests servers, within an OU, can be connected to remotely, and installs a service,
    logging success and failures in a text file.
.Example
    Specify the fully qualified Domain Name (FQDN) and Organisational Unit (OU) by distinguished name (DN).
    Configure-Service -Domain $Domain -OU $OU -ServiceEXE $ServiceEXE -ServiceName $ServiceName -ServiceConfig $ServiceConfig -ServiceInstallLocation $ServiceInstallLocation

#>

#Include Functions
. .\Test-Server.ps1

function Configure-Service() {
    #Parameters
    Param(
        #Request Domain
        [Parameter(
            Mandatory=$false,
            Position=1,
            HelpMessage="Enter the FQDN",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        
        #Request OU
        [Parameter(
            Mandatory=$false,
            Position=2,
            HelpMessage="Enter in DN format",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $OU,
        
        #Server Host name
        [Parameter(
            Mandatory=$false,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DNSHostName,
        
        #Server status
        [Parameter(
            Mandatory=$false,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Status,
        
        #Service EXE
        [Parameter(
            Mandatory=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceEXE,
        
        #Service Name
        [Parameter(
            Mandatory=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceName,
        
        #Service Config
        [Parameter(
            Mandatory=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceConfig,

        #Service InstallLocation
        [Parameter(
            Mandatory=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceInstallLocation,
        
        #Service InstallLocation
        [Parameter(
            Mandatory=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ArgumentList
        )

    Begin {
        
        #If there are no credentials, prompt for credentials
        if ($Credential -eq $null) {
            Write-Output "Enter credentials for remote computer"
            $Credential = Get-Credential
        }
    }
    
    Process {

        #Reconstitute object from pipeline
        $ServerGroup = foreach ($Server in $_){
            $ObjectProperties = @{
                DNSHostName  = $Server.DNSHostName
                Status  = $Server.Status
            }
            New-Object psobject -Property $ObjectProperties
        }

        #If there are no statuses for servers
        if (!$Server.Status){

            #If there are no servers at all in array, get servers that can successfully be connected to
            if (!$ServerGroup){
                
                #If there aren't any servers, and no domain and OU are specified, get successful servers
                If (!$Domain -or !$ou){
                    $ServerSuccessGroup = Get-SuccessServer
                }
                else {
                    #Get successful servers and pass parameters
                    $ServerSuccessGroup = Get-SuccessServer -Domain $Domain -OU $OU
                }
            }
            Else {
                
                #Pipe the servers to test and get successful ones
                $ServerSuccessGroup = $ServerGroup | Test-Server | Get-SuccessServer
            }
        }
        
            #Display the servers returned for confirmation
            Write-Host ""
            Write-Host "Successfully connected to:"
            Write-Host ""
            Write-Output $ServerSuccessGroup.DNSHostName
            Write-Host ""
    
        #Prompt for input
        while ($choice -notmatch "[y|n]"){
            $choice = read-host "Configure service? (Y/N)"
        }
        
        #Execute command
        if ($choice -eq "y"){
            Write-Host ""
            Write-Output "Configuring service on remote computers."
            foreach ($Server in $ServerSuccessGroup) {
                
                try {
                    
                    #Create new session
                    $Session = New-PSSession -ComputerName $Server.DNSHostName -Credential $Credential -ErrorAction Stop
                    
                    try {
                        #Run command in remote session to install
                        Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                            
                            #Check if service is installed
                            $Service = Get-Service $Using:ServiceName -ErrorAction Stop
                            
                            #Check if service is running
                            If ($Service | Where-Object Status -eq "Running") {
        
                                #Service already installed and running
                                Write-Host ""
                                Write-Output "Service already installed and running on"$using:Server.DNSHostName | Tee-Object -Append -FilePath .\RunningLog.txt
                            }
                            Else {
                                
                                try {
                                    #Try starting service
                                    $Service = $Service | Start-Service -PassThru -ErrorAction Stop
                                    
                                    #Service already installed and running
                                    Write-Host ""
                                    Write-Output "Service already installed and now running on"$using:Server.DNSHostName | Tee-Object -Append -FilePath .\RunningLog.txt
                                }
                                Catch {
                                    #Service already installed but won't start
                                    Write-Host ""
                                    Write-Output "Service already installed but will not start on"$using:Server.DNSHostName | Tee-Object -Append -FilePath .\StoppedLog.txt
                                }
                            }
                        }
                    }
                    catch {

                        Try{
                            #Get file, pipe to copy to remote session
                            Get-ChildItem $ServiceEXE | Copy-Item -Destination $env:SystemDrive\ -ToSession $Session -Force -ErrorAction Stop
                        }
                        Catch {
                            Write-Error "Failed to copy service to server." -ErrorAction Stop
                        }
                        try{
                            #Run command in remote session to install
                            Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                                
                                #Execute installer
                                Set-Location $env:SystemDrive\
                                
                                #$FileName = Split-Path $Using:ServiceEXE -Leaf
                                #Start-Process "msiexec.exe" -ArgumentList "/qn /i $FileName" -Wait
                                
                                Start-Process "msiexec.exe" -ArgumentList $Using:ArgumentList -Wait
                            }
                        }
                        Catch {
                            Write-Error "Failed to install service" -ErrorAction Stop
                        }
                        Try{
                            #Get file, pipe to remote session
                            Get-ChildItem $ServiceConfig | Copy-Item -Destination $ServiceInstallLocation -ToSession $Session -Force
                        }
                        Catch {
                            Write-Error "Failed to copy config to server" -ErrorAction Stop
                        }
                        Finally {
                            #Run command in remote session
                            Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                                
                                #Restart Service
                                try {
                                    Restart-Service $Using:ServiceName -WarningAction Stop
                                }
                                Catch {
                                    Write-Error "Unable to restart service on"$Server.DNSHostName
                                }
                                Finally {
                                    #Clean up
                                    Remove-Item $Using:ServiceEXE
                                }
                            }
                        }
                    
                        #Successfully configured service
                        Write-Host ""
                        Write-Output "Successfully configured service on" $Server.DNSHostName | Tee-Object -Append -FilePath .\SuccessLog.txt
                                            
                        #Remove session
                        Remove-PSSession -Session $Session
                    }                    
                    Finally {
                        #Remove session
                        Remove-PSSession -Session $Session
                    }
                }
                Catch {
                    #Service was not installed
                    Write-Host ""
                    Write-Output "Service not installed on"$Server.DNSHostName | Tee-Object -Append -FilePath .\ErrorLog.txt
                    Write-Host ""
                }
            }
        }
        else {  
            Write-Host ""
            write-Error "Operation cancelled" -ErrorAction Stop
            Write-Host ""
        }
    }
    End {
        
    }
}