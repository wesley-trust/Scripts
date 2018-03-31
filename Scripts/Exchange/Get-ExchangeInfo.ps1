<#
#Script name: Get Exchange Info
#Creator: Wesley Trust
#Date: 2018-03-29
#Revision: 1
#References: 

.Synopsis
    Script to get Exchange info
.Description

.Example
    
.Example
    
#>

Param(
    [Parameter(
        Mandatory=$true,
        HelpMessage="Specify path for CSV export"
    )]
    [string]
    $CSVPath
)

try {
    # Get Exchange certificate info
    Get-ExchangeCertificate | Select-Object Subject,IsSelfSigned,Issuer,Services,Status,NotAfter -OutVariable ExchangeCertificate
    $ExchangeCertificate | Export-CSV $CSVPath"\ExchangeCertificate.csv"
    
    # Get Exchange virtual directory info
    Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Exchange"
    . .\Get-EXVirtualDirectories.ps1

    Get-EXVirtualDirectories -CSVPath $CSVPath"\EXVirtualDirectories.csv"

    # Get mailbox info
    Get-Mailbox -ResultSize unlimited | Get-MailboxStatistics | Export-CSV $CSVPath"\MailboxStatistics.csv"
    Get-Mailbox -ResultSize unlimited | Get-MailboxFolderStatistics | Export-CSV $CSVPath"\MailboxFolderStatistics.csv"

    # Get Organisation information
    Get-OrganizationConfig | Export-Csv $CSVPath"\OrganizationConfig.csv"
    
    # Get CAS information
    Get-ClientAccessServer | Export-Csv $CSVPath"\ClientAccessServer.csv"

    # Get Exchange Servers
    Get-ExchangeServer | Export-Csv $CSVPath"\ExchangeServer.csv"

    # Get domains
    Get-AcceptedDomain | Export-Csv $CSVPath"\AcceptedDomain.csv"
    Get-RemoteDomain | Export-Csv $CSVPath"\RemoteDomain.csv"
}
Catch {
    Write-Error -Message $_.exception
    throw $_.exception
}
