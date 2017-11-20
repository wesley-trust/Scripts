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
            
            # Check if AzureRM module is installed
            if (!(Get-Module -ListAvailable | Where-Object Name -Like "*AzureRM*")){
                
                # If not installed, install the module
                Install-Module -Name AzureRM -AllowClobber -Force
            }

            # Check to see if there is an active connection to Azure
            $AzureConnection = Get-AzureRmContext | Where-Object Name -NE "Default"

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

                    # Load subscriptions
                    $Subscriptions = Get-AzureRmSubscription

                    # If there is no subscription ID specified
                    if (!$SubscriptionID){
                                                 
                        # But there are subscriptions
                        if ($Subscriptions){
                            
                            Write-Host ""
                            Write-Host "Subscriptions you have access to:"
                            Write-Host ""

                            # List subscriptions
                            #$Subscriptions | Select-Object Name, SubscriptionId | Format-List
                            foreach ($Subscription in $Subscriptions) {
                                ($Subscription).name, ($Subscription).SubscriptionId, "`n" | Out-Host -Paging
                            }

                            # Prompt for subscription ID
                            $SubscriptionId = Read-Host "Enter subscription ID"
                        }
                        else {
                            $ErrorMessage = "Unable to list subscriptions, you may not have access to any."
                            throw $ErrorMessage
                        }
                    }

                    # Check for valid subscription ID
                    while ($Subscriptions.SubscriptionId -notcontains $SubscriptionID){
                        $SubscriptionID = Read-Host "Subscription is invalid or you do not have access, specify a new ID"
                    }

                    # Get the subscription in the current context
                    $SelectedSubscriptionID = (Get-AzureRmContext).Subscription.id

                    # If the selected subscription is not in the current context
                    if ($SelectedSubscriptionID -ne $SubscriptionID){
                        
                        # Change context to selected subscription
                        Write-Host ""
                        Write-Host "Selecting subscription"
                        $AzureConnection = Select-AzureRmSubscription -SubscriptionId $SubscriptionId
                    }
                return $AzureConnection
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