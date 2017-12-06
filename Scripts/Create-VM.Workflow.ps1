<#
#Script name: Create VM script
#Creator: Wesley Trust
#Date: 2017-12-06
#Revision: 1
#References: 

.Synopsis
    Script to call workflow to provision Azure virtual machines in parallel.
.Description

.Example

.Example
    
#>

Begin {
    try {
        
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}

Process {
    try {
        # Include functions
        Set-Location $ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Compute\
        . .\New-VM.ps1

        Set-Location $ENV:USERPROFILE\GitHub\Scripts\Functions\Toolkit\
        . .\New-RandomString.ps1

        Set-Location $ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Resources\
        . .\ResourceGroup.ps1

        Set-Location $ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Network\
        . .\VirtualNetwork.ps1

        # Define workflow
        workflow New-ParallelVM {
            Param(
                [Parameter(
                    Mandatory=$true,
                    HelpMessage="Enter the subscription ID"
                )]
                [string]
                $SubscriptionID,
                [Parameter(
                    Mandatory=$true,
                    HelpMessage="Enter Azure credentials"
                )]
                [pscredential]
                $credential,
                [Parameter(
                    Mandatory=$true,
                    HelpMessage="Enter VM credentials"
                )]
                [pscredential]
                $VMCredential,
                [Parameter(
                    Mandatory=$false,
                    HelpMessage="Enter the character length of random string for VM name"
                )]
                [string]
                $CharacterLength = "6",
                [Parameter(
                    Mandatory=$false,
                    HelpMessage="Enter the storage type"
                )]
                [string]
                $StorageType = "StandardLRS",
                [Parameter(
                    Mandatory=$false,
                    HelpMessage="Enter the VM size"
                )]
                [string]
                $VMSize = "Standard_A1_v2",
                [Parameter(
                    Mandatory=$false,
                    HelpMessage="Enter the VM count"
                )]
                [string]
                $VMCount = "10",
                [Parameter(
                    Mandatory=$false,
                    HelpMessage="Enter the location"
                )]
                [string]
                $Location = "westeurope",
                [Parameter(
                    Mandatory=$false,
                    HelpMessage="Enter the resource group name"
                )]
                [string]
                $ResourceGroupName = "WesDev",
                [Parameter(
                    Mandatory=$false,
                    HelpMessage="Enter the VM name prefix"
                )]
                [string]
                $VMName = "DeleteMe-"
            )

            # Validate resource group
            if ($ResourceGroupName){
                $ResourceGroup = Get-ResourceGroup `
                -SubscriptionID $SubscriptionID `
                -ResourceGroupName $ResourceGroupName `
                -Credential $credential
            }
            
            # If no resource group exists, create resource group
            if (!$ResourceGroup){
                $ResourceGroup = New-ResourceGroup `
                    -SubscriptionID $SubscriptionID `
                    -ResourceGroupName $ResourceGroupName `
                    -Location $Location `
                    -Credential $credential
            }

            # Check for valid virtual network
            $Vnet = Get-Vnet `
                -SubscriptionID $SubscriptionID `
                -ResourceGroupName $VnetResourceGroupName `
                -VNetName $VnetName `
                -Credential $credential

            # If no vnet exists, create a default network
            if (!$Vnet){
                
                # If no specific vnet resource group is specified, use existing group
                if (!$VnetResourceGroupName){
                    $VnetResourceGroupName = $ResourceGroupName
                }
                
                $Vnet = New-Vnet `
                -SubscriptionID $SubscriptionID `
                -ResourceGroupName $VnetResourceGroupName `
                -VNetName $VnetName `
                -Location $Location `
                -SubnetName $SubnetName `
                -VNetAddressPrefix $VNetAddressPrefix `
                -VNetSubnetAddressPrefix $VNetSubnetAddressPrefix `
                -Credential $credential
            }

            # For each VM that needs to be created
            foreach -parallel ($VM in 1..$VMCount) {
                
                # Create random string for VM name
                $RandomString = New-RandomString -CharacterLength $CharacterLength -Simplified $true
                $RandomVMName = $VMName+$RandomString
                
                # Create VM
                New-VM `
                    -Credential $Credential `
                    -StorageType $StorageType `
                    -VMSize $VMSize `
                    -VMName $RandomVMName `
                    -subscriptionId $SubscriptionId `
                    -ResourceGroupName $ResourceGroupName `
                    -Location $Location `
                    -VMCredential $VMCredential
            } 
        }

        # Execute Workflow
        New-ParallelVM
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}
