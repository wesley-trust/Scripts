<#
#Script name: New Service Principal
#Creator: Wesley Trust
#Date: 2019-02-18
#Revision: 1
#References: 

.Synopsis
    Script that creates a new Service Principal, grants this access to Azure resources and outputs the results (including secret).
.Description

.Example
    
.Example
    
#>
Param(
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Specify a PowerShell credential"
    )]
    [pscredential]
    $Credential,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Optionally specify the Azure AD tenant (if access to more than one)"
    )]
    [string]
    $TenantID,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Optionally specify the Azure subscription (if access to more than one)"
    )]
    [string]
    $SubscriptionID,
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Specify Azure AD Service Principal Display Name"
    )]
    [string]
    $AzSPDisplayName,
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Specify resource access permissions for Service Principal"
    )]
    [string]
    $AzSPRole,
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Specify resource scope for Service Principal"
    )]
    [string]
    $AzSPScope
)

Begin {
    try {
        
        # Authenticate with Azure
        Connect-AzAccount `
            -Credential $Credential `
            -Tenant $TenantID `
            -Subscription $SubscriptionID `
            | Tee-Object -Variable AzContext

    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}
    
Process {
    try {

        # Create new Service Principal (AppID will be auto-generated)
        $AzSP = New-AzADServicePrincipal -DisplayName $AzSPDisplayName -Role $AzSPRole -Scope $AzSPScope

        # Decrypt Secret
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AzSP.Secret)
        $Secret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        # Generate Output
        $AzSPOutput = [PSCustomObject]@{
            TenantID = $AzContext.Context.Tenant.Id
            DisplayName = $AzSP.DisplayName
            Role = $AzSPRole
            Scope = $AzSPScope
            AppID = $AzSP.ApplicationId
            Secret = $Secret
        }

        # Display Output
        $AzSPOutput
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    try {
        
        # Clean up active session
        if (!$SkipDisconnect) {
            Disconnect-AzAccount
        }
    }
    catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
