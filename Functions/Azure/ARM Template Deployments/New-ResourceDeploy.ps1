<#
#Name: New function to deploy ARM templates to Azure
#Creator: Wesley Trust
#Date: 2017-12-16
#Revision: 1
#References:

.Synopsis
    New function that authenticates with Azure and deploys an ARM template with specified parameters.
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
        $TemplateParameterFile,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Hashtable of custom parameters"
        )]
        [Hashtable]
        $CustomParameters,
        [Parameter(
            Mandatory=$false,
            HelpMessage="SecureString"
        )]
        [securestring]
        $SecureString
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
            # If a secure string is required
            if ($SecureString){
                # Create new deployment with secure string
                New-AzureRmResourceGroupDeployment `
                    -Name $DeploymentName `
                    -ResourceGroupName $ResourceGroupName `
                    -TemplateFile $TemplateFile `
                    -TemplateParameterFile $TemplateParameterFile `
                    @CustomParameters `
                    -SecureString $SecureString
            }
            Else {
                # Create new deployment without secure string
                New-AzureRmResourceGroupDeployment `
                -Name $DeploymentName `
                -ResourceGroupName $ResourceGroupName `
                -TemplateFile $TemplateFile `
                -TemplateParameterFile $TemplateParameterFile `
                @CustomParameters
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