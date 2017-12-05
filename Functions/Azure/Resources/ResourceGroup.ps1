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
            # Get all resource groups
            $ResourceGroups = Get-AzureRmResourceGroup

            # If the resource group name parameter is not set
            if (!$ResourceGroupName){
                $WarningMessage = "No resource group name is specified"
                Write-Warning $WarningMessage

                # Get all resource groups
                Write-Host "`nExisting Resource Group names:"
                $ResourceGroups | Select-Object ResourceGroupName | Format-Table | Out-Host -Paging
                
                # Request resource group name
                $ResourceGroupName = Read-Host "If this is not correct, specify existing resource group name"
            }
            
            # If no valid resource group name is provided
            if ($ResourceGroups.ResourceGroupName -notcontains $ResourceGroupName){
                $WarningMessage = "Existing Resource Group name is invalid or not specified"
                Write-Warning $WarningMessage
                
                # Display valid resource groups
                Write-Host "`nValid Resource Group names:"
                $ResourceGroups | Select-Object ResourceGroupName | Format-Table | Out-Host -Paging
                $ResourceGroupName = Read-Host "If this is not correct, specify existing resource group name"
            }
            
            # If there is now a resource group name
            if ($ResourceGroupName){
                # Select resource group object
                $ResourceGroup = Get-AzureRmResourceGroup -ResourceGroupName $ResourceGroupName
            }

            # If no object exists
            if (!$ResourceGroup){
                $ErrorMessage = "No resource group specified."
                Write-Error $ErrorMessage
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
                Write-Host "`nCreating new resource group`n"
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
                Write-Host "`nSupported Regions:"
                $Locations | Select-Object Location | Format-Table | Out-Host -Paging
                
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