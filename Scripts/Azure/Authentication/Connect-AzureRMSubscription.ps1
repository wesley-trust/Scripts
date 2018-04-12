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
    $Confirm
)

Begin {
    try {

        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\Azure\Authentication\Connect-AzureRMSubscription.ps1",
            "$FunctionLocation\PartnerCenter\Authentication\Connect-PartnerCenter.ps1",
            "$FunctionLocation\PartnerCenter\Customer\Get-PCCustomerSubscription.ps1",
            "$FunctionLocation\Toolkit\Check-RequiredModule.ps1"
        )
        # Function dot source
        foreach ($Function in $Functions){
            . $Function
        }
        
        # Required Module
        $Module = "AzureRM"
        $ModuleCore = "AzureRM.Netcore"
        
        Check-RequiredModule -Modules $Module -ModulesCore $ModuleCore

    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {

        # Create hashtable of custom parameters
        $CustomParameters = @{
            SubscriptionID = $SubscriptionID;
            TenantID = $TenantID;
            SubscriptionName = $SubscriptionName;
            Credential = $Credential;
        }
        # If switches are true, append to custom parameters
        if ($ReAuthenticate){
            $CustomParameters += @{
                ReAuthenticate = $true
            }
        }
        if ($Force){
            $CustomParameters += @{
                Force = $true
            }
        }

        # Connect to Azure RM Subscription with custom parameters
        $AzureRMSubscription = Connect-AzureRMSubscription @CustomParameters
        if ($AzureRMSubscription){
            return $AzureRMSubscription
        }
        else {
            # Required Module
            $Module = "PartnerCenterModule,AzureAD"
            
            Check-RequiredModule -Modules $Module
            
            # Connect to Partner Center
            Connect-PartnerCenter -Credential $Credential | Out-Null

            # Get Azure Subscriptions
            $AzureCustomerSubscriptions = Get-PCCustomerSubscription -OfferName "Microsoft Azure"
            if ($AzureCustomerSubscriptions){
                # Display subscriptions
                Write-Host "`nSubscriptions you have access to:"
                $AzureCustomerSubscriptions | ForEach-Object{
                    # Build hastable of custom parameters
                    $CustomParameters = @{}
                    $CustomParameters += @{
                        TenantID = $_.TenantID
                        SubscriptionID = $_.SubscriptionID
                    }
                    
                    # Load subscriptions
                    $Subscriptions = Get-AzureRmSubscription @CustomParameters

                    if ($Subscriptions){
                        $Subscriptions | Select-Object Name, Id | Format-List | Out-Host -Paging
                    }
                }
                
                # Request subscription ID
                $SubscriptionID = Read-Host "Enter subscription ID"
                
                # While there is no valid subscription ID specified
                while ($AzureCustomerSubscriptions.SubscriptionId -notcontains $SubscriptionID){
                    $WarningMessage = "Invalid Subscription Id $SubscriptionID"
                    Write-Warning $WarningMessage
                    $SubscriptionId = Read-Host "Enter valid subscription ID"
                }
                $ParterCenterSubscription = $AzureCustomerSubscriptions | Where-Object SubscriptionID -eq $SubscriptionId
            }
            else {
                $ErrorMessage = "No subscriptions returned that you have access to"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }
        }
    # Connect to subscription
    Connect-AzureRMSubscription -tenantid $ParterCenterSubscription.tenantid -subscriptionid $ParterCenterSubscription.subscriptionid
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}