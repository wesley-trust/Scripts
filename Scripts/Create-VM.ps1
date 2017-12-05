<#
#Script name: Create VM script
#Creator: Wesley Trust
#Date: 2017-11-18
#Revision: 1
#References: 

.Synopsis
    Script to call function to provision virtual machine in Azure
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

        # Variables
        $CharacterLength = "6"
        $StorageType = "StandardLRS"
        $VMSize = "Standard_A1"
        $VMCount = 2
        $Location = "westeurope"
        $ResourceGroupName = "WesDev"

        # If there are VMs to create
        if ($VMCount){
            # From one, to the number required
            1..$VMCount | ForEach-Object {
                
                # Create random string for VM name
                $RandomString = New-RandomString -CharacterLength $CharacterLength -Simplified $true
                $VMName = "DeleteMe-"+$RandomString
                
                # Create VM
                New-VM `
                    -StorageType $StorageType `
                    -VMSize $VMSize `
                    -VMName $VMName `
                    -subscriptionId $SubscriptionId `
                    -ResourceGroupName $ResourceGroupName `
                    -Location $Location
            }
        }
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}
