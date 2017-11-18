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

function Connect-AzureSubscription() {
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
        try {
            
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    
    Process {
        try {

            # Check if AzureRM module is installed
            if (!(Get-Module -ListAvailable | Where-Object Name -Like "*AzureRM*")){
                
                # If not installed, install the module
                Install-Module -Name AzureRM -AllowClobber -Force
            }

            # Connect to Azure
            
            # Check to see if there is an active connection to Azure
            $AzureConnection = Get-AzureRmContext | Where-Object Name -NE "Default"

            # If not, connect to Azure (will prompt for credentials)
            if (!$AzureConnection) {
                Add-AzureRmAccount
            }

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
        Catch {

            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}
