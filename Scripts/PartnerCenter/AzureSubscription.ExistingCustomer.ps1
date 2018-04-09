<#
#Script name: Create default subscription orders
#Creator: Wesley Trust
#Date: 2018-04-08
#Revision: 1
#References: 

.Synopsis
    
.Description

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
        Mandatory=$false,
        Position = 0,
        HelpMessage="Subscription name"
    )]
    [string]
    $friendlyName,
    [Parameter(
        Mandatory=$true
    )]
    [int]
    $Quantity,
    [Parameter(
        Mandatory=$false
    )]
    [string]
    $tenantid,
    [Parameter(
        Mandatory=$false
    )]
    [string]
    $CustomerName,
    [Parameter(
        Mandatory=$false
    )]
    [string]
    $TenantDomain,
    [Parameter(
        Mandatory=$false
    )]
    [string]
    $OfferID,
    [Parameter(
        Mandatory=$false
    )]
    [string]
    $CountryID,
    [Parameter(
        Mandatory=$false
    )]
    [switch]
    $force
)

Begin {
    try {

        # Load functions
        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Toolkit"
        . .\Check-RequiredModule.ps1

        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\PartnerCenter\Authentication"
        . .\Connect-PartnerCenter.ps1

        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\PartnerCenter\Customer"
        . .\Find-PCCustomer.ps1

        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\PartnerCenter\Order"
        . .\New-PCOrderItem.ps1
        
        # Required Modules
        $Module = "PartnerCenterModule,AzureAD"
        
        Check-RequiredModule -Modules $Module
        
        # Required Module Classes
        $Module = "PartnerCenterModule"
        
        # Import Module Classes
        $scriptBody = "using module $ModuleClasses"
        $script = [ScriptBlock]::Create($scriptBody)
        . $script
        
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

        # Get Customer
        if ($TenantID){
            $customer = Get-PCCustomer -Tenantid $tenantid
        }
        else {
            $customer = Find-PCCustomer -Name $CustomerName -Domain $TenantDomain
        }

        if ($customer){
            New-PCOrderItem `
                -TenantID $customer.id `
                -friendlyName "Microsoft Azure" `
                -Quantity "3" `
                -OfferID "MS-AZR-0146P" `
                -countryId "US" `
                -Force
        }
        else {
            $ErrorMessage = "No customer returned, unable to order without a customer"
            Write-Error $ErrorMessage
            throw $ErrorMessage
        }
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}