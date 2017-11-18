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
            HelpMessage="Enter the VM size"
        )]
        [string]
        $VMSize,

        [Parameter(
            Mandatory=$true,
            HelpMessage="Enter the Storage Account Type"
        )]
        [string]
        $StorageType,

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
        $VNetSubnetAddressPrefix,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the number of data disks (if any)"
        )]
        [int]
        $DataDisk,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the size of each data disks (if any)"
        )]
        [int]
        $DataDiskSize,
        
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether to provision a public IP address"
        )]
        [int]
        $ProvisionPIP,
        
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specifies whether the VM should run post provisioning"
        )]
        [int]
        $PostProvision,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the post provision script name"
        )]
        [string]
        $ScriptName,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the post provision script storage account"
        )]
        [string]
        $ScriptStorageAccount,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the post provision script storage account key"
        )]
        [string]
        $ScriptStorageAccountKey,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the post provision script file name"
        )]
        [string]
        $ScriptFileName,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the post provision script storage container name"
        )]
        [string]
        $ScriptContainerName
    )

    Begin {
        try {
            # Connect to Azure
            Set-Location $ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Authentication\
            . .\Connect-AzureRM.ps1
            
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

            # Set resource group
            Set-Location $ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Resources\
            . .\Set-ResourceGroup.ps1

            $ResourceGroup = {
                if ($SubscriptionID){
                    if ($ResourceGroupName){
                        if ($Location){
                            Set-ResourceGroup -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName -Location $Location
                        }
                        else {
                            Set-ResourceGroup -SubscriptionID $SubscriptionID -ResourceGroupName $ResourceGroupName
                        }
                    }
                    else {
                        Set-ResourceGroup -SubscriptionID $SubscriptionID
                    }
                }
                else {
                    Set-ResourceGroup
                }
            }

            # Update location variable from resource group object
            $Location = $ResourceGroup.Location
            
            # Set vnet
            Set-Location $ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Network\
            . .\Set-Vnet.ps1

            # Set Virtual Network
            $Vnet = {
                Set-Vnet
            }

            # Display vnet to be used
            Write-Host "Using Vnet:"$Vnet.name

            # If there are no VM credentials
            If (!$VMCredential) {
                
                # Prompt for credentials
                Write-Output "Enter VM Credentials"
                $VMCredential = Get-Credential
            }
            
            # Clear the variable
            $VMObject = $null

            # Check if a VM exists with specified name
            $VMObject = Get-AzureRMVM -ResourceGroupName $ResourceGroupName -VMName $VMName -ErrorAction SilentlyContinue
            
            # While a VM exists with the same name
            while ($VMObject){
                
                # Clear the variable
                $VMObject = $null
                
                # Prompt for new name
                Write-Host "VM Name $VMName already exists"

                # Clear variable
                $VMName = $null

                # While no name is entered, prompt for name
                while (!$VMName){
                    $VMName = Read-Host "Specify a new name"
                }
                
                # Recheck if VM exists with new name
                $VMObject = Get-AzureRMVM -ResourceGroupName $ResourceGroupName -VMName $VMName -ErrorAction SilentlyContinue
            }

            # Get supported sizes in location of VM
            $SupportedVMSize = Get-AzureRmVMSize -Location $Location

            # If no size is specified
            if (!$VMSize){
                
                # Get supported VM sizes and display the name
                Write-Host ""
                Write-Host "Getting supported VM sizes in $location"
                $SupportedVMSize | Select-Object Name | Format-Table | more

                # Prompt for VM size
                $VMSize = Read-Host "Please enter the name of the VM Size"
            }
            
            # Check for invalid size
            while ($SupportedVMSize.name -notcontains $VMSize){
                $VMSize = Read-Host "VM size is invalid or not available, specify a new size."
            }

            # If a public IP should be provisioned
            if ($ProvisionPIP){
                
                # Create public IP
                $PIp = New-AzureRmPublicIpAddress -Name $VMName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic
                
                # Create VM Network Interface with PIP
                $Interface = New-AzureRmNetworkInterface -Name $VMName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PIp.Id
                        
            }
            Else {
                
                # Create VM Network Interface without a public IP
                $Interface = New-AzureRmNetworkInterface -Name $VMName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id
            }
            
            # Enable diagnostics

            # Consider Availability group

            # Create virtual machine configuration object
            $VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize

            # Set Operating System settings
            $VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $VMCredential -ProvisionVMAgent -EnableAutoUpdate
            
            # Set image used for operating system
            $VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName $PublisherName -Offer $Offer -Skus $SKU -Version $latest
            
            # Set network interface
            $VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id

            # If Data disks are required
            if ($DataDisk -ge 1){

                # While no data disk size is set, prompt for size
                while (!$DataDiskSize){
                    
                    # Prompt for data disk size
                    $DataDiskSize = Read-Host "Enter the data disk size in GB"
                }

                # From 1, to the number of data disks required, for each
                1..$DataDisk | ForEach-Object {
                    
                    # Create Managed Data Disk
                    $DiskConfig = New-AzureRmDiskConfig -AccountType $StorageType -Location $Location -CreateOption Empty -OsType Windows -DiskSizeGB $DataDiskSize
                    $Disk = New-AzureRmDisk -Disk $DiskConfig -ResourceGroupName $resourceGroupName -DiskName $VMName'DataDisk'$_ 
                    
                    # Attach to Virtual machine object
                    $VirtualMachine = Add-AzureRmVMDataDisk -VM $VirtualMachine -CreateOption Attach -ManagedDiskId $Disk.Id -Lun $_
                }
            }

            # Set OS disk to create from Windows image
            $VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -StorageAccountType $StorageType -CreateOption FromImage -Windows

            # Create VM in Azure
            New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine

            # If postprovision is true
            if ($PostProvision){

                # Execute post provision custom script
                Set-AzureRmVMCustomScriptExtension `
                    -ResourceGroupName $ResourceGroupName `
                    -Location $Location `
                    -VMName $VMName `
                    -Name $ScriptName `
                    -TypeHandlerVersion "1.1" `
                    -StorageAccountName $ScriptStorageAccount `
                    -StorageAccountKey $ScriptStorageAccountKey `
                    -FileName $ScriptFileName `
                    -ContainerName $ScriptContainerName
            }
            Else {
                
                # Deallocate VM until configuration is due to take place
                Stop-AzureRMVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force
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
