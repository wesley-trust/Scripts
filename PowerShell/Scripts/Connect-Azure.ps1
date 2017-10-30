<#
#Script name: Connect Azure
#Creator: Wesley Trust
#Date: 2017-10-30
#Revision: 1
#References: 

.Synopsis
    Function to authenticate against Azure.
.Description
    
.Example

.Example
    

#>

function Connect-Azure() {
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
            
            # Try connecting to see if a session is currently active
            $AzureConnection = Get-AzureRmContext | Where-Object Name -NE "Default"

            # If not, connect to Azure (will prompt for credentials)
            if (!$AzureConnection) {
                Add-AzureRmAccount
            }

            # Subscription info
            if (!$SubscriptionID){
            
                # List subscriptions
                Write-Host ""
                Write-Host "Loading subscriptions this account has access to:"
                Get-AzureRmSubscription | Select-Object Name, SubscriptionId | Format-List
            
                # Prompt for subscription ID
                $SubscriptionId = Read-Host "Enter subscription ID"
            }

            # Select subscription
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
