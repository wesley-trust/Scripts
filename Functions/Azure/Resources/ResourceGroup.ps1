<#
#Name: Resource Group Functions
#Creator: Wesley Trust
#Date: 2017-11-20
#Revision: 1
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
            $AzureConnection = Connect-AzureRM -SubscriptionID $SubscriptionID #`
            #| Tee-Object -Variable AzureConnection

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
                Write-Host "`n Resource Group Names:"
                $ResourceGroups = Get-AzureRmResourceGroup
                "`n",($ResourceGroups).ResourceGroupName,"`n" | Out-Host -Paging
                
                # While no resource group name is provided
                while (!$ResourceGroupName){
                    $ResourceGroupName = Read-Host "Enter resource group name"
                }
            }
                
            # Check if the resource group exists
            $ResourceGroup = Get-AzureRmResourceGroup -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

            # If the resource group does not exist
            if (!$ResourceGroup){
                $Choice = $null
                while ($choice -notmatch "Y|N") {
                    $Choice = Read-Host "Resource group does not exist, do you want to create this group? (Y/N)"
                }
                if ($choice -eq "Y"){
                    # Create resource group
                    $ResourceGroup = New-ResourceGroup -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -Location $Location
                }
                else {
                    $ErrorMessage = "Resource group does not exist, user aborted creation of new group"
                    Write-Error -Message $ErrorMessage
                    throw $ErrorMessage
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
            $AzureConnection = Connect-AzureRM -SubscriptionID $SubscriptionID #`
            #| Tee-Object -Variable AzureConnection

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
            # While no resource group name is provided
            while (!$ResourceGroupName){
                $ResourceGroupName = Read-Host "Enter resource group name"
            }

            # Check if the resource group exists
            $ResourceGroup = Get-AzureRmResourceGroup -ResourceGroupName $ResourceGroupName

            #If the resource group does not exist
            if (!$ResourceGroup){
                
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
                }

                # Create Resource Group
                $ResourceGroup = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
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