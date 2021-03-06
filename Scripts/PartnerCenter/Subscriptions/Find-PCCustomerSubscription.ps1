<#
#Script name: Connect to Azure subscription
#Creator: Wesley Trust
#Date: 2018-04-10
#Revision: 2
#References: 

.Synopsis
    Connects to an Azure RM subscription
.Description

.Example
    
.Example
    
#>

Param(
    [Parameter(
        Mandatory=$false,
        HelpMessage="Enter the subscription ID"
    )]
    [string]
    $SubscriptionID,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Enter the subscription ID"
    )]
    [string]
    $TenantID,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Enter a subscription name"
    )]
    [string]
    $SubscriptionName,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify PowerShell credential object"
    )]
    [pscredential]
    $Credential,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify whether to reauthenticate with different credentials"
    )]
    [switch]
    $ReAuthenticate,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify whether to confirm disconnection/reauthentication of active session"
    )]
    [switch]
    $Confirm,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify Partner Center Offer Name"
    )]
    [string]
    $OfferName = "Microsoft Azure"
)

Begin {
    try {

        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\PartnerCenter\Authentication\Test-PartnerCenterConnection.ps1",
            "$FunctionLocation\PartnerCenter\Authentication\Connect-PartnerCenter.ps1",
            "$FunctionLocation\PartnerCenter\Customer\Get-PCCustomerSubscription.ps1",
            "$FunctionLocation\PartnerCenter\Customer\Find-PCCustomer.ps1",
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
        
        # Check for active connection
        if (!$ReAuthenticate){
            $TestConnection = Test-PartnerCenterConnection -Credential $Credential
            if ($TestConnection.reauthenticate){
                $ReAuthenticate = $true
            }
        }

        # If no active connection, connect
        if (!$TestConnection.ActiveConnection -or $ReAuthenticate){
            Write-Host "`nAuthenticating with Partner Center`n"
            $PartnerCenterConnection = Connect-PartnerCenter -Credential $Credential
            
            if (!$PartnerCenterConnection){
                $ErrorMessage = "Unable to connect to Partner Center"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }
        }
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

        # Get Parter Center Azure Subscriptions
        $AzureCustomerSubscriptions = Get-PCCustomerSubscription -OfferName $OfferName -Tenantid $TenantID
        if ($AzureCustomerSubscriptions){
            # Display subscriptions
            Write-Host "`nSubscriptions you have access to:"
            $AzureCustomerSubscriptions | Format-List Name,SubscriptionId,State -GroupBy Customer | Out-Host -Paging
            
            # Request subscription ID
            $SubscriptionID = Read-Host "Enter subscription ID"

            # While there is no valid subscription ID specified
            while ($AzureCustomerSubscriptions.subscriptionid -notcontains $SubscriptionID){
                $WarningMessage = "Invalid Subscription Id $SubscriptionID"
                Write-Warning $WarningMessage
                $SubscriptionId = Read-Host "Enter valid subscription ID"
            }
            # Filter to selected subscription
            $ParterCenterSubscription = $AzureCustomerSubscriptions | Where-Object SubscriptionID -eq $SubscriptionId
            return $ParterCenterSubscription
        }
        else {
            $ErrorMessage = "No Partner Center Customers have $OfferName Subscriptions"
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