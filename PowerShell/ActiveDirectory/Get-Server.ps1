<#
#Script name: Get servers from an OU
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision:
#References:

.Synopsis
    Script to get the servers from an OU and put in an array.
.Description
    Script to get the servers from an OU and put in an array. Includes Get-DC function.
.Example
    Specify server domain and OU.
    Get-Servers -Domain $Domain -OU $OU
.Example
    

#>

#Include Functions
. .\Get-DC.ps1
#. .\Connect-Server.ps1

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
            HelpMessage="Enter the FQDN",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $OU)
    
    #Get credentials
    $Credential = Get-Credential
    #Get DC and store in variable
    $DC = Get-DC -Domain $Domain

    #Try connecting to DC
    Try {
            Test-Connection $DC -Count 1 -ErrorAction Stop | Out-Null
        }
        Catch {
            "Unable to connect to '$DC'"
        }

    $Session = New-PSSession -ComputerName $DC -Credential $Credential
    $ServerGroup = Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {

        #Get Servers within OU
        Get-ADComputer -Filter * -SearchBase $Using:OU
    }
        
    #Remove session
    Remove-pssession -Session $Session

    #Check server name(s) returned
    if ($ServerGroup -eq $null){
        Write-Error 'No servers returned.' -ErrorAction Stop
    }
    else {
        Write-Output $ServerGroup | Select-Object Name
    }
    }
