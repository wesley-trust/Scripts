<#
#Script name: Connect Azure Subscription
#Creator: Wesley Trust
#Date: 2017-10-30
#Revision: 2
#References: 

.Synopsis
    Function that connects to an Azure subscription via Azure Automation or user Authentication.
.Description
    Function that connects to an Azure subscription, firstly by checking whether it is in Azure Automation,
    if not, checks if the AzureRM module is installed, if not, installs the module.
    Then checks if there is an active connection, or whether different credentials are required, connects to Azure.
    If it is not in Azure Automation, and there is an active connection, checks if a subscription ID is specified,
    if not, loads subscriptions, prompts for subscription ID, finally selects subscription if not already selected.
.Example
    Connect-AzureRM -SubscriptionID $SubscriptionID -ReAuthenticate $true 
.Example
    

#>

function Connect-AzureRM() {
    #Parameters
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the subscription ID"
        )]
        [string]
        $SubscriptionID,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether to reauthenticate with different credentials"
        )]
        [bool]
        $ReAuthenticate = $false
    )

    Begin {
        # Try Azure Automation Authentication
        try {
            # Connection Variable
            $connectionName = "AzureRunAsConnection"
            
            # Get the service principal of the connection
            $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName

            # If there is a service principal
            if ($ServicePrincipalConnection){
                "Authenticating with Azure Automation"
                Add-AzureRmAccount `
                    -ServicePrincipal `
                    -TenantId $servicePrincipalConnection.TenantId `
                    -ApplicationId $servicePrincipalConnection.ApplicationId `
                    -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
            }
            else {
                $ErrorMessage = "Connection $ConnectionName not found."
                throw $ErrorMessage
            }
        }
        
        # Catch when Azure Automation command is not found
        catch [System.Management.Automation.CommandNotFoundException] {
            
            # Required Module
            $Module = "AzureRM"

            Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Toolkit"
            . .\Check-RequiredModule.ps1

            Check-RequiredModule -Modules $Module

            # Check to see if there is an active connection to Azure
            $AzureConnection = Get-AzureRmContext | Where-Object Name -NE "Default"
            
            if ($AzureConnection){
                # Get the subscription in the current context
                $SelectedSubscriptionID = $AzureConnection.Subscription.id
            }

            # If no active connection, or reauthentication is required 
            if (!$AzureConnection -or $ReAuthenticate) {
                Write-Host ""
                Write-Host "Authenticating with Azure, enter credentials when prompted"
                $AzureConnection = Add-AzureRmAccount
            }
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    
    Process {
        try {
            # If there is no Azure Automation Service Principal
            if (!$ServicePrincipalConnection){
                
                # But there is a connection to Azure
                if ($AzureConnection){

                    # Check whether the subscription is different
                    if ($SelectedSubscriptionID -ne $SubscriptionID){

                        # Load subscriptions
                        $Subscriptions = Get-AzureRmSubscription

                        # If there is no subscription ID specified
                        if (!$SubscriptionID){
                                                    
                            # But there are subscriptions
                            if ($Subscriptions){
                                Write-Host "`nSubscriptions you have access to:"
                                $Subscriptions | Select-Object Name, SubscriptionId | Format-List | Out-Host -Paging

                                # Prompt for subscription ID
                                while (!$SubscriptionId) {
                                    $SubscriptionId = Read-Host "Enter subscription ID"
                                }
                            }
                            else {
                                $ErrorMessage = "This account does not have access to any subscriptions."
                                Write-Error $ErrorMessage
                                throw $ErrorMessage
                            }
                        }
                        
                        # Warn if subscription id is not valid for Azure account
                        while ($Subscriptions.id -notcontains $SubscriptionID){
                            $WarningMessage = "Invalid Subscription Id: $SubscriptionID"
                            Write-Warning $WarningMessage
                            Write-Host "If ID is correct, try reauthenticating with a different account"
                            
                            # Display valid IDs
                            Write-Host "`nValid subscriptions available:"
                            $Subscriptions | Select-Object Name, SubscriptionId | Format-List | Out-Host -Paging
                            $SubscriptionId = Read-Host "Enter a valid subscription ID"
                        }
                        
                        # Change context to selected subscription
                        Write-Host "`nSelecting subscription"
                        $AzureConnection = Select-AzureRmSubscription -SubscriptionId $SubscriptionId
                    }
                    return $AzureConnection
                }
                else {
                    $ErrorMessage = "No active Azure connection."
                    Write-Error $ErrorMessage
                    throw $ErrorMessage
                }
            }
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}
