<#
#Script name: Check Azure AD tenant domain name availablity
#Creator: Wesley Trust
#Date: 2018-04-08
#Revision: 1
#References: 

.Synopsis
    Checks whether an Azure AD domain name is available.
.Description
    Alphanumeric, .onmicrosoft.com is appended for the check via Partner Center, authentication is required.
.Example

.Example
    
#>

Param(
    [Parameter(
        Mandatory=$false,
        Position = 0,
        HelpMessage="Specify a PowerShell credential object"
    )]
    [pscredential]
    $Credential,
    [Parameter(
        Mandatory=$true,
        Position = 0,
        HelpMessage="Specify an alphanumeric tenant name (excluding .onmicrosoft.com)"
    )]
    [string]
    [ValidatePattern('^[a-zA-Z0-9]+$')]
    $TenantName
)

Begin {
    try {

        # Load functions
        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Toolkit"
        . .\Check-RequiredModule.ps1

        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\PartnerCenter\Authentication"
        . .\Connect-PartnerCenter.ps1
        
        # Required Module
        $Module = "PartnerCenterModule"
        
        Check-RequiredModule -Modules $Module
        
        # Connect to Partner Center
        Connect-PartnerCenter -Credential $Credential | Out-Null
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {
        # Build Azure AD Tenant Domain
        $TenantDomainName = $TenantName+'.onmicrosoft.com'
        
        # Check Azure AD domain via Partner Center
        $NameAvailability = Get-PCDomainAvailability -Domain $TenantDomainName

        # Display availability
        if ($NameAvailability){
            Write-Host "`nThe tenant domain $TenantDomainName is available`n"
        }
        else {
            Write-Host "`nThe tenant domain $TenantDomainName is not available`n"
        }
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}