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
            HelpMessage="Specify a SecureString if required for deployment"
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
            
            # Load resource group functions
            Set-Location $ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Resources\
            . .\ResourceGroup.ps1

            # If a resource group name is specified, check for validity
            if ($ResourceGroupName){
                $ResourceGroup = Get-ResourceGroup `
                    -SubscriptionID $SubscriptionID `
                    -Credential $Credential `
                    -ResourceGroupName $ResourceGroupName
            }
            
            # If no resource group exists, create terminating error
            if (!$ResourceGroup){
                $ErrorMessage = "Resource Group does not exist, create a group first"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }

            # While no deployment name is provided
            while (!$DeploymentName){
                $WarningMessage = "No deployment name is specified"
                Write-Warning $WarningMessage
                $DeploymentName = Read-Host "Enter Deployment name"
            }

            # While no template file is provided
            while (!$TemplateFile){
                $WarningMessage = "No template file is specified"
                Write-Warning $WarningMessage
                $TemplateFile = Read-Host "Enter location of template file"
            }

            # Start deployment
            $HostMessage = "Starting Deployment: $DeploymentName"
            Write-Host $HostMessage

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