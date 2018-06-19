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
        HelpMessage="Specify Partner Center Subscription Offer Name"
    )]
    [string]
    $OfferName = "Microsoft Azure"
)

Begin {
    try {

        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\Azure\Authentication\Connect-AzureRMSubscription.ps1",
            "$FunctionLocation\PartnerCenter\Authentication\Connect-PartnerCenter.ps1",
            "$FunctionLocation\PartnerCenter\Customer\Get-PCCustomerSubscription.ps1",
            "$FunctionLocation\Toolkit\Install-Dependency.ps1"
        )
        # Function dot source
        foreach ($Function in $Functions){
            . $Function
        }
        
        # Required Module
        $Module = "AzureRM"
        $ModuleCore = "AzureRM.Netcore"
        
        Install-Dependency -Modules $Module -ModulesCore $ModuleCore
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {
        # Create hashtable of custom parameters
        $CustomParameters = @{}
        if ($TenantID){
            $CustomParameters += @{
                TenantID = $TenantID
            }
        }
        if ($SubscriptionID){
            $CustomParameters += @{
                SubscriptionID = $SubscriptionID
            }
        }
        # Connect to Azure RM Subscription with custom parameters
        $AzureSubscriptions = Connect-AzureRMSubscription @CustomParameters
        if (!$AzureSubscriptions){
            # Required Module
            $Module = "PartnerCenterModule,AzureAD"
            
            Install-Dependency -Modules $Module
            
            # Connect to Partner Center
            Connect-PartnerCenter -Credential $Credential | Out-Null

            # Get Parter Center Azure Subscriptions
            $AzureSubscriptions = Get-PCCustomerSubscription -OfferName $OfferName -TenantId $TenantID
        }
        if ($AzureSubscriptions){
            # Display subscriptions
            Write-Host "`nSubscriptions you have access to:"
            $AzureSubscriptions | Select-Object CustomerName,SubscriptionName,SubscriptionId | Format-List | Out-Host -Paging
            
            # Request subscription ID
            $SubscriptionID = Read-Host "Enter subscription ID"

            # While there is no valid subscription ID specified
            while ($AzureSubscriptions.subscriptionid -notcontains $SubscriptionID){
                $WarningMessage = "Invalid Subscription Id $SubscriptionID"
                Write-Warning $WarningMessage
                $SubscriptionId = Read-Host "Enter valid subscription ID"
            }
            # Filter to selected subscription
            $ParterCenterSubscription = $AzureSubscriptions | Where-Object SubscriptionID -eq $SubscriptionId
            # Get full subscription name
            $SubscriptionName = $ParterCenterSubscription.SubscriptionName
            # Change context to selected subscription
            Write-Host "`nSelecting Subscription: $SubscriptionName"
            $AzureConnection = Set-AzureRmContext `
                -SubscriptionId $ParterCenterSubscription.SubscriptionId `
                -TenantId $ParterCenterSubscription.tenantid
            return $AzureConnection
        }
        else {
            $ErrorMessage = "No Azure Subscriptions returned"
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