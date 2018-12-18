<#
#Script name: Add member to group from CSV import of object Ids
#Creator: Wesley Trust
#Date: 2018-12-18
#Revision: 1
#References: 
.Synopsis
    Script to add members to a group
.Description

#>

Param(
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify the path of the CSV import file",
        ValueFromPipeLineByPropertyName = $true
    )]
    [string]
    $PathToCSV,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify the object ID of the group, accepts pipeline values",
        ValueFromPipeLineByPropertyName = $true
    )]
    [string]
    $GroupObjectId
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify whether to skip dependency checks"
    )]
    [switch]
    $SkipDependencyCheck,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify a PowerShell credential"
    )]
    [pscredential]
    $Credential,
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
            "$FunctionLocation\Toolkit\Invoke-DependencyCheck.ps1",
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

            Invoke-DependencyCheck -Modules $Module
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

        # Import CSV
        $CSVImport = Import-Csv $PathToCSV

        # Add members to group
        foreach ($Member in $CSVImport){
            Add-AzureADGroupMember -ObjectId $GroupObjectId -RefObjectId $Member.ObjectId
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