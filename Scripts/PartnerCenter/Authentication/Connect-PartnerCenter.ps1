<#
#Script name: Connect to Partner Center
#Creator: Wesley Trust
#Date: 2018-04-10
#Revision: 1
#References: 

.Synopsis
    Connects to Partner Center
.Description

.Example
    
.Example
    
#>

Param(
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
    $ReAuthenticate,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify whether to confirm disconnection/reauthentication of active session"
    )]
    [switch]
    $Confirm,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Optionally specify a CSP App ID, if no ID is specified, an Azure AD lookup will be attemted"
    )]
    [string]
    $CSPAppID
)

Begin {
    try {

        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\PartnerCenter\Authentication\Connect-PartnerCenter.ps1",
            "$FunctionLocation\Toolkit\Check-RequiredModule.ps1"
        )
        # Function dot source
        foreach ($Function in $Functions){
            . $Function
        }
        
        # Required Module
        $Module = "PartnerCenterModule,AzureAD"
        
        Check-RequiredModule -Modules $Module

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
            Credential = $Credential
            CSPAppID = $CSPAppID
        }
        # If switches are true, append to custom parameters
        if ($ReAuthenticate){
            $CustomParameters += @{
                ReAuthenticate = $true
            }
        }
        if ($Confirm){
            $CustomParameters += @{
                Confirm = $true
            }
        }

        # Connect to Partner Center with custom parameters
        Connect-PartnerCenter @CustomParameters

    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}