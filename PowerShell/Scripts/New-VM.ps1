<#
#Script name: New VM
#Creator: Wesley Trust
#Date: 2017-10-19
#Revision: 1
#References: https://docs.microsoft.com/en-us/powershell/module/azurerm.compute/new-azurermvm?view=azurermps-4.2.0

.Synopsis
    Function to create a new VM in Azure
.Description
    Function to create a new VM in Azure, based on Microsoft documentation, see references for more info.
.Example

.Example
    

#>

function New-VM() {
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
            HelpMessage="Enter the server interface name"
        )]
        [string]
        $InterfaceName = "ServerInterface01",
        
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the publisher name"
        )]
        [string]
        $PublisherName = "MicrosoftWindowsServer",

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the Azure offer"
        )]
        [string]
        $Offer = "WindowsServer",

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the SKU"
        )]
        [string]
        $SKU = "2012-R2-Datacenter",

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter whether to use latest version"
        )]
        [string]
        $Latest = "latest",

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the Azure region location"
        )]
        [string]
        $Location,

        [Parameter(
            Mandatory=$true,
            HelpMessage="Enter the VM name"
        )]
        [string]
        $VMName,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the computer name (default to VM Name)"
        )]
        [string]
        $Computername = $VMName,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the VM size"
        )]
        [string]
        $VMSize,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the OS disk name"
        )]
        [string]
        $OSDiskName = $VMName + "OSDisk",

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the OS disk name"
        )]
        [string]
        $SubnetName = "default"
    )

    Begin {
        
        # Check if AzureRM module is installed
        if (!(Get-Module -ListAvailable | Where-Object Name -Like "*AzureRM*")){
            
            # If not installed, install the module
            Install-Module -Name AzureRM -AllowClobber -Force
        }

        # Connect to Azure
        
        # Try connecting to see if a session is currently active
        $AzureConnection = Get-AzureRmContext | Where-Object Name -NE "Default"

        # If not, connect to Azure
        if (!$AzureConnection) {
            Add-AzureRmAccount
        }

        # Subscription info
        if (!$SubscriptionID){
        
            # List subscriptions
            Write-Host ""
            Write-Host "Loading subscriptions this account has access to:"
            Get-AzureRmSubscription | Select-Object Name,SubscriptionId | Format-List
        
            # Prompt for subscription ID
            $SubscriptionId = Read-Host "Enter subscription ID"
        }

        # Select subscription
        Select-AzureRmSubscription -SubscriptionId $SubscriptionId
    }
    
    Process {
        try {

            # Prompt for credentials for VM
            Write-Output "Enter VM Credentials"
            $VMCredential = Get-Credential

            # If the resource group name parameter is not set
            if (!$ResourceGroupName){

                # Get all resource groups
                Get-AzureRmResourceGroup | Select-Object ResourceGroupName | More
                $ResourceGroupName = Read-Host "Enter the name of an exisiting or new resource group"
            }
                
            # Check if the resource group exists
            $ResourceGroup = Get-AzureRmResourceGroup -ResourceGroupName $ResourceGroupName

            # Get Azure resions
            $Locations = Get-AzureRmLocation

            #If the resource group does not exist
            if (!$ResourceGroup){
                
                # And no location is set
                if (!$Location){
                    
                    # Get Azure region locations
                    $Locations | Select-Object Location
                    
                    # Prompt for location
                    $Location = Read-Host "Enter the location for this VM"
                }

                # Check for valid location
                if ($Locations.location -notcontains $Location){
                    throw "Location is invalid or not available"
                }

                # Create Resource Group
                New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
            }
                                        
            # Get supported sizes in location of VM
            $SupportedVMSize = Get-AzureRmVMSize -Location $Location

            # If no size is specified
            if (!$VMSize){
                
                # Get supported VM sizes and display the name
                $SupportedVMSize | Select-Object Name

                # Prompt for VM size
                $VMSize = Read-Host "Please enter the name of the VM Size"
            }
            
            # Check for invalid size
            if ($SupportedVMSize.name -notcontains $VMSize){
                throw "VM size is invalid or not available in that location."
            }

            # Create public IP
            $PIp = New-AzureRmPublicIpAddress -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic

            # Get existing vNET
            Get-AzureRmVirtualNetwork | Tee-object -Variable vnet | Select-Object -Property Name

            if (!$vnet){

                # Create virtual network
                
                # Create virtual network config
                
            }
            Else {
                # Get existing subnetconfig
                $vnet | Get-AzureRmVirtualNetworkSubnetConfig | Where-Object -Property Name -EQ $SubnetName | Tee-Object -Variable subnetconfig | Select-Object -Property Name,AddressPrefix
                
            }

            # Create VM Network Interface
            $Interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PIp.Id

            # Create Managed Disk

            # Compute

            ## Set up VM object
            $VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
            $VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $VMCredential -ProvisionVMAgent -EnableAutoUpdate
            $VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName $PublisherName -Offer $Offer -Skus $SKU -Version $latest
            $VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id
            #Need to review managed disks
            #$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
            $VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage

            ## Create the VM in Azure
            New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine

        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}
