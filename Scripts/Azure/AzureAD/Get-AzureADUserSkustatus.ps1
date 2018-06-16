<#
#Script name: User SKU status
#Creator: Wesley Trust
#Date: 2018-06-16
#Revision: 1
#References: 
.Synopsis
    Script to call function to get the Sku status of users, allows specific users or skus to be specified.
.Description
    By default only returns users and skus that are assigned, formats output, tests for active connection/connects/disconnects, supports reauthentication.
#>

Param(
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify the UPN of a user to check, multiple UPNs can be comma separated or in an array, accepts pipeline values",
        ValueFromPipeLine = $true,
        ValueFromPipeLineByPropertyName = $true
    )]
    [string[]]
    $UserPrincipalName,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify the SKU id to check, multiple SKUs can be comma separated or in an array",
        ValueFromPipeLineByPropertyName = $true
    )]
    [string[]]
    $SkuId,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify whether to include users with unassigned skus",
        ValueFromPipeLineByPropertyName = $true
    )]
    [switch]
    $IncludeUnassignedUser,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify whether to include unassigned subscribed skus",
        ValueFromPipeLineByPropertyName = $true
    )]
    [switch]
    $IncludeUnassignedSku,
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
            "$FunctionLocation\Azure\AzureAD\UserSkuStatus.ps1"
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
            if ($ReAuthenticate -or $TestConnection.reauthenticate) {
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
        Write-Error -Message $_.exception
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
        $AzureADUserSkuStatus = Get-AzureADUserSkuStatus

        # Output and format
        if ($AzureADUserSkuStatus) {
            $AzureADUserSkuStatus | Format-Table -AutoSize
        }
        else {
            $ErrorMessage = "No user sku licence status returned"
            Write-Error $ErrorMessage
            throw $ErrorMessage
        }
    }
    catch {
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