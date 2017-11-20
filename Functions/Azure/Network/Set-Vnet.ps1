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
            # If no Vnet name is specified
            if (!$VNetName){
               
                # Get all Vnets
                $Vnet = Get-AzureRmVirtualNetwork -ErrorAction SilentlyContinue
            }

            # If there are no Vnet objects
            if (!$Vnet){
                
                # Set resource group
                Set-Location $ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Resources\
                . .\Set-ResourceGroup.ps1

                $ResourceGroup = Set-ResourceGroup `
                    -SubscriptionID $SubscriptionID `
                    -ResourceGroupName $ResourceGroupName `
                    -Location $Location #`
                    #| Tee-Object -Variable ResourceGroup
                
                $ResourceGroup = $ResourceGroup | Where-Object {$_ -is [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroup]}

                # Update variables from resource group object
                $Location = $ResourceGroup.Location
                $ResourceGroupName = $ResourceGroup.ResourceGroupName
                
                if (!$VNetName){
                    
                    # Request optional vnet variable
                    $VNetName = Read-Host "Enter an existing vnet name within the resource group, a new name will create a new vnet"
                    
                    # Get Vnet object
                    $Vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
                }
                if (!$Vnet) {
                    
                    # Request subnet optional variables
                    if (!$SubnetName){
                        $SubnetName = Read-Host "Please enter Subnet name"
                    }
                    if (!$VNetSubnetAddressPrefix){
                        $VNetSubnetAddressPrefix = Read-Host "Please enter Subnet address prefix"
                    }
                    
                    # Create virtual network config
                    $SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $VNetSubnetAddressPrefix
                    
                    # Request vnet address optional variable
                    if (!$VNetAddressPrefix){
                        $VNetAddressPrefix = Read-Host "Please enter the vnet address prefix"
                    }
                    # Create virtual network
                    $VNet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
                }
            }

            # Else if there is more than 1 vnet
            Elseif ($VNet.count -ne "1") {
                
                # Display vnet names
                Write-Host ""
                Write-Host "Virtual Network Names:"
                Write-Host ""
                ($Vnet).name, "`n" | Out-Host -Paging

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
