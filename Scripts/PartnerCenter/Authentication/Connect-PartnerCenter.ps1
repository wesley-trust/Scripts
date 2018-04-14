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
        HelpMessage="Optionally specify a CSP App ID, if no ID is specified, an Azure AD lookup will be attemted"
    )]
    [string]
    $CSPAppID,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Optionally specify a CSP domain, if no domain is specified, username domain is assumed"
    )]
    [string]
    $CSPDomain
)

Begin {
    try {

        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\PartnerCenter\Authentication\Test-PartnerCenterConnection.ps1",
            "$FunctionLocation\PartnerCenter\Authentication\Get-AzureADPCApp.ps1",
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
        # If there are no credentials
        if (!$Credential){
            $Credential = Get-Credential -Message "Enter Partner Center credentials"
        }
                    
        if (!$ReAuthenticate){
            $ActiveParterCenterConnection = Test-PartnerCenterConnection -Credential $Credential
        }

        # If no active connection, or reauthentcation is required
        if (!$ActiveParterCenterConnection -or $ReAuthenticate){
            if (!$CSPAPPID){
                $CSPApp = Get-AzureADPCApp -Credential $Credential
                $CSPAppID = $CSPApp.appid
            }
            if (!$CSPDomain){
                $CSPDomain = ($Credential.UserName).Split("@")[1]
            }

            $CustomParameters = @{
                Credential = $Credential
                CSPAppID = $CSPApp.appid
                cspDomain = $CSPDomain
            }
            Write-Host "`nAuthenticating with Partner Center"
            Add-PCAuthentication @CustomParameters | Out-Null
        }
    }
    catch [System.Management.Automation.RuntimeException] {
        Write-Host "`nAuthentication attempt failed, retrying with same credentials"
        Add-PCAuthentication @CustomParameters | Out-Null
    }
    catch [System.Net.WebException]{
        Write-Host "`nAuthentication attempt failed, prompting for new credentials"
        $Credential = Get-Credential -Message "Enter Partner Center credentials"
        # Create hashtable of custom parameters
        $CustomParameters = @{
            Credential = $Credential
            CSPAppID = $CSPAppID
            cspDomain = $CSPDomain
        }
        Add-PCAuthentication @CustomParameters | Out-Null
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}