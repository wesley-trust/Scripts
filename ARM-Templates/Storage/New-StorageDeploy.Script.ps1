<#
#Name: New script to call function to provision storage account(s) in Azure
#Creator: Wesley Trust
#Date: 2017-12-16
#Revision: 1
#References:

.Synopsis
    
.Description

.Example

.Example

#>

Param(
    [Parameter(
        Mandatory=$false,
        HelpMessage="Enter Azure credentials"
    )]
    [pscredential]
    $Credential,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify subscription ID"
    )]
    [string]
    $SubscriptionID,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify resource group name"
    )]
    [string]
    $ResourceGroupName = "Testing",
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify the deployment name"
    )]
    [string]
    $DeploymentName = "TestDeploymentName",
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify the storage account name"
    )]
    [string]
    $StorageAccountName = "ExampleScriptTest",
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify the storage account type"
    )]
    [string]
    $StorageAccountType = "Standard_LRS"
)

Begin {
    try {

        # Load functions
        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\ARM-Templates\Storage"
        . .\New-StorageDeploy.Function.ps1
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {

        # Create new storage account
        New-StorageDeploy `
            -DeploymentName $DeploymentName `
            -ResourceGroupName $ResourceGroupName `
            -storageAccountName $StorageAccountName `
            -storageAccountType $StorageAccountType
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}