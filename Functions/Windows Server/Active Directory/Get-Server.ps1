<#
#Script name: Get servers from an OU
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision: 3
#References:
#ToDo
    .Check home domain, to see whether script can be run from local device.
    ..Check whether AD module is installed, so can bypass the need for a remote connection.

.Synopsis
    Script that calls a function to resolve the domain controller, from the domain, and gets the servers from within an OU.
.Description
    Script that calls a function to resolve the domain controller, from the domain, and gets the servers from within an OU,
    with the results put in an array.
.Example
    Specify the fully qualified Domain Name (FQDN) and Organisational Unit (OU) by distinguished name (DN).
    Configure-Drive -Domain $Domain -OU $OU
.Example
    

#>

#Include Functions
Set-Location "C:\Users\wesley.trust\GitHub\Scripts\Functions\Active Directory"
. .\Get-DC.ps1

Function Get-Server () {
    
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
    
    Begin {
        #If there are no credentials, prompt for credentials
        if ($Credential -eq $null) {
            Write-Output "Enter credentials for remote computer"
            $Credential = Get-Credential
        }
    }

    Process {

        #Get DC and store in variable
        $DC = Get-DC -Domain $Domain
    
        #Attempting conection to domain controller
        Write-Host "Attempting conection to $DC"
    
        #Try pinging domain controller
        Try {
            Test-Connection $DC -Count 1 | Out-Null
        }
        Catch {
            Write-Host ""
            Write-Error "Unable to ping '$DC'" -ErrorAction Stop
        }
        
        #Try remotely connecting to domain controller
        try {
            #Create PowerShell session
            $Session = New-PSSession -ComputerName $DC -Credential $Credential
        }
        catch {
            Write-Error "Failed to remotely connect to $DC" -ErrorAction Stop
        }
    
        #Write message to host
        Write-Host ""
        Write-Host "Getting servers within OU:"
        Write-Host ""
        Write-Host $OU
        
        #Invoke remote command within open session
        $ServerGroup = Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
    
            #Get Servers within OU
            Get-ADComputer -Filter * -SearchBase $Using:OU
        }
        
        #Remove session
        Remove-pssession -Session $Session
        
        #Check if servers are returned
        if ($ServerGroup -eq $Null) {
            Write-Host ""
            Write-Error "No servers returned." -ErrorAction Stop
        }
        else {
            Return $ServerGroup
        }
    }

    End {

    }
} 