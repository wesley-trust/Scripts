<#
#Name: New function to deploy storage account template
#Creator: Wesley Trust
#Date: 2017-12-16
#Revision: 1
#References:

.Synopsis
    
.Description

.Example

.Example

#>

function New-StorageAccountDeploy() {
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
        $ResourceGroupName,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the deployment name"
        )]
        [string]
        $DeploymentName,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the storage account name"
        )]
        [string]
        $StorageAccountName,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the storage account type"
        )]
        [string]
        $StorageAccountType
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

            # Clean parameter
            $StorageAccountName = $StorageAccountName.ToLower()

            # Set Template Artifact Location
            Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\ARM Template Deployments\Storage\"

            # Create new  deployment
            New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName `
                -TemplateFile .\Storage.azuredeploy.json `
                -storageAccountName $StorageAccountName
                -storageAccountType $storageAccountType
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}

# Execute
New-StorageAccountDeploy `
    -ResourceGroupName "Testing" `
    -DeploymentName "TestDeploymentName" `
    -StorageAccountName "TestAccountName" `
    -StorageAccountType "Standard_LRS"