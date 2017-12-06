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
            HelpMessage="Specify PowerShell credential object"
        )]
        [pscredential]
        $Credential,
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
            $ModuleCore = "AzureRM.Netcore"

            Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Toolkit"
            . .\Check-RequiredModule.ps1

            Check-RequiredModule -Modules $Module -ModulesCore $ModuleCore

            # Check to see if there is an active connection to Azure
            $AzureConnection = Get-AzureRmContext

            # If no active account, or reauthentication is required 
            if (!$AzureConnection.Account -or $ReAuthenticate) {
                Write-Host "`nAuthenticating with Azure, enter credentials when prompted"
                # Commenting out, AzureRM.NetCore only supports device authentication at this time
<#                 if (!$Credential){
                    $Credential = Get-Credential
                }  #>
                $AzureConnection = Add-AzureRmAccount #-Credential $Credential
            }
            
            # Get the subscription in the current context
            if ($AzureConnection){
                $SelectedSubscriptionID = $AzureConnection.Subscription.id
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

                    # Check whether the subscription is different to current context
                    if ($SelectedSubscriptionID -ne $SubscriptionID){

                        # Load subscriptions
                        $Subscriptions = Get-AzureRmSubscription

                        if ($Subscriptions){
                            # While there is no subscription ID specified
                            if (!$SubscriptionID){
                                $WarningMessage = "No subscription ID is specified"
                                Write-Warning $WarningMessage
                                
                                # Display subscriptions
                                Write-Host "`nSubscriptions you have access to:"
                                $Subscriptions | Select-Object Name, Id | Format-List | Out-Host -Paging

                                # Request resource group name
                                $SubscriptionID = Read-Host "Enter subscription ID"

                                # While there is no valid subscription ID specified
                                while ($Subscriptions.id -notcontains $SubscriptionID){
                                    $WarningMessage = "Invalid Subscription Id $SubscriptionID"
                                    Write-Warning $WarningMessage
                                    $SubscriptionId = Read-Host "Enter valid subscription ID"
                                }
                            }
                            
                            # Error if subscription id specified is not valid for Azure account
                            if ($Subscriptions.id -notcontains $SubscriptionID){
                                $ErrorMessage = "Invalid Subscription Id $SubscriptionID"
                                Write-Error $ErrorMessage
                                throw $ErrorMessage
                            }
                            
                            # Change context to selected subscription
                            Write-Host "`nSelecting subscription"
                            $AzureConnection = Select-AzureRmSubscription -SubscriptionId $SubscriptionId
                        }
                        else {
                            $ErrorMessage = "This account does not have access to any subscriptions."
                            Write-Error $ErrorMessage
                            throw $ErrorMessage
                        }
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
