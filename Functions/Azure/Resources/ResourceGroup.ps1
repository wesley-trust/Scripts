<#
#Name: Resource Group Functions
#Creator: Wesley Trust
#Date: 2017-11-20
#Revision: 3
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

            # If no resource group name is specified
            if (!$ResourceGroupName){
                $WarningMessage = "No resource group name is specified"
                Write-Warning $WarningMessage
                
                # Display resource groups
                Write-Host "`nExisting Resource Group names:"
                $ResourceGroups | Select-Object ResourceGroupName | Format-Table | Out-Host -Paging
                
                # Request resource group name
                $ResourceGroupName = Read-Host "Specify existing resource group name"
                
                # While no valid resource group name is specified
                while ($ResourceGroups.ResourceGroupName -notcontains $ResourceGroupName){
                    $WarningMessage = "Invalid Resource group name $ResourceGroupName"
                    Write-Warning $WarningMessage
                    
                    # Request resource group name
                    $ResourceGroupName = Read-Host "Specify valid resource group name"
                }
            }

            # If there is a resource group name
            if ($ResourceGroupName){
                # Check if resource group name is invalid
                if ($ResourceGroups.ResourceGroupName -notcontains $ResourceGroupName){
                    $ErrorMessage = "Invalid Resource group name $ResourceGroupName"
                    Write-Error $ErrorMessage
                }
                else {
                    # Select resource group object
                    $ResourceGroup = Get-AzureRmResourceGroup -ResourceGroupName $ResourceGroupName
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
            if (!$ResourceGroupName){
                $WarningMessage = "No resource group name is specified"
                Write-Warning $WarningMessage
                $ResourceGroupName = Read-Host "Enter resource group name"
                
                # If an invalid name is specified
                if ($ResourceGroups.ResourceGroupName -contains $ResourceGroupName){
                    $WarningMessage = "Exisiting Resource group with name $ResourceGroupName"
                    Write-Warning $WarningMessage
                    
                    # Display exisiting resource groups
                    Write-Host "`nExisting Resource Group names:"
                    $ResourceGroups | Select-Object ResourceGroupName | Format-Table | Out-Host -Paging
                }
                
                # while an invalid name is specified
                while ($ResourceGroups.ResourceGroupName -contains $ResourceGroupName){
                    $ResourceGroupName = Read-Host "Enter a unique resource group name"
                }
            }

            # Check if resource group name conflict
            if ($ResourceGroups.ResourceGroupName -contains $ResourceGroupName){
                $ErrorMessage = "Exisiting Resource group with name $ResourceGroupName"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }
            else {
                # Get Azure regions
                $Locations = Get-AzureRmLocation

                # If no location is set
                if (!$Location){
                    $WarningMessage = "No location is specified"
                    Write-Warning $WarningMessage
                    
                    # Get Azure region locations
                    Write-Host "`nSupported Locations:"
                    $Locations | Select-Object Location | Format-Table | Out-Host -Paging
                    
                    # Prompt for location
                    $Location = Read-Host "Enter a location for this resource group"

                    # Check for valid location
                    while ($Locations.location -notcontains $Location){
                        $WarningMessage = "Invalid location $Location"
                        Write-Warning $WarningMessage
                        $Location = Read-Host "Specify a valid location."
                    }
                }

                # Check for valid location
                if ($Locations.location -notcontains $Location){
                    $ErrorMessage = "Invalid location $Location"
                    Write-Error $ErrorMessage
                    throw $ErrorMessage
                }
                else {
                    # Create Resource Group
                    $ResourceGroup = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
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