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
. ..Functions\Move-ServerOU.ps1
. ..Functions\Configure-Drive.ps1

function Post-VMProvision () {
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

        #Request New OU to move servers to
        [Parameter(
            Mandatory=$false,
            Position=3,
            HelpMessage="Enter in DN format",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $MoveOU
    )

    #Credentials
    #Prompt if no credentials stored
    if ($Credential -eq $null) {
        Write-Output "Enter credentials for remote computer"
        $Credential = Get-Credential
    }
    
    #Get Servers
    $ServerGroup = Get-Server -Domain $Domain -OU $OU

    #Check if server requires moving to new OU
    Move-OU -Domain $Domain -OU $OU

    #Update variable if new OU is specified
    If ($MoveOU -ne $null{
        $OU = $MoveOU
    } 
    
    #Check if data drives require configuration
    Configure-Drive -Domain $Domain -OU $OU
    
}