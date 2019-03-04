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
    $adminCredential,

    [Parameter(
        Mandatory = $false
    )]
    [switch]
    $DelegatedAuthentication,

    [Parameter(
        Mandatory = $true
    )]
    [string]
    $TenantId,

    [Parameter(
        Mandatory = $true
    )]
    [string]
    $subscriptionId,

    [Parameter(
        Mandatory = $true
    )]
    [string]
    $resourceGroupName,

    [Parameter(
        Mandatory = $true
    )]
    [string]
    $resourceGroupLocation,

    [Parameter(
        Mandatory = $true
    )]
    [string]
    $deploymentName,

    [Parameter(
        Mandatory = $false
    )]
    [string]
    $templateFilePath = "Template\template.json",

    [Parameter(
        Mandatory = $false
    )]
    $parametersFilePath = "Template\parameters.json"
)

# Variables
$ErrorActionPreference = "Stop"
$VaultName = "$resourceGroupName-"+(Get-Random)
$VaultKey = ""

# Connect to Azure and subscription
Write-Host "Signing in to Azure RM"
if ($DelegatedAuthentication){
    if ($TenantId){
        Write-Host "`nSelecting tenant '$TenantId' and subscription '$subscriptionId'"
        Connect-AZAccount -Credential $AzureCredential -TenantId $TenantId -SubscriptionId $SubscriptionId
    }
    else {
        $ErrorMessage = "A tenant ID is not specified, unable to use delegated authentication"
        Write-Error $ErrorMessage
        throw $ErrorMessage
    }
}
else {
    Connect-AZAccount -Credential $AzureCredential
    Write-Host "Selecting subscription '$subscriptionId'"
    Set-AzContext -SubscriptionID $subscriptionId
}

# Register Resource Providers
$resourceProviders = @("microsoft.compute", "microsoft.storage", "microsoft.network","Microsoft.KeyVault")
if ($resourceProviders) {
    Write-Host "Registering resource providers..."
    foreach ($resourceProvider in $resourceProviders) {
        Register-AZResourceProvider -ProviderNamespace $ResourceProvider
    }
}

# Create or check for existing resource group
$resourceGroup = Get-AZResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (!$resourceGroup) {
    Write-Host "Resource group '$resourceGroupName' does not exist."
    Write-Host "`nCreating resource group '$resourceGroupName' in location '$resourceGroupLocation'"
    New-AZResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else {
    Write-Host "Using existing resource group '$resourceGroupName'"
}

# Create or check for existing key vault
$KeyVault = Get-AZResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (!$KeyVault) {
    Write-Host "Key vault '$VaultName' does not exist."
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
if ($adminCredential){
    $CustomParameters = @{
        adminUsername = $adminCredential.UserName
        adminPassword = $adminCredential.Password
        VaultName = $VaultName
        VaultKey = $VaultKey
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