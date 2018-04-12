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
    $OfferName = "Microsoft Azure",
    [Parameter(
        Mandatory=$false
    )]
    [string]
    $tenantid
)

Begin {
    try {

        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\PartnerCenter\Authentication\Connect-PartnerCenter.ps1",
            "$FunctionLocation\PartnerCenter\Customer\Get-PCCustomerSubscription.ps1",
            "$FunctionLocation\PartnerCenter\Customer\Find-PCCustomer.ps1",
            "$FunctionLocation\Toolkit\Check-RequiredModule.ps1"
        )
        # Function dot source
        foreach ($Function in $Functions){
            . $Function
        }
        
        # Required Module
        $Module = "PartnerCenterModule,AzureAD"
        
        Check-RequiredModule -Modules $Module
        
        # Required Module Classes
        $ModuleClasses = "PartnerCenterModule"
        
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
        elseif ($CustomerName -or $TenantDomain){
            $customer = Find-PCCustomer -Name $CustomerName -Domain $TenantDomain
            $tenantid = $customer.id
        }
        
        # Get Azure Subscriptions
        Get-PCCustomerSubscription -OfferName $OfferName -tenantid $tenantid
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}