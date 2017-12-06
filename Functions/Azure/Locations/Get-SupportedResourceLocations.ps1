<#
#Name: Get-SupportedResourceLocations
#Creator: Wesley Trust
#Date: 2017-12-06
#Revision: 1
#References:

.Synopsis
    Functions to get supported location of AzureRM resources.
.Description

.Example
    Get-SupportedResourceLocations -SubscriptionID $SubscriptionID -ResourceProvider "Microsoft.Compute" -ResourceType "virtualMachines"
.Example
    

#>

function Get-SupportedResourceLocations() {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the subscription ID"
        )]
        [string]
        $SubscriptionID,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the resource provider"
        )]
        [string]
        $ResourceProvider,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the resource type"
        )]
        [string]
        $ResourceType
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
            # Get available resource providers
            $AvailableResourceProviders = Get-AzureRmResourceProvider
            
            # While no resource provider is specified
            while (!$ResourceProvider){
                $WarningMessage = "No resource provider is specified"
                Write-Warning $WarningMessage

                # If there are resource providers
                if ($AvailableResourceProviders){
                    
                    # Display available resource providers
                    Write-Host "`nAvailable resource providers:"
                    $AvailableResourceProviders | Select-Object ProviderNamespace | Format-Table | Out-Host -Paging

                    # Request provider name
                    $ResourceProvider = Read-Host "Enter resource provider name"
                    
                    # while an invalid name is specified
                    while ($AvailableResourceProviders.ProviderNamespace -notcontains $ResourceProvider){
                        $WarningMessage = "Invalid resource provider $ResourceProvider"
                        Write-Warning $WarningMessage
                        $ResourceProvider = Read-Host "Enter a valid resource provider name"
                    }
                }
            }

            # Check if resource provider is valid
            if ($AvailableResourceProviders.ProviderNamespace -notcontains $ResourceProvider){
                $ErrorMessage = "Invalid resource provider $ResourceProvider"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }
            
            # Get resource provider object
            $AzureRmResourceProvider = $AvailableResourceProviders | Where-Object ProviderNamespace -eq $ResourceProvider

            # Set available resource types
            $AvailableResourceTypes = $AzureRmResourceProvider.ResourceTypes

            # While no resource type is specified
            while (!$ResourceType){
                $WarningMessage = "No resource type is specified"
                Write-Warning $WarningMessage
                
                # If there are resource types
                if ($AvailableResourceTypes){

                    # Display available resource types
                    Write-Host "`nAvailable resource types:"
                    $AvailableResourceTypes | Select-Object ResourceTypeName | Format-Table | Out-Host -Paging

                    # Request resource type
                    $ResourceType = Read-Host "Enter a resource type"

                    # while an invalid name is specified
                    while ($AvailableResourceTypes.ResourceTypename -notcontains $ResourceType){
                        $WarningMessage = "Invalid resource type $ResourceType"
                        Write-Warning $WarningMessage
                        $ResourceType = Read-Host "Enter a valid resource type"
                    }
                }
            }

            # Check if resource provider is valid
            if ($AvailableResourceTypes.ResourceTypename -notcontains $ResourceType){
                $ErrorMessage = "Invalid resource type $ResourceType"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }

            # Get resource type object
            $AzureRmResourceType = $AvailableResourceTypes | Where-Object ResourceTypeName -eq $ResourceType
            
            # Get locations
            $Locations = $AzureRmResourceType.Locations
            
            # Error if no supported locations
            if (!$Locations){
                $ErrorMessage = "No supported locations for $ResourceType"
                Write-Error $ErrorMessage
                throw $ErrorMessage

            }
            else {
                Write-Host "`nAvailable locations for resource $ResourceType`n"
            }
            return $Locations
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}