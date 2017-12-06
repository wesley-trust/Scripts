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

        # Define workflow
        workflow New-parallelVM {
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
                $VMCount = "5",
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
                    HelpMessage="Enter the resource group name"
                )]
                [string]
                $VMName = "DeleteMe-"
            )

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
