<#
#Script name: Configure service
#Creator: Wesley Trust
#Date: 2017-09-05
#Revision: 3
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

function Copy-Config() {
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
        $ServiceInstallLocation
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
                        
                    #Get file, pipe to remote session
                    Get-ChildItem $ServiceConfig | Copy-Item -Destination $ServiceInstallLocation -ToSession $Session -Force
                    
                    #Run command in remote session
                    Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                        
                        #Restart Service
                        Restart-Service $Using:ServiceName -WarningAction Stop
                    }
                    
                    #Remove session
                    Remove-PSSession -Session $Session

                    #Write Output
                    Write-Host ""
                    Write-Output "Successfully copied config file to "$Server.DNSHostName | Tee-Object -FilePath .\Success.log

                }
                Catch {
                    #Catch Exception
                    Write-Host ""
                    Write-Output $_.Exception.Message | Tee-Object -FilePath .\errorlog.txt
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