<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template

 .PARAMETER subscriptionId
    The subscription id where the template will be deployed.

 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER resourceGroupLocation
    Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.

 .PARAMETER deploymentName
    The deployment name.

 .PARAMETER templateFilePath
    Optional, path to the template file. Defaults to template.json.

 .PARAMETER parametersFilePath
    Optional, path to the parameters file. Defaults to parameters.json. If file is not found, will prompt for parameter values based on template.
#>

param(
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Enter Azure credentials"
    )]
    [pscredential]
    $AzureCredential,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Enter Admin credentials for deployment"
    )]
    [pscredential]
    $AdminCredential,
    [Parameter(
        Mandatory = $true
    )]
    [string]
    $AzADTenantID,
    [Parameter(
        Mandatory = $true
    )]
    [string]
    $AzSubscriptionID,
    [Parameter(
        Mandatory = $true
    )]
    [string]
    $ResourceGroupName,
    [Parameter(
        Mandatory = $true
    )]
    [string]
    $ResourceGroupLocation,
    [Parameter(
        Mandatory = $true
    )]
    [string]
    $DeploymentName,
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $TemplateFilePath = "Template\template.json",
    [Parameter(
        Mandatory = $false
    )]
    $ParametersFilePath = "Template\parameters.json"
)

# Variables
$ErrorActionPreference = "Stop"
$VaultName = "$resourceGroupName-" + (Get-Random)
$VaultKey = ""

# Build custom parameters
$CustomParameters = @{}
if ($AzADTenantID) {
    $CustomParameters += @{
        TenantID = $AzADTenantID
    }
}
if ($AzSubscriptionID) {
    $CustomParameters += @{
        SubscriptionID = $AzSubscriptionID
    }
}
if ($AzCredential) {
    $CustomParameters += @{
        Credential = $AzCredential
    }
}

# Connect to Azure and subscription
Connect-AzAccount @CustomParameters

# Register Resource Providers
$resourceProviders = @("microsoft.compute", "microsoft.storage", "microsoft.network", "Microsoft.KeyVault")
if ($resourceProviders) {
    Write-Host "Registering resource providers..."
    foreach ($resourceProvider in $resourceProviders) {
        Register-AZResourceProvider -ProviderNamespace $ResourceProvider
    }
}

# Create resource group if it does not exist
$resourceGroup = Get-AZResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (!$resourceGroup) {
    Write-Host "`nCreating resource group '$resourceGroupName' in location '$resourceGroupLocation'"
    New-AZResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else {
    Write-Host "Using existing resource group '$resourceGroupName'"
}

# Create or check for existing key vault
$KeyVault = Get-AZResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (!$KeyVault) {
    Write-Host "`nCreating Key Vault '$VaultName' in location '$resourceGroupLocation'"
    New-AZKeyVault -VaultName $VaultName -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -EnabledForTemplateDeployment
}
else {
    Write-Host "Using existing Key Vault '$resourceGroupName'"
}

# Generate key for password
$VMPassword = Get-Random | ConvertTo-SecureString -AsPlainText -Force

# Store key
Set-AzureKeyVaultSecret -VaultName $VaultName -Name $VaultKey -SecretValue $VMPassword

# Create custom parameters hastable
if ($adminCredential) {
    $CustomParameters = @{
        adminUsername = $adminCredential.UserName
        adminPassword = $adminCredential.Password
        VaultName     = $VaultName
        VaultKey      = $VaultKey
    }
}

# Start the deployment
Write-Host "`nStarting deployment..."
if (Test-Path $parametersFilePath) {
    New-AZResourceGroupDeployment `
        -ResourceGroupName $resourceGroupName `
        -TemplateFile $templateFilePath `
        -TemplateParameterFile $parametersFilePath `
        @CustomParameters
}
else {
    New-AZResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath
}