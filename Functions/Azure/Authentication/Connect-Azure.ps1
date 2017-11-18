<#
#Script name: Connect Azure Subscription
#Creator: Wesley Trust
#Date: 2017-10-30
#Revision: 2
#References: 

.Synopsis
    Function that connects to an Azure subscription.
.Description
    Function that connects to an Azure subscription, firstly by checking if the AzureRM module is installed,
    if not, installs this, then checks if there is an active connection to Azure, if not, connects to Azure,
    if a subscription ID is specified, selects that subscription, if not, loads subscriptions,
    prompts for subscription ID, and selects that subscription.
.Example

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
        $SubscriptionID
    )

    Begin {
        # Try Azure Automation Authentication
        try {
            # Connection Variable
            $connectionName = "AzureRunAsConnection"
            
            # Get the service principal of the connection
            $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName

            if ($ServicePrincipalConnection){
                Write-Host "Authenticating with Azure"
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
        
        # Catch when not run in Azure Automation
        catch [System.Management.Automation.CommandNotFoundException] {
            
            # Check if AzureRM module is installed
            if (!(Get-Module -ListAvailable | Where-Object Name -Like "*AzureRM*")){
                
                # If not installed, install the module
                Install-Module -Name AzureRM -AllowClobber -Force
            }

            # Check to see if there is an active connection to Azure
            $AzureConnection = Get-AzureRmContext | Where-Object Name -NE "Default"

            # If not, connect to Azure (will prompt for credentials)
            if (!$AzureConnection) {
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
                
                # If there is a connection to Azure
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
        
                    # Select subscription
                    Write-Host ""
                    Write-Host "Selecting subscription"
                    Select-AzureRmSubscription -SubscriptionId $SubscriptionId
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
