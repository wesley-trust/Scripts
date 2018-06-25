<#
#Script name: User Logon Functions and Script
#Creator: Wesley Trust
#Date: 2018-06-22
#Revision: 1
.Synopsis
   Script that contains functions to retrieve user objects from AD, checks whether the logon script is a certain value, and remove it if so.
.DESCRIPTION

.EXAMPLE
    $UserLogonScriptObject = Get-UserLogonScript -Username "TestUser1"

    Remove-UserLogonScript -UserLogonScriptObject $UserLogonScriptObject
#>

function Get-UserLogonScript {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $False,
            HelpMessage = "Enter the Username",
            Position = 0,
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [Alias('User')]
        [string[]]
        $Username,
        [Parameter(
            Mandatory = $False,
            HelpMessage = "Enter the Script name",
            Position = 1,
            ValueFromPipeLineByPropertyName = $true
        )]
        [Alias('Script')]
        [string[]] $ScriptValue = "Test"
    )

    Begin {
        try {

        }
        catch {
            Write-Error -Message $_.Exception
        }                                                                     
    }

    Process {
        try {

            # For each user, get AD properties
            foreach ($User in $UserName) {
                $ADUser = Get-ADUser -Properties * -Filter "SamAccountName -eq '$Username'"
    
                # If user has a script path, create an object with the value and match status
                if ($ADUser.ScriptPath) {
                    if ($ADUser.ScriptPath -eq $ScriptValue) {
                        [pscustomobject]@{
                            SamAccountName = $ADUser.SamAccountName
                            ScriptPath     = $ADUser.ScriptPath
                            ValueMatch     = $true
                        }
                    }
                    else {
                        [pscustomobject]@{
                            SamAccountName = $ADUser.SamAccountName
                            ScriptPath     = $ADUser.ScriptPath
                            ValueMatch     = $false
                        }
                    }
                }
            }
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
}
function Remove-UserLogonScript {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $False,
            HelpMessage = "Provide the script path user check object",
            Position = 0,
            ValueFromPipeLine = $true
        )]
        [psobject]
        $UserLogonScriptObject
    )

    Begin {
        try {

        }
        catch {
            Write-Error -Message $_.Exception
        }                                                                     
    }

    Process {
        try {

            # For each user
            foreach ($User in $UserLogonScriptObject) {

                # If user has a script path, create an object with the value and match status
                if ($User.ValueMatch) {
                    
                    # Set AD script path property to null and return modified object
                    $SetADUser = Set-ADUser -Identity $User.SamAccountName -ScriptPath $null -PassThru
                    
                    # Check if the modified user object script path, no longer equals the original value, return object
                    if ($SetADUser.ScriptPath -ne $UserScriptPath) {
                        [pscustomobject]@{
                            SamAccountName     = $User.SamAccountName
                            OriginalScriptPath = $User.ScriptPath
                            NewScriptPath      = $SetADUser.ScriptPath
                            Success            = $true
                            Detail             = "Successfully set new script path property"
                        }
                    }
                    else {
                        [pscustomobject]@{
                            SamAccountName     = $User.SamAccountName
                            OriginalScriptPath = $User.ScriptPath
                            NewScriptPath      = $null
                            Success            = $false
                            Detail             = "Failed to set new script path property"
                        }
                    }
                }
                else {
                    [pscustomobject]@{
                        SamAccountName     = $User.SamAccountName
                        OriginalScriptPath = $User.ScriptPath
                        NewScriptPath      = $null
                        Success            = $null
                        Detail             = "No change required"
                    }
                }
            }
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
}

# Get user logon script check object
$UserLogonScriptObject = Get-UserLogonScript -Username "TestUser1"

# Remove logon script for users that match the check and return object
$UserLogonScriptRemovalObject = Remove-UserLogonScript -UserLogonScriptObject $UserLogonScriptObject

# Format for display
$UserLogonScriptRemovalObject | Format-Table -AutoSize