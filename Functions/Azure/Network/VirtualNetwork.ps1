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
        $VNetName,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter Azure credentials"
        )]
        [pscredential]
        $Credential,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether to assume correct vnet, when only one exists"
        )]
        [bool]
        $AssumeDefaultVnet
    )

    Begin {
        try {
            # Load functions
            Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Authentication\"
            . .\Connect-AzureRM.ps1
            
            # Connect to Azure
            $AzureConnection = Connect-AzureRM -SubscriptionID $SubscriptionID -Credential $credential

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
                    if (!$Vnet){
                        $ErrorMessage = "No Virtual Network: $VnetName in Resource Group: $ResourceGroupName"
                        Write-Error $ErrorMessage
                    }
                }
                else {
                    # Get all virtual networks inside resource group
                    $Vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName
                    if (!$Vnet){
                        $ErrorMessage = "No Virtual Network in Resource Group: $ResourceGroupName"
                        Write-Error $ErrorMessage
                    }
                }
            }
            else {
                # Get all virtual networks within subscription
                $Vnet = Get-AzureRmVirtualNetwork
            }

            # If there is a vnet
            if ($Vnet){
                # But there is more than one
                if ($VNet.count -ne "1"){
                    # If assume virtual network is false
                    if (!$AssumeDefaultVnet){
                    
                        # Display vnet names
                        Write-Host "`nExisiting Virtual Network Names:`n"
                        $Vnet | Select-Object Name | Out-Host -Paging

                        # Clear variable
                        $VNetName = $null

                        # If no vnet name is specified
                        while (!$VnetName) {
                            $WarningMessage = "No Virtual Network name is specified"
                            Write-Warning $WarningMessage

                            # Display valid virtual networks
                            Write-Host "`nExisiting Virtual Network Names:"
                            $Vnet | Select-Object Name | Out-Host -Paging
                            
                            # Request virtual network name
                            $VnetName = Read-Host "Specify existing virtual network name"
                            
                            # Check for valid name
                            while ($Vnet.name -notcontains $VNetName){
                                $WarningMessage = "Invalid Virtual network name $VNetName"
                                Write-Warning $WarningMessage
                                                                
                                $VNetName = Read-Host "Specify valid virtual network name"
                            }
                        }

                        # Set vnet variable to include only the specified virtual network name
                        $Vnet = $Vnet | Where-Object Name -eq $VNetName

                    }
                    else {
                        $ErrorMessage = "Unable to assume which virtual network to use as there is more than one."
                        Write-Error $ErrorMessage
                        throw $ErrorMessage
                    }
                }
                return $Vnet
            }
            else {
                # If there is no vnet object
                $ErrorMessage = "No virtual networks accessible in this subscription."
                Write-Error $ErrorMessage
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
                $WarningMessage = "No virtual network name is specified"
                Write-Warning $WarningMessage
                $VNetName = Read-Host "Enter Virtual Network name"
            }
            
            # Get resource group
            Set-Location $ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Resources\
            . .\ResourceGroup.ps1

            $ResourceGroup = Get-ResourceGroup `
                -SubscriptionID $SubscriptionID `
                -ResourceGroupName $ResourceGroupName `
                -Location $Location
            
            # Return specific object check
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
                    $WarningMessage = "No subnet name is specified"
                    Write-Warning $WarningMessage
                    $SubnetName = Read-Host "Please enter Subnet name"
                }
                while (!$VNetSubnetAddressPrefix){
                    $WarningMessage = "No subnet address prefix is specified"
                    Write-Warning $WarningMessage
                    $VNetSubnetAddressPrefix = Read-Host "Please enter Subnet address prefix"
                }
                
                # Create virtual network config
                $SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $VNetSubnetAddressPrefix
                
                # Request vnet address optional variable
                while (!$VNetAddressPrefix){
                    $WarningMessage = "No virtual network address prefix is specified"
                    Write-Warning $WarningMessage
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