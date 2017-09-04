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
        
        #Domain name
        [Parameter(
            Mandatory=$false,
            Position=1,
            HelpMessage="Enter the FQDN",
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        
        #Request OU
        [Parameter(
            Mandatory=$false,
            Position=2,
            HelpMessage="Enter in DN format",
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
        $DNSHostName
    )

    Begin {
        #If there are no credentials, prompt for credentials
        if ($Credential -eq $null) {
            Write-Output "Enter credentials for remote computer"
            $Credential = Get-Credential
        }

        #Write message to host
        Write-Host ""
        Write-Host "Testing remote connection to servers"
    }

    Process
    {
        #Reconstitute object from pipeline
        $ServerGroup = foreach ($Server in $_)
        {
            $ObjectProperties = @{
                DNSHostName  = $Server.DNSHostName
            }
            New-Object psobject -Property $ObjectProperties
        }

        #Check there are servers in array
        if ($ServerGroup -eq $null){
            
            #If there aren't, and no domain and OU are specified, get servers
            If (!$Domain -or !$ou){
                $ServerGroup = Get-Server
            }
            else {
                #Get servers and pass parameters
                $ServerGroup = Get-Server -Domain $domain -OU $OU
            }
        }
        
        #Check there are servers in the array
        if ($ServerGroup -eq $null){
            Write-Error 'No servers returned.' -ErrorAction Stop
        }
        
        $ServerGroup = foreach ($Server in $ServerGroup){
            try {
                #Open a remote session
                $Session = New-PSSession -ComputerName $Server.DNSHostName -Credential $Credential -ErrorAction SilentlyContinue
                
                #Remove session
                Remove-pssession -session $Session
                
                #Create object property variable
                $ObjectProperties = @{
                    DNSHostName = $Server.DNSHostName
                    Status = "Success"
                }
                
                #Create a new object, with the properties
                New-Object psobject -Property $ObjectProperties
            }
            catch {
                #Catch failures and create object property variable
                $ObjectProperties = @{
                    DNSHostName = $Server.DNSHostName
                    Status = "Fail"
                }
                
                #Create a new object, with the properties
                New-Object psobject -Property $ObjectProperties
            }
            Continue
        }
        Return $ServerGroup
    }
    End {

    }
}

function Get-SuccessServer () {
    #Parameters
    Param(
        
        #Domain name
        [Parameter(
            Mandatory=$false,
            Position=1,
            HelpMessage="Enter the FQDN")]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        
        #Request OU
        [Parameter(
            Mandatory=$false,
            Position=2,
            HelpMessage="Enter in DN format",
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
        $Status
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

        #Check there are servers in array
        if (!$ServerGroup){
            
            #If there aren't, and no domain and OU are specified, test servers
            If (!$Domain -and !$ou){
                $ServerGroup = Test-Server
            }
            else {
                #Test servers and pass parameters
                $ServerGroup = Test-Server -Domain $domain -OU $OU
            }
        }

        #Write-Output $ServerGroup
        
        #Check there are servers in the array
        if (!$ServerGroup){
            Write-Error 'No servers returned.' -ErrorAction Stop
        }

        #Add successfully connected servers to variable
        $ServerSuccessGroup = $ServerGroup | Where-Object -Property Status -eq "Success"

        #Check whether no servers are successful.
<#         If ($ServerSuccessGroup -eq $null){
            Write-Error "Unable to connect to any servers." -ErrorAction Stop
        } #>
        Return $ServerSuccessGroup
    }
    
    End {
        
            }
}