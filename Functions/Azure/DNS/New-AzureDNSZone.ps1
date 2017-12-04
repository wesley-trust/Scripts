<#
#Script name: New Azure DNS Zone
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision: 3
#References:

.Synopsis
    Function to create a new Azure DNS Zone in a subscription in a specific location.
.Description

.Example

.Example
    

#>

function New-AzureDNSZone() {
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
        $Location,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the subscription ID"
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
            Connect-AzureRM -SubscriptionID $SubscriptionID

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
            
            # If no location for the zone is specified
            if (!$Location){
                
                # Get available locations
                Get-AzureRmLocation | Select-Object Location
                
                # Prompt for location
                $Location = Read-Host "Enter resource location (recommended: uksouth)"
            }
            # Create resource group
            $ResourceGroupName = $DNSZone
            New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction Stop

            # Create DNZ Zone
            New-AzureRmDnsZone -Name $DNSZone -ResourceGroupName $ResourceGroupName
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}
