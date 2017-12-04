<#
#Name: Resource Group Functions
#Creator: Wesley Trust
#Date: 2017-11-20
#Revision: 2
#References:

.Synopsis
    Functions to get, or create new resource group.
.Description

.Example

.Example
    

#>

function Get-ResourceGroup() {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the subscription ID"
        )]
        [string]
        $SubscriptionID,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the resource group name"
        )]
        [string]
        $ResourceGroupName,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the Azure region location"
        )]
        [string]
        $Location
    )

    Begin {
        try {
            # Include functions
            Set-Location $ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Authentication\
            . .\Connect-AzureRM.ps1
            
            # Authenticate with Azure
            $AzureConnection = Connect-AzureRM -SubscriptionID $SubscriptionID

            # Update subscription Id from Azure Connection
            $SubscriptionID = $AzureConnection.Subscription.id

        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    
    Process {
        try {
            # If the resource group name parameter is not set
            if (!$ResourceGroupName){

                # Get all resource groups
                Write-Host "`nExisting Resource Group names:"
                $ResourceGroups = Get-AzureRmResourceGroup
                "`n",($ResourceGroups).ResourceGroupName,"`n" | Out-Host -Paging
                
                # While no exisiting resource group name is provided
                while ($ResourceGroupName -notcontains $ResourceGroups.ResourceGroupName){
                    $ResourceGroupName = Read-Host "Enter existing or new resource group name"
                }
            }
            return $ResourceGroup
        }
        Catch {

            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}
function New-ResourceGroup() {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the subscription ID"
        )]
        [string]
        $SubscriptionID,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the resource group name"
        )]
        [string]
        $ResourceGroupName,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the Azure region location"
        )]
        [string]
        $Location
    )

    Begin {
        try {
            # Include functions
            Set-Location $ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Authentication\
            . .\Connect-AzureRM.ps1
            
            # Authenticate with Azure
            $AzureConnection = Connect-AzureRM -SubscriptionID $SubscriptionID

            # Update subscription Id from Azure Connection
            $SubscriptionID = $AzureConnection.Subscription.id

        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    
    Process {
        try {
            # Get all resource groups
            $ResourceGroups = Get-AzureRmResourceGroup

            # While no resource group name is provided
            while (!$ResourceGroupName){
                $ResourceGroupName = Read-Host "Enter resource group name"
                while ($ResourceGroups.ResourceGroupName -contains $ResourceGroupName){
                    $ResourceGroupName = Read-Host "Resource group name already exists, enter a different name"
                }
            }
            
            # Get Azure regions
            $Locations = Get-AzureRmLocation

            # If no location is set
            if (!$Location){
                
                # Get Azure region locations
                Write-Host "Supported Regions:"
                "`n",($Locations).Location,"`n" | Out-Host -Paging
                
                # Prompt for location
                $Location = Read-Host "Enter the location for this resource group"
            }

            # Check for valid location
            while ($Locations.location -notcontains $Location){
                $Location = Read-Host "Location is invalid or not available, specify a new location."
                while (!$Location){
                    $Location = Read-Host "Enter the location for this resource group"
                }
            }

            # Create Resource Group
            $ResourceGroup = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location

            return $ResourceGroup
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}