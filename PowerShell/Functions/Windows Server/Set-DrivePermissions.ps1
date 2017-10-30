<#
#Script name: Run server command template
#Creator: Wesley Trust
#Date: 2017-08-31
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
        $OU)

    #Credentials
    #Prompt if no credentials stored
    if ($Credential -eq $null) {
        Write-Output "Enter credentials for remote computer"
        $Credential = Get-Credential
    }
    
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
    
    #Prompt for input
    while ($choice -notmatch "[y|n]"){
        $choice = read-host "Run command on servers? (Y/N)"
        
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