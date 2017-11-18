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

        New-VM -VMName "Test-Delete-Me" -StorageType "Standard_LRS" -SubscriptionID
    }
    Catch {

        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}
