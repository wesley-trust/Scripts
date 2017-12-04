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
        try {
            # Load functions
            Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Authentication\"
            . .\Connect-AzureRM.ps1
            
            # Connect to Azure
            $AzureConnection = Connect-AzureRM -SubscriptionID $SubscriptionID

            # Update subscription Id from Azure Connection
            $SubscriptionID = $AzureConnection.Subscription.id
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
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
