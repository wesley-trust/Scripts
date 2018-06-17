<#
#Script name: Set-AzureAD-UserType
#Creator: Wesley Trust
#Date: 2017-12-03
#Revision: 1
#References: 

.Synopsis
    Function that connects to an Azure AD tenant and sets directory user type (by default to Member).
.Description

.Example
    Set-AzureAD-UserType -Credential $Credential -Emails "wesley.trust@example.com" -UserType $UserType
.Example
    
#>
Param(
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify a PowerShell credential"
    )]
    [pscredential]
    $Credential,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify email address(es) of directory to change"
    )]
    [string[]]
    $Emails,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify user type to change to (Default: Member)"
    )]
    [ValidateSet("Guest", "Member")] 
    [string]
    $UserType = "Member",
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify whether to skip dependency checks"
    )]
    [switch]
    $SkipDependencyCheck,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify whether to skip disconnection"
    )]
    [switch]
    $SkipDisconnect,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify whether to reauthenticate with different credentials"
    )]
    [switch]
    $ReAuthenticate
)

Begin {
    try {
        # Dot source function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\Toolkit\Check-RequiredModule.ps1",
            "$FunctionLocation\Azure\AzureAD\Test-AzureADConnection.ps1"
            "$FunctionLocation\Azure\AzureAD\Set-AzureADUserType.ps1"
        )
        foreach ($Function in $Functions) {
            . $Function
        }

        # Skip dependency check if switch is true
        if (!$SkipDependencyCheck) {
    
            # Dependency check for required module:
            $Module = "AzureAD"

            Check-RequiredModule -Modules $Module
        }

        # Check for active connection to Azure AD
        if (!$ReAuthenticate) {
            $TestConnection = Test-AzureADConnection -Credential $Credential
            if ($TestConnection.reauthenticate) {
                $ReAuthenticate = $true
            }
        }

        # If there is an active connection, clean up if required
        if ($TestConnection.ActiveConnection) {
            if ($ReAuthenticate) {
                $TestConnection.ActiveConnection = Disconnect-AzureAD | Out-Null
            }
        }

        # If no active connection, connect to Azure AD
        if (!$TestConnection.ActiveConnection -or $ReAuthenticate) {
            Write-Host "`nAuthenticating with Azure AD`n"
            $AzureADConnection = Connect-AzureAD -Credential $Credential
        }
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}
    
Process {
    try {

        # Throw error if not connected to Azure AD
        if (!$AzureADConnection) {
            if (!$TestConnection.ActiveConnection) {
                $ErrorMessage = "No connection to Azure AD"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }
        }

        # Call function
        Set-AzureADUserType `
            -Credential $Credential `
            -Emails $Emails `
            -UserType $UserType
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
            Disconnect-AzureAD 
        }
    }
    catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
