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
        try {
            # Connect to Azure
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
                -Location $Location #`
                #| Tee-Object -Variable ResourceGroup
            
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