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

function New-ResourceDeploy() {
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
            HelpMessage="Specify the template file location"
        )]
        [string]
        $TemplateFile,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the parameter file location"
        )]
        [string]
        $TemplateParameterFile
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

            # Create new deployment
            New-AzureRmResourceGroupDeployment `
                -Name $DeploymentName `
                -ResourceGroupName $ResourceGroupName `
                -TemplateFile $TemplateFile `
                -TemplateParameterFile $TemplateParameterFile
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}