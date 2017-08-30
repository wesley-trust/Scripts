<#
#Script name: Get domain controller from domain name
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision: 2
#References:

.Synopsis
    Script that resolves a domain controller from a domain name.
.Description
    Script that resolves a domain controller from a domain name, when using an AD integrated DNS zone for the domain.
.Example
    Specify the fully qualified Domain Name (FQDN) and Organisational Unit (OU) by distinguished name (DN).
    Configure-Drive -Domain $Domain -OU $OU
.Example
    

#>

Function Get-DC () {
    #Request Domain name
    Param(
        [Parameter(
            Mandatory=$True,
            Position=1,
            HelpMessage="Enter the FQDN",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain)
    
    #Get start of authority of domain
    $DC = Resolve-DnsName $Domain -Type SOA
    
    #Select primary server, convert to string
    $DC= $DC.PrimaryServer.ToString()
    
    #Write message to host
    Write-Host ""
    If ($DC -eq $null){
        Write-Error "Unable to resolve a domain controller" -ErrorAction Stop
    }
    Else{
        Write-Host "Found Domain Controller"
        Write-Host ""
        
    }
    
    #Return domain controller
    Return $DC
}
