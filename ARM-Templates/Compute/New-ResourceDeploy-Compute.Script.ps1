<#
#Name: Example script to deploy VM in Azure
#Creator: Wesley Trust
#Date: 2017-12-17
#Revision: 1
#References:

.Synopsis
    The script specifies parameters, including ARM artifacts, and calls a function to provision deployment.
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
    $ResourceGroupName,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify deployment location"
    )]
    [string]
    $Location,
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
    $TemplateFile = "$ENV:USERPROFILE\GitHub\Scripts\ARM-Templates\Compute\Compute.azuredeploy.json",
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify the parameter file location"
    )]
    [string]
    $TemplateParameterFile = "$ENV:USERPROFILE\GitHub\Scripts\ARM-Templates\Compute\Compute.parameters.json"
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

        # Load resource group functions
        Set-Location $ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Resources\
        . .\ResourceGroup.ps1

        # Check for valid resource group
        if ($ResourceGroupName){
            $ResourceGroup = Get-ResourceGroup `
                -SubscriptionID $SubscriptionID `
                -ResourceGroupName $ResourceGroupName `
                -Credential $credential
        }
        
        # If no resource group exists, create resource group
        if (!$ResourceGroup){
            $WarningMessage = "Resource group does not exist, creating group: $ResourceGroupName"
            Write-Warning $WarningMessage
            $ResourceGroup = New-ResourceGroup `
                -SubscriptionID $SubscriptionID `
                -ResourceGroupName $ResourceGroupName `
                -Location $Location `
                -Credential $credential
        }
        else {
            $HostMessage = "Using existing Resource Group: $ResourceGroupName"
            Write-Host $HostMessage
        }
        
        # Sensitive Variables
        $adminUsername = ""
        $adminPassword = ""
        $vmName = "Test"
        $virtualNetworkName = "Test"
        $subnetName = "Test"

        # Create hashtable of custom parameters
        $CustomParameters = @{
            adminUsername = $adminUsername;
            vmName = $vmName;
            virtualNetworkName = $virtualNetworkName;
            subnetName = $subnetName;
        }
        
        # Convert password to secure string
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