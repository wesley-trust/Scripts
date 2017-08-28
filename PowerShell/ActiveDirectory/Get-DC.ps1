<#
#Script name: Get domain controller from domain name
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision:
#References:

.Synopsis
    Script to get a domain controller from a domain name
.Description
    Script to get a domain controller from a domain name, when using an AD integrated DNS zone for the domain
.Example
    Specify domain name
    Get-DC -Domain "DOMANNAME"
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
    #Return string
    $DC
    }
