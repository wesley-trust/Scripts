<#
#Script name: User Logon Functions
#Creator: Wesley Trust
#Date: 2018-06-22
#Revision: 2
.Synopsis
   Functions to retrieve user objects from AD, checks whether the logon script is a certain value, and remove it if so.
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
        [string]
        $ScriptValue
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
                
                # Start building object properties
                $ObjectProperties = @{
                    SamAccountName = $ADUser.SamAccountName
                    ScriptPath     = $ADUser.ScriptPath
                }
                
                # If user has a script path, create an object with the value and match status
                if ($ADUser.ScriptPath) {
                    if ($ADUser.ScriptPath -eq $ScriptValue) {
                        $ObjectProperties += @{
                            ValueMatch = $true
                        }
                    }
                    else {
                        $ObjectProperties += @{
                            ValueMatch = $false
                        }
                    }
                }
                
                # Create the object with the properties built
                New-Object -TypeName psobject -Property $ObjectProperties
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
                
                # Start building object properties
                $ObjectProperties = @{
                    SamAccountName     = $User.SamAccountName
                    OriginalScriptPath = $User.ScriptPath
                }

                # If user has a script path, create an object with the value and match status
                if ($User.ValueMatch) {
                    
                    # Set AD script path property to null and return modified object
                    $SetADUser = Set-ADUser -Identity $User.SamAccountName -ScriptPath $null -PassThru
                    
                    # Check if the modified user object script path, no longer equals the original value, return object
                    if ($SetADUser.ScriptPath -ne $UserScriptPath) {
                        $ObjectProperties += @{
                            NewScriptPath = $SetADUser.ScriptPath
                            Success       = $true
                            Detail        = "Successfully set new script path property"
                        }
                    }
                    else {
                        $ObjectProperties += @{
                            NewScriptPath = $null
                            Success       = $false
                            Detail        = "Failed to set new script path property"
                        }
                    }
                }
                else {
                    $ObjectProperties += @{
                        NewScriptPath = $null
                        Success       = $null
                        Detail        = "No change required as ScriptPath does not match required value"
                    }
                }

                # Create the object with the properties built
                New-Object -TypeName psobject -Property $ObjectProperties
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