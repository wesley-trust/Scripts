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
    Then checks if there is an active connection to Azure, or whether credentials are required, connects to Azure.
    If it is not in Azure Automation, and there is an active connection, checks if a subscription ID is specified,
    if not, loads subscriptions, prompts for subscription ID, and finally selects subscription.
.Example
    Connect-AzureRM -SubscriptionID $SubscriptionID -DifferentCredentials $true 
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
            HelpMessage="Specify whether to reauthentcate with different credentials"
        )]
        [bool]
        $DifferentCredentials = $false
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
            
            # Check if AzureRM module is installed
            if (!(Get-Module -ListAvailable | Where-Object Name -Like "*AzureRM*")){
                
                # If not installed, install the module
                Install-Module -Name AzureRM -AllowClobber -Force
            }

            # Check to see if there is an active connection to Azure
            $AzureConnection = Get-AzureRmContext | Where-Object Name -NE "Default"

            # If no active connection, or different credentials are required 
            if (!$AzureConnection -or $DifferentCredentials) {
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

                    # If there is no subscription ID specified
                    if (!$SubscriptionID){
                        
                        # List subscriptions
                        Write-Host ""
                        Write-Host "Loading subscriptions this account has access to:"
                        Get-AzureRmSubscription | Select-Object Name, SubscriptionId | Format-List
                    
                        # Prompt for subscription ID
                        $SubscriptionId = Read-Host "Enter subscription ID"
                    }

                    # Get the subscription in the current context
                    $SelectedSubscriptionID = (Get-AzureRmContext).Subscription.id

                    # If the selected subscription is not in the current context
                    if ($SelectedSubscriptionID -ne $SubscriptionID){
                        
                        # Change context to selected subscription
                        Write-Host ""
                        Write-Host "Selecting subscription"
                        Select-AzureRmSubscription -SubscriptionId $SubscriptionId
                    }
                }
                else {
                    $ErrorMessage = "No active Azure connection."
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
