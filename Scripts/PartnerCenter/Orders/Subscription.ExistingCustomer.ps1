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
        Mandatory=$true,
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
        Mandatory=$true
    )]
    [string]
    $OfferID,
    [Parameter(
        Mandatory=$true
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

        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\PartnerCenter\Authentication\Connect-PartnerCenter.ps1",
            "$FunctionLocation\PartnerCenter\Customer\Find-PCCustomer.ps1",
            "$FunctionLocation\PartnerCenter\Order\New-PCOrderItem.ps1",
            "$FunctionLocation\Toolkit\Invoke-DependencyCheck.ps1"
        )
        # Function dot source
        foreach ($Function in $Functions){
            . $Function
        }
        
        # Required Module
        $Module = "PartnerCenterModule,AzureAD"
        
        Invoke-DependencyCheck -Modules $Module
        
        # Required Module Classes
        $ModuleClasses = "PartnerCenterModule"
        
        # Import Module Classes
        $scriptBody = "using module $ModuleClasses"
        $script = [ScriptBlock]::Create($scriptBody)
        . $script
        
        # Connect to Partner Center
        Connect-PartnerCenter -Credential $Credential

    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {

        # Get Customer
        if (!$TenantID){
            $customer = Get-PCCustomer -Tenantid $tenantid
        }
        else {
            $customer = Find-PCCustomer -Name $CustomerName -Domain $TenantDomain
        }
        if ($customer){

            # Provision Orders
            New-PCOrderItem `
                -TenantID $customer.id `
                -friendlyName $friendlyName `
                -Quantity $Quantity `
                -OfferID $OfferID `
                -countryId $CountryID `
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