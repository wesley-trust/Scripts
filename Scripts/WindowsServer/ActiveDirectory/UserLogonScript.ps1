<#
#Script name: User Logon Functions and Script
#Creator: Wesley Trust
#Date: 2018-06-22
#Revision: 2
.Synopsis
   Script that contains functions to retrieve user objects from AD, checks whether the logon script is a certain value, and remove it if so.
.DESCRIPTION

.EXAMPLE
    $UserLogonScriptObject = Get-UserLogonScript -Username "TestUser1"

    Remove-UserLogonScript -UserLogonScriptObject $UserLogonScriptObject
#>

Param(
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Enter the Username",
        Position = 0,
        ValueFromPipeLine = $true,
        ValueFromPipeLineByPropertyName = $true
    )]
    [Alias('User')]
    [string[]]
    $Username,
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Enter the Script name",
        Position = 1,
        ValueFromPipeLineByPropertyName = $true
    )]
    [Alias('Script')]
    [string]
    $ScriptValue
)

Begin {
    try {
        
        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\WindowsServer\ActiveDirectory\UserLogonScript.ps1"
        )

        # Function dot source
        foreach ($Function in $Functions) {
            . $Function
        }
    }
    catch {
        Write-Error -Message $_.Exception
    }                                                                     
}

Process {
    try {

        # Get user logon script check object
        $UserLogonScriptObject = Get-UserLogonScript -Username $Username -ScriptValue $ScriptValue

        # Remove logon script for users that match the check and return object
        $UserLogonScriptRemovalObject = Remove-UserLogonScript -UserLogonScriptObject $UserLogonScriptObject

        # Format for display
        $UserLogonScriptRemovalObject | Format-Table -AutoSize
    }
    catch {
        Write-Error -Message $_.Exception
    }
}
End {
    try {

    }
    catch {
        Write-Error -Message $_.Exception
    }
}
