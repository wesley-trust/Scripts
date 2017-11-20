<#
#Script name: Set Resource
#Creator: Wesley Trust
#Date: 2017-11-18
#Revision: 1
#References:

.Synopsis
    Function to set resource and group.
.Description

.Example

.Example
    

#>

function Set-ResourceGroup() {
    #Parameters
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
                #Get-AzureRmResourceGroup | Select-Object ResourceGroupName | More
                Write-Host "`n Resource Group Names:"
                $ResourceGroups = Get-AzureRmResourceGroup
                Write-Host ""
                ($ResourceGroups).ResourceGroupName | Out-Host -Paging
                Write-Host ""
                $ResourceGroupName = Read-Host "Enter an existing resource group name, a new name will create a new group"
            }
                
            # Check if the resource group exists
            $ResourceGroup = Get-AzureRmResourceGroup -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

            #If the resource group does not exist
            if (!$ResourceGroup){
                
                # Get Azure regions
                $Locations = Get-AzureRmLocation

                # And no location is set
                if (!$Location){
                    
                    # Get Azure region locations
                    #$Locations | Select-Object Location | Format-Table | more
                    Write-Host "Supported Regions:"
                    Write-Host ""
                    ($Locations).Location | Out-Host -Paging
                    Write-Host ""
                    
                    # Prompt for location
                    $Location = Read-Host "Enter the location for this resource"
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
