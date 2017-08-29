<#
#Script name: Run server command template
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision:
#References:

.Synopsis
    Template that calls a function that tests the connection to remote servers, then executes a command.
.Description
    Template that calls a function that tests the connection to remote servers,
    then executes a command on successful servers after confirmation.
.Example
    Specify the fully qualified Domain Name (FQDN) and Organisational Unit (OU) by distinguished name (DN).
    Configure-Drive -Domain $Domain -OU $OU
.Example
    

#>

#Include Functions
. .\Test-Server.ps1

function New-ServerCommand () {
    #Parameters
    Param(
        #Request Domain
        [Parameter(
            Mandatory=$True,
            Position=1,
            HelpMessage="Enter the FQDN",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        
        #Request OU
        [Parameter(
            Mandatory=$True,
            Position=2,
            HelpMessage="Enter the FQDN",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $OU)
    
    #Storage
    $Volume = "Data"
    $VirtualDisk = $Volume+"VD"
    $StoragePool = $Volume+"SP"

    #If there are no credentials, prompt for credentials
    if ($Credential -eq $null) {
        Write-Output "Enter credentials for remote computer"
        $Credential = Get-Credential
    }
    
    #Get Servers
    $ServerGroup = Test-Server -Domain $Domain -OU $OU
    
    #Check server name(s) returned
    if ($ServerGroup -eq $null){
        Write-Host ""
        Write-Error 'No servers returned.' -ErrorAction Stop
    }

    #Add successfully connected servers to variable
    $ServerSuccessGroup = $ServerGroup | Where-Object -Property Status -eq "Success"
    #Add failed to connect servers to variable
    $ServerFailGroup = $ServerGroup | Where-Object -Property Status -eq "Fail"
    
    #Check whether no servers are successful.
    If ($ServerSuccessGroup -eq $null){
        Write-Error "Unable to connect to any servers." -ErrorAction Stop
    }

    #Display host message for successfully connected servers.
    Write-Host ""
    Write-Host "Successfully connected to:"
    Write-Host ""
    Write-Output $ServerSuccessGroup.name
    Write-Host ""

    #Check if there are any servers that failed.
    If ($ServerFailGroup -eq $null){
    }
    #If there are servers that failed, display a host message.
    Else {
        Write-Host "Failed to connect to:"
        Write-Host ""
        Write-Output $ServerFailGroup.name
        Write-Host ""
    }
    
    #Prompt for input
    while ($choice -notmatch "[y|n]"){
        $choice = read-host "Run command on successful servers? (Y/N)"
        
    }
    if ($choice -eq "y"){
        Write-Host ""
        Write-Output "Return Y"
    }
    else {  
        Write-Host ""
        write-output "Return N"
    }
}