<#
#Script name: Set Vnet
#Creator: Wesley Trust
#Date: 2017-10-30
#Revision: 1
#References: Vnet now split out in to separate function from New-VM function.

.Synopsis
    Function to get, or create a new vnet in Azure
.Description
    Function to get, or create a new vnet in Azure
.Example

.Example
    

#>

function Set-Vnet() {
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
        $Location,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the subnet name"
        )]
        [string]
        $SubnetName = "default",

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the virtual network name"
        )]
        [string]
        $VNetName,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the virtual network address prefix"
        )]
        [string]
        $VNetAddressPrefix,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the virtual network subnet address prefix"
        )]
        [string]
        $VNetSubnetAddressPrefix

    )

    Begin {
        try {
            # Include functions
            Set-Location $ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Authentication\
            . .\Connect-AzureRM.ps1
            
            # Authenticate with Azure
            if ($SubscriptionID){
                Connect-AzureRM -SubscriptionID $SubscriptionID
            }
            else {
                Connect-AzureRM
            }
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
                Get-AzureRmResourceGroup | Select-Object ResourceGroupName | More
                $ResourceGroupName = Read-Host "Enter the name of an exisiting or new resource group"
            }
                
            # Check if the resource group exists
            $ResourceGroup = Get-AzureRmResourceGroup -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

            # Get Azure regions
            $Locations = Get-AzureRmLocation

            #If the resource group does not exist
            if (!$ResourceGroup){
                
                # And no location is set
                if (!$Location){
                    
                    # Get Azure region locations
                    $Locations | Select-Object Location | Format-Table | more
                    
                    # Prompt for location
                    $Location = Read-Host "Enter the location for this VM"
                }

                # Check for valid location
                while ($Locations.location -notcontains $Location){
                    $Location = Read-Host "Location is invalid or not available, specify a new location."
                }

                # Create Resource Group
                New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
            }
            Else {
                # Set location from resource group
                $Location = $ResourceGroup.Location
            }
            
            # If a Vnet name is specified
            if ($VNetName){
                # Get Vnet object
                $Vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
            }
            Else {
                # Get all Vnets
                $Vnet = Get-AzureRmVirtualNetwork -ErrorAction SilentlyContinue
            }
          
            # If there are no Vnet objects
            if (!$Vnet){
               
                # Create virtual network config
                $SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $VNetSubnetAddressPrefix
                
                # Create virtual network
                $VNet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
            }
            
            # Else if there is more than 1 vnet
            Elseif ($VNet.count -ne "1") {
                
                # Display vnet names
                $Vnet | Select-Object Name

                # Clear variable
                $VNetName = $null

                # While no vnet name is specified
                while (!$VnetName) {
                    
                    # Continue to prompt for vnet name
                    $VnetName = Read-Host "Specify VNet name to use"
                }

                while ($Vnet.name -notcontains $VNetName){
                    $VNetName = Read-Host "Virtual network is invalid or not available, specify a new virtual network."
                }

                # Set vnet variable to include only the specified vnet object
                $Vnet = $Vnet | Where-Object Name -eq $VNetName
                
                # If there is no vnet object
                if (!$vnet){
                    throw "No valid virtual network specified."
                }
            }
            Else {
                # Display vnet to be used
                return $Vnet
            }
        }
        Catch {

            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}
