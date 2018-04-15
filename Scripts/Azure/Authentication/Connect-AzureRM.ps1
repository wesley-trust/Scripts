<#
#Script name: Connect to Azure RM
#Creator: Wesley Trust
#Date: 2018-04-14
#Revision: 1
#References: 

.Synopsis
    Connects to an Azure RM
.Description

.Example
    
.Example
    
#>

Param(
    [Parameter(
        Mandatory=$false,
        HelpMessage="Enter the subscription ID"
    )]
    [string]
    $SubscriptionID,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Enter the tenant ID"
    )]
    [string]
    $TenantID,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify PowerShell credential object"
    )]
    [pscredential]
    $Credential,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify whether to reauthenticate with different credentials"
    )]
    [switch]
    $ReAuthenticate
)

Begin {
    try {

        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\Azure\Authentication\Test-AzureConnection.ps1",
            "$FunctionLocation\Toolkit\Check-RequiredModule.ps1"
        )
        # Function dot source
        foreach ($Function in $Functions){
            . $Function
        }
        
        # Required Module
        $Module = "AzureRM"
        $ModuleCore = "AzureRM.Netcore"
        
        Check-RequiredModule -Modules $Module -ModulesCore $ModuleCore
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {
        # Build custom parameters
        $CustomParameters = @{}
        if ($TenantID){
            $CustomParameters += @{
                TenantID = $TenantID
            }
        }
        if ($SubscriptionID){
            $CustomParameters += @{
                SubscriptionID = $SubscriptionID
            }
        }
        if ($Credential){
            $CustomParameters += @{
                Credential = $Credential
            }
        }

        # Check for active connection
        $TestConnection = Test-AzureConnection -Credential $Credential
        
        # If there is an active connection, clean up
        if ($TestConnection.ActiveConnection){
            if ($ReAuthenticate -or $TestConnection.reauthenticate){
                $TestConnection.ActiveConnection = Disconnect-AzureRmAccount | Out-Null
            }
        }

        # If no active connection, connect
        if (!$TestConnection.ActiveConnection){
            Write-Host "`nAuthenticating with Azure`n"
            $AzureConnection = Connect-AzureRMAccount @CustomParameters
            if ($AzureConnection){
                $AzureContext = Get-AzureRmContext
            }
            else {
                $ErrorMessage = "Unable to connect to Azure"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }
        }
        return $AzureContext
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}