<#
#Name: Example script to deploy VM in Azure
#Creator: Wesley Trust
#Date: 2017-12-16
#Revision: 1
#References:

.Synopsis
    The script specifies parameters, including ARM artifacts, and calls a function that connects to Azure
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
        HelpMessage="Specify the template file location"
    )]
    [string]
    $TemplateFile = "$ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\ARM Template Deployments\Compute\Compute.azuredeploy.json",
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify the parameter file location"
    )]
    [string]
    $TemplateParameterFile = "$ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\ARM Template Deployments\Compute\Compute.parameters.json"
)

Begin {
    try {
        # Load functions
        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\ARM Template Deployments\"
        . .\New-ResourceDeploy.ps1
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {

        # Create hashtable of custom parameters
        $CustomParameters = @{
            adminUsername = "";
        }
        
        # Create password as a secure string
        $adminPassword = "";
        $SecureString = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force

        # Create new  deployment
        New-ResourceDeploy `
            -Credential $Credential `
            -SubscriptionID $SubscriptionID `
            -ResourceGroupName $ResourceGroupName `
            -DeploymentName $DeploymentName `
            -TemplateFile $TemplateFile `
            -TemplateParameterFile $TemplateParameterFile `
            -CustomParameters $CustomParameters `
            -SecureString $SecureString
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}