<#
#Script name: New Azure DNS Zone
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision: 3
#References:

.Synopsis
    Function to get a Azure DNS Zone in a subscription.
.Description

.Example

.Example
    

#>

function Get-AzureDNSZone() {
    #Parameters
    Param(
        [Parameter(
            Mandatory=$true,
            HelpMessage="Enter the DNS Zone"
        )]
        [string]
        $DNSZone,
        
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the location for the DNS Zone resource group"
        )]
        [string]
        $SubscriptionID
    )

    Begin {
        
        #Check if AzureRM module is installed
        if (!(Get-Module -ListAvailable | Where-Object Name -Like "*AzureRM*")){
            
            #If not installed, install the module
            Install-Module -Name AzureRM -AllowClobber -Force
        }

        #Connect to Azure
        
        #Try connecting to see if a session is currently active
        $AzureConnection = Get-AzureRmContext | Where-Object Name -NE "Default"

        #If not, connect to Azure
        if (!$AzureConnection) {
            Add-AzureRmAccount
        }

        #Subscription info
        if (!$SubscriptionID){
        
            #List subscriptions
            Write-Host ""
            Write-Host "Loading subscriptions this account has access to:"
            Get-AzureRmSubscription | Select-Object Name,SubscriptionId | Format-List
        
            #Prompt for subscription ID
            $SubscriptionId = Read-Host "Enter subscription ID"
        }

        #Select subscription
        Select-AzureRmSubscription -SubscriptionId $SubscriptionId
    }
    
    Process {
        try {
            #Try to get DNS Zone
            $DNSZoneObject = Get-AzureRmResourceGroup | Where-Object ResourceID -EQ $DNSZone | Get-AzureRmDnsZone

            # If this doesn't exist, display message
            if (!$DNSZoneObject){
                Write-Host "Azure DNS Zone does not exist"
            }
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
        return $DNSZoneObject
    }
    End {
        
    }
}
