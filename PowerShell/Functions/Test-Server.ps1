<#
#Script name: Test connection to server
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision: 3
#References:

.Synopsis
    Script to call a function that gets servers within an OU and tests that the servers can be connected to remotely.
.Description
    Script to call a function that gets servers within an OU and tests that the servers can be connected to remotely,
    returned in an an array including connection status.
.Example
    Specify the fully qualified Domain Name (FQDN) and Organisational Unit (OU) by distinguished name (DN).
    Configure-Drive -Domain $Domain -OU $OU
.Example
    
#>

#Include Functions
. .\Get-Server.ps1

function Test-Server () {
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
            HelpMessage="Enter in DN format",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $OU
        )
    
    #If there are no credentials, prompt for credentials
    if ($Credential -eq $null) {
        Write-Output "Enter credentials for remote computer"
        $Credential = Get-Credential
    }
    
    #Get Servers
    $ServerGroup = Get-Server -Domain $Domain -OU $OU

    #Check server name(s) returned
    if ($ServerGroup -eq $null){
        Write-Error 'No servers returned.' -ErrorAction Stop
    }

    #Write message to host
    Write-Host "Testing remote connection to servers"

    #Select DNS host name from server objects returned
    $ServerGroup = $ServerGroup | Select-Object -ExpandProperty DNSHostName

    #Try connecting to server
    $ServerGroup = foreach ($Server in $ServerGroup){
        try {
            #Open a remote session
            $Session = New-PSSession -ComputerName $Server -Credential $Credential -ErrorAction SilentlyContinue
            
            #Remove session
            Remove-pssession -session $Session
            
            #Create object property variable
            $ObjectProperties = @{
            Name = $Server
            Status = "Success"
            }
            
            #Create a new object, with the properties
            New-Object psobject -Property $ObjectProperties
        }
        catch {
            #Catch failures and create object property variable
            $ObjectProperties = @{
            Name = $Server
            Status = "Fail"
            }
            
            #Create a new object, with the properties
            New-Object psobject -Property $ObjectProperties
        }
        Continue
    }
    Return $ServerGroup
}

function Get-SuccessServer () {
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
            HelpMessage="Enter in DN format",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $OU
        )
       
    $ServerGroup = Test-Server -Domain $Domain -OU $OU
        
    #Check server name(s) are returned
    if ($ServerGroup -eq $null){
        Write-Host ""
        Write-Error 'No servers returned.' -ErrorAction Stop
        }
    
    #Add successfully connected servers to variable
    $ServerSuccessGroup = $ServerGroup | Where-Object -Property Status -eq "Success"
    
    #Check whether no servers are successful.
    If ($ServerSuccessGroup -eq $null){
        Write-Error "Unable to connect to any servers." -ErrorAction Stop
    }
    
    #Return servers
    Return $ServerSuccessGroup
}