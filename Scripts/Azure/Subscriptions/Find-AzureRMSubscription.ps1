<#
#Script name: Find Azure subscription
#Creator: Wesley Trust
#Date: 2018-04-10
#Revision: 3
#References: 

.Synopsis
    Finds Azure subscriptions from Azure direct, or via Partner Center
.Description
    Uses Tenant ID and/or Subscription ID or Subscription name to search
    Connects to selected subscription.
.Example

.Example

#>

Param(
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Enter the subscription ID"
    )]
    [string]
    $SubscriptionID,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Enter the tenant ID"
    )]
    [string]
    $TenantID,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Enter a subscription name"
    )]
    [string]
    $SubscriptionName,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify PowerShell credential object"
    )]
    [pscredential]
    $Credential,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify whether to reauthenticate with different credentials"
    )]
    [switch]
    $ReAuthenticate,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify whether to include CSP subscriptions"
    )]
    [switch]
    $IncludeCSP,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify Partner Center Subscription Offer Name"
    )]
    [string]
    $OfferName = "Microsoft Azure"
)

Begin {
    try {

        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\Azure\Authentication\Test-AzureConnection.ps1",
            "$FunctionLocation\Toolkit\Invoke-DependencyCheck.ps1"
        )
        # Function dot source
        foreach ($Function in $Functions) {
            . $Function
        }

        # Required Module
        $Module = "AzureRM"
        $ModuleCore = "AzureRM.Netcore"

        Invoke-DependencyCheck -Modules $Module -ModulesCore $ModuleCore
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {

        # If a credential exists, make the password read only so it can be reused
        if ($Credential) {
            $Credential.Password.MakeReadOnly()
        }

        # Build custom parameters
        $CustomParameters = @{}
        if ($TenantID) {
            $CustomParameters += @{
                TenantID = $TenantID
            }
        }
        if ($SubscriptionID) {
            $CustomParameters += @{
                SubscriptionID = $SubscriptionID
            }
        }
        if ($Credential) {
            $CustomParameters += @{
                Credential = $Credential
            }
        }

        # Check for active connection to Azure RM
        if (!$ReAuthenticate) {
            $TestConnection = Test-AzureConnection -Credential $Credential
            if ($TestConnection.reauthenticate) {
                $ReAuthenticate = $true
            }
        }

        # If there is an active connection, clean up
        if ($TestConnection.ActiveConnection) {
            if ($ReAuthenticate) {
                $TestConnection.ActiveConnection = Disconnect-AzureRmAccount | Out-Null
            }
        }

        # If no active connection, connect
        if (!$TestConnection.ActiveConnection) {
            Write-Host "`nAuthenticating with Azure`n"
            $AzureConnection = Connect-AzureRMAccount @CustomParameters
            if ($AzureConnection.Account) {
                $AzureContext = Get-AzureRmContext
            }
            else {
                Write-Verbose "No Azure Subscriptions accessible to current account"
            }
        }

        # Check whether the subscription is different to current context
        if ($AzureContext.Subscription.id) {
            if ($AzureContext.Subscription.id -ne $SubscriptionID) {

                # Check for Azure Subscriptions, if none available, automatically include CSP
                $AzureRMSubscriptions = Get-AzureRmSubscription
                $AzureSubscriptions = $AzureRMSubscriptions
                if ($SubscriptionID -notcontains $AzureRMSubscriptions.SubscriptionId) {
                    Write-Verbose "No subscriptions available for active connection, including CSP subscriptions within scope"
                    $IncludeCSP = $True
                }
            }
        }

        # Connect to Partner Center
        if ($IncludeCSP) {

            # Function definitions
            $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
            $Functions = @(
                "$FunctionLocation\PartnerCenter\Authentication\Test-PartnerCenterConnection.ps1",
                "$FunctionLocation\PartnerCenter\Authentication\Connect-PartnerCenter.ps1",
                "$FunctionLocation\PartnerCenter\Customer\Get-PCCustomerSubscription.ps1"
            )

            # Function dot source
            foreach ($Function in $Functions) {
                . $Function
            }

            # Required Module
            $Module = "PartnerCenterModule,AzureAD"
            Invoke-DependencyCheck -Modules $Module

            # Check for active connection
            if (!$ReAuthenticate) {
                $TestConnection = Test-PartnerCenterConnection -Credential $Credential -ErrorAction SilentlyContinue
                if ($TestConnection.reauthenticate) {
                    $ReAuthenticate = $true
                }
            }

            # If no active connection, or reauthentication required
            if (!$TestConnection.ActiveConnection -or $ReAuthenticate) {

                # If there are no credentials
                if (!$Credential) {
                    $Credential = Get-Credential -Message "Enter Partner Center credentials"
                    $Credential.Password.MakeReadOnly()
                }
                Write-Host "`nAuthenticating with Partner Center`n"
                $PartnerCenterConnection = Connect-PartnerCenter -Credential $Credential

                if (!$PartnerCenterConnection) {
                    $ErrorMessage = "Unable to connect to Partner Center"
                    Write-Error $ErrorMessage
                }
            }
            if ($PartnerCenterConnection -or $TestConnection) {

                # Get Parter Center Azure Subscriptions
                $PCAzureSubscriptions = Get-PCCustomerSubscription -OfferName $OfferName -TenantId $TenantID
                $AzureSubscriptions += $PCAzureSubscriptions
            }
        }

        # If there are Azure Subscriptions
        if ($AzureSubscriptions) {

            # Filter to unique subscriptions
            $UniqueSubscriptions = $AzureSubscriptions | Sort-Object SubscriptionID -Unique
            $AzureSubscriptions = foreach ($Subscription in $UniqueSubscriptions) {
                $AzureSubscriptions `
                    | Where-Object {$_.subscriptionid -match $Subscription.subscriptionid} `
                    | Sort-Object Customer -Desc `
                    | Select-Object -first 1
            }

            # Filter if a subscription name is provided
            if ($SubscriptionName) {
                $AzureSubscriptions = $AzureSubscriptions | Where-Object Name -Like "*$SubscriptionName*"
                if (!$AzureSubscriptions) {
                    $ErrorMessage = "No subscriptions match $SubscriptionName"
                    Write-Error $ErrorMessage
                    throw $ErrorMessage
                }
            }

            # Filter if a subscription ID is provided
            if ($SubscriptionID) {
                $AzureSubscriptions = $AzureSubscriptions | Where-Object SubscriptionID -eq $SubscriptionId
                if (!$AzureSubscriptions) {
                    $ErrorMessage = "No subscriptions match $SubscriptionId"
                    Write-Error $ErrorMessage
                    throw $ErrorMessage
                }
            }

            # If multiple subscriptions are returned
            if ($AzureSubscriptions.count -gt 1) {

                # Display subscriptions
                Write-Host "`nSubscriptions you have access to:`n"
                $AzureSubscriptions | Sort-Object Name | Format-List Name, SubscriptionId -GroupBy Customer | Out-Host -Paging

                # Request subscription ID
                $SubscriptionID = Read-Host "Enter subscription ID"

                # While there is no valid subscription ID specified
                while ($AzureSubscriptions.subscriptionid -notcontains $SubscriptionID) {
                    $WarningMessage = "Invalid Subscription Id $SubscriptionID"
                    Write-Warning $WarningMessage
                    $SubscriptionId = Read-Host "Enter valid subscription ID"
                }
            }
            elseif (($AzureSubscriptions | Measure-Object).Count -eq 1) {
                $SubscriptionID = $AzureSubscriptions.SubscriptionId
            }
            else {
                $ErrorMessage = "No subscriptions returned."
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }

            # Filter to selected subscription
            $AzureSubscription = $AzureSubscriptions | Where-Object SubscriptionID -eq $SubscriptionId

            # Get full subscription name
            $SubscriptionName = $AzureSubscription.Name

            # Connecting to specific subscription
            Write-Host "`nConnecting to Azure Subscription: $SubscriptionName`n"

            # Build custom parameters
            $CustomParameters = @{}
            $CustomParameters += @{
                TenantID       = $AzureSubscription.tenantid
                SubscriptionID = $AzureSubscription.SubscriptionId
            }

            # If subscription is within current security context change context, else connect
            if ($AzureSubscription.SubscriptionID -contains $AzureRMSubscriptions.SubscriptionId) {
                $AzureContext = Set-AzureRmContext @CustomParameters
                if (!$AzureContext) {
                    $ErrorMessage = "Unable to connect to Azure."
                    Write-Error $ErrorMessage
                    throw $ErrorMessage
                }
            }
            else {
                if ($Credential) {
                    $CustomParameters += @{
                        Credential = $Credential
                    }
                }
                $AzureConnection = Connect-AzureRMAccount @CustomParameters
                if ($AzureConnection) {
                    $AzureContext = Get-AzureRmContext
                }
                else {
                    $ErrorMessage = "Unable to connect to Azure"
                    Write-Error $ErrorMessage
                    throw $ErrorMessage
                }
            }
        }
        else {
            $ErrorMessage = "This account does not have access to any subscriptions."
            Write-Error $ErrorMessage
            throw $ErrorMessage
        }
        return $AzureContext
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {

}