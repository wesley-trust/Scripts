<#
#Script name: Get Exchange Info
#Creator: Wesley Trust
#Date: 2018-03-29
#Revision: 2
#References: 

.Synopsis
    Script to gather exchange virtual directory, organisation and mailbox info
.Description
    Calls three exisiting functions to execute Exchange commands
.Example
    
.Example
    
#>

Param(
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify path for CSV export"
    )]
    [string]
    $CSVPath = "$home\Documents\ExchangeInfo"
)

try {

    # Check if CSVPath exists
    $PathExists = Get-item -Path $CSVPath -ErrorAction SilentlyContinue
    if (!$PathExists){
        $PathExists = New-item -ItemType Directory -Path $CSVPath
    }

    # Dot source functions
    Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Exchange"
    . .\Get-ExchangeInfo.ps1

    # Execute
    Get-ExchangeDirectoryInfo -CSVPath $CSVPath
    Get-ExchangeOrganisationInfo -CSVPath $CSVPath
    Get-ExchangeMailboxInfo -CSVPath $CSVPath

}
Catch {
    Write-Error -Message $_.exception
    throw $_.exception
}
