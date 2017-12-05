<#
#Name: Virtual Network functions
#Creator: Wesley Trust
#Date: 2017-11-21
#Revision: 1
#References:

.Synopsis
    Functions to get, or create a new vnet in Azure
.Description

.Example

.Example
    

#>


function Get-Vnet() {
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
            HelpMessage="Enter the virtual network name"
        )]
        [string]
        $VNetName
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
            # If a resource group is specified
            if ($ResourceGroupName){
                # And a virtual network name is
                if ($VNetName){
                    # Get virtual network name inside resource group
                    $Vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
                }
                else {
                    # Get all virtual networks inside resource group
                    $Vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName
                }
            }
            else {
                # Get all virtual networks within subscription
                $Vnet = Get-AzureRmVirtualNetwork
            }

            # if there is more than 1 vnet
            if ($VNet.count -ne "1") {
                
                # Display vnet names
                Write-Host "`nVirtual Network Names:`n"
                $Vnet | Select-Object Name | Out-Host -Paging

                # Clear variable
                $VNetName = $null

                # While no vnet name is specified
                while (!$VnetName) {
                    
                    # Continue to prompt for vnet name
                    $VnetName = Read-Host "Specify virtual network name to use"
                }

                while ($Vnet.name -notcontains $VNetName){
                    $WarningMessage = "Virtual network is invalid or not available"
                    Write-Warning $WarningMessage
                    $VNetName = Read-Host "Specify a new virtual network name"
                }

                # Set vnet variable to include only the specified vnet object
                $Vnet = $Vnet | Where-Object Name -eq $VNetName
                
                # If there is no vnet object
                if (!$vnet){
                    $ErrorMessage = "No valid virtual network specified."
                    Write-Error $ErrorMessage
                    throw $ErrorMessage
                }
            }
            return $Vnet
        }
        Catch {

            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}

function New-Vnet() {
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
    }
    
    Process {
        try {
            # While no virtual network name is provided
            while (!$VNetName){
                $VNetName = Read-Host "Enter Virtual Network name"
            }
            
            # Get resource group
            Set-Location $ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Resources\
            . .\ResourceGroup.ps1

            $ResourceGroup = Get-ResourceGroup `
                -SubscriptionID $SubscriptionID `
                -ResourceGroupName $ResourceGroupName `
                -Location $Location
            
            $ResourceGroup = $ResourceGroup | Where-Object {$_ -is [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroup]}

            # Update variables from resource group object
            $Location = $ResourceGroup.Location
            $ResourceGroupName = $ResourceGroup.ResourceGroupName

            # Check if Virtual Network already exists
            $Vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

            # If there are no Vnet objects
            if (!$Vnet){
                
                # Request subnet optional variables
                while (!$SubnetName){
                    $SubnetName = Read-Host "Please enter Subnet name"
                }
                while (!$VNetSubnetAddressPrefix){
                    $VNetSubnetAddressPrefix = Read-Host "Please enter Subnet address prefix"
                }
                
                # Create virtual network config
                $SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $VNetSubnetAddressPrefix
                
                # Request vnet address optional variable
                while (!$VNetAddressPrefix){
                    $VNetAddressPrefix = Read-Host "Please enter the vnet address prefix"
                }
                # Create virtual network
                $VNet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
            }
            else {
                $ErrorMessage = "Virtual network name already exists in the resource group."
                Write-Error -Message $ErrorMessage
                throw $ErrorMessage
            }
            return $Vnet
        }
        Catch {

            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}